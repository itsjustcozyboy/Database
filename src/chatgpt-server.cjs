const http = require('http');
const { processNaturalLanguageToSupabase } = require('./chatgpt-agent.cjs');

const PORT = Number(process.env.CHATGPT_INGEST_PORT || 8787);

function json(res, status, body) {
  const payload = JSON.stringify(body, null, 2);
  res.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Content-Length': Buffer.byteLength(payload),
  });
  res.end(payload);
}

function parseBody(req) {
  return new Promise((resolve, reject) => {
    let body = '';
    req.on('data', (chunk) => {
      body += chunk;
    });
    req.on('end', () => {
      try {
        resolve(body ? JSON.parse(body) : {});
      } catch (error) {
        reject(new Error('Invalid JSON body'));
      }
    });
    req.on('error', reject);
  });
}

const server = http.createServer(async (req, res) => {
  try {
    if (req.method === 'GET' && req.url === '/health') {
      return json(res, 200, { ok: true, service: 'openclaw-supabase-ingest' });
    }

    if (req.method === 'POST' && req.url === '/ingest') {
      const body = await parseBody(req);
      const text = body.text || '';
      const boardId = Number(body.board_id || 1);
      const dryRun = Boolean(body.dry_run);

      const result = await processNaturalLanguageToSupabase({
        text,
        boardId,
        dryRun,
      });

      return json(res, 200, {
        ok: true,
        message: dryRun ? 'Dry run completed' : 'Ingest completed',
        ...result,
      });
    }

    return json(res, 404, { ok: false, error: 'Not found' });
  } catch (error) {
    return json(res, 400, {
      ok: false,
      error: error.message,
    });
  }
});

server.listen(PORT, () => {
  console.log(`Openclaw ingest server running on http://localhost:${PORT}`);
  console.log('POST /ingest with JSON: { "text": "...", "board_id": 1, "dry_run": false }');
});
