const fs = require('fs');
const path = require('path');
const { createClient } = require('@supabase/supabase-js');

function loadEnvFile(filePath) {
  if (!fs.existsSync(filePath)) return;
  const raw = fs.readFileSync(filePath, 'utf8');
  for (const line of raw.split('\n')) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const eq = trimmed.indexOf('=');
    if (eq === -1) continue;
    const key = trimmed.slice(0, eq).trim();
    const value = trimmed.slice(eq + 1).trim();
    if (!process.env[key]) process.env[key] = value;
  }
}

function loadEnv() {
  const root = process.cwd();
  loadEnvFile(path.join(root, '.env.local'));
  loadEnvFile(path.join(root, '.env'));
}

function getRequiredEnv(name) {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Missing required env: ${name}`);
  }
  return value;
}

function extractJson(text) {
  if (!text) throw new Error('Empty LLM response');
  const cleaned = text.replace(/```json|```/g, '').trim();
  const first = cleaned.indexOf('{');
  const last = cleaned.lastIndexOf('}');
  if (first === -1 || last === -1 || first >= last) {
    throw new Error('Could not find JSON object in LLM response');
  }
  return JSON.parse(cleaned.slice(first, last + 1));
}

function todayString() {
  return new Date().toISOString().slice(0, 10);
}

async function getBoardContext(supabase, boardId) {
  const [{ data: steps, error: stepsError }, { data: members, error: membersError }] = await Promise.all([
    supabase
      .from('recipe_step')
      .select('column_id,column_name,order_position')
      .eq('board_id', boardId)
      .order('order_position', { ascending: true }),
    supabase
      .from('team_member')
      .select('member_id,member_name,role')
      .eq('board_id', boardId)
      .order('member_id', { ascending: true }),
  ]);

  if (stepsError) throw stepsError;
  if (membersError) throw membersError;

  return { steps: steps || [], members: members || [] };
}

async function generatePlanFromChatGPT(input, context) {
  const apiKey = getRequiredEnv('OPENAI_API_KEY');
  
  const stepIds = context.steps.map((s) => s.column_id);
  const memberNames = context.members.map((m) => m.member_name);

  const systemPrompt = [
    'You are a strict data planner for a Kanban database.',
    'Return ONLY valid JSON. No prose.',
    'Use this schema exactly:',
    '{"operations":[{"type":"create_task|assign_member|create_member","title":"string?","task_id":"number?","description":"string?","step_id":"string?","due_date":"YYYY-MM-DD?","member_name":"string?","role":"string?","assignee_names":["string"]?}],"notes":"string"}',
    `Allowed step_id values: ${JSON.stringify(stepIds)}.`,
    `Existing member names: ${JSON.stringify(memberNames)}.`,
    'Rules:',
    '- Prefer create_task for new work items mentioned by user.',
    '- For create_task, include title, optional description, optional due_date, and valid step_id.',
    '- For assignees in create_task, set assignee_names when user implies owner.',
    '- Use create_member only when user asks to add a new person.',
    '- Keep operations minimal and deterministic.',
  ].join('\n');

  const userPrompt = [
    `User request: ${input}`,
    `Today: ${todayString()}`,
  ].join('\n');

  const payload = {
    model: 'gpt-4o-mini',
    temperature: 0,
    messages: [
      { role: 'system', content: systemPrompt },
      { role: 'user', content: userPrompt },
    ],
    response_format: { type: 'json_object' },
  };

  const res = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify(payload),
  });

  if (!res.ok) {
    const errorText = await res.text();
    throw new Error(`ChatGPT request failed (${res.status}): ${errorText}`);
  }

  const data = await res.json();
  const content = data?.choices?.[0]?.message?.content;
  const parsed = extractJson(content);

  if (!parsed.operations || !Array.isArray(parsed.operations)) {
    throw new Error('ChatGPT response missing operations array');
  }

  return parsed;
}

async function getOrCreateMember(supabase, boardId, memberName, role = 'Member') {
  const { data: existing, error: findError } = await supabase
    .from('team_member')
    .select('member_id,member_name')
    .eq('board_id', boardId)
    .eq('member_name', memberName)
    .maybeSingle();

  if (findError) throw findError;
  if (existing) return existing;

  const { data: created, error: createError } = await supabase
    .from('team_member')
    .insert({ board_id: boardId, member_name: memberName, role })
    .select('member_id,member_name')
    .single();

  if (createError) throw createError;
  return created;
}

async function nextOrderPosition(supabase, boardId, stepId) {
  const { data, error } = await supabase
    .from('recipe_task')
    .select('order_position')
    .eq('board_id', boardId)
    .eq('step_id', stepId)
    .order('order_position', { ascending: false })
    .limit(1);

  if (error) throw error;
  if (!data || data.length === 0) return 1;
  return Number(data[0].order_position || 0) + 1;
}

async function createTask(supabase, boardId, op) {
  if (!op.title || !op.step_id) {
    throw new Error('create_task requires title and step_id');
  }

  const orderPosition = await nextOrderPosition(supabase, boardId, op.step_id);
  const payload = {
    board_id: boardId,
    step_id: op.step_id,
    title: op.title,
    description: op.description || null,
    due_date: op.due_date || null,
    order_position: orderPosition,
    is_done: false,
  };

  const { data: task, error } = await supabase
    .from('recipe_task')
    .insert(payload)
    .select('card_id,title,step_id,order_position')
    .single();

  if (error) throw error;

  const assignments = [];
  if (Array.isArray(op.assignee_names) && op.assignee_names.length > 0) {
    for (const name of op.assignee_names) {
      const member = await getOrCreateMember(supabase, boardId, name);
      const { error: assignError } = await supabase
        .from('task_assignment')
        .upsert({ task_id: task.card_id, member_id: member.member_id }, { onConflict: 'task_id,member_id' });
      if (assignError) throw assignError;
      assignments.push(member.member_name);
    }
  }

  return { type: 'create_task', task, assignments };
}

async function assignMember(supabase, boardId, op) {
  const memberName = op.member_name;
  if (!memberName) throw new Error('assign_member requires member_name');

  let taskId = op.task_id || null;
  if (!taskId && op.title) {
    const { data: taskByTitle, error: taskError } = await supabase
      .from('recipe_task')
      .select('card_id,title')
      .eq('board_id', boardId)
      .eq('title', op.title)
      .maybeSingle();
    if (taskError) throw taskError;
    if (!taskByTitle) throw new Error(`Task not found by title: ${op.title}`);
    taskId = taskByTitle.card_id;
  }

  if (!taskId) throw new Error('assign_member requires task_id or title');

  const member = await getOrCreateMember(supabase, boardId, memberName, op.role || 'Member');
  const { error } = await supabase
    .from('task_assignment')
    .upsert({ task_id: taskId, member_id: member.member_id }, { onConflict: 'task_id,member_id' });
  if (error) throw error;

  return { type: 'assign_member', task_id: taskId, member_name: member.member_name };
}

async function createMember(supabase, boardId, op) {
  if (!op.member_name) throw new Error('create_member requires member_name');
  const member = await getOrCreateMember(supabase, boardId, op.member_name, op.role || 'Member');
  return { type: 'create_member', member };
}

async function executePlan(supabase, boardId, plan, dryRun = false) {
  const results = [];
  for (const op of plan.operations) {
    if (!op || !op.type) continue;

    if (dryRun) {
      results.push({ dry_run: true, op });
      continue;
    }

    if (op.type === 'create_task') {
      results.push(await createTask(supabase, boardId, op));
    } else if (op.type === 'assign_member') {
      results.push(await assignMember(supabase, boardId, op));
    } else if (op.type === 'create_member') {
      results.push(await createMember(supabase, boardId, op));
    } else {
      results.push({ skipped: true, reason: `Unsupported op type: ${op.type}` });
    }
  }
  return results;
}

async function processNaturalLanguageToSupabase({ text, boardId = 1, dryRun = false }) {
  loadEnv();
  if (!text || !text.trim()) {
    throw new Error('text is required');
  }

  const supabaseUrl = getRequiredEnv('SUPABASE_URL');
  const serviceRoleKey = getRequiredEnv('SUPABASE_SERVICE_ROLE_KEY');
  const supabase = createClient(supabaseUrl, serviceRoleKey);

  const context = await getBoardContext(supabase, boardId);
  const plan = await generatePlanFromChatGPT(text, context);
  const results = await executePlan(supabase, boardId, plan, dryRun);

  return {
    board_id: boardId,
    dry_run: dryRun,
    context,
    plan,
    results,
  };
}

module.exports = {
  processNaturalLanguageToSupabase,
};
