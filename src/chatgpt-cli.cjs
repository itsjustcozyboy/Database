const { processNaturalLanguageToSupabase } = require('./chatgpt-agent.cjs');

async function main() {
  const args = process.argv.slice(2);
  const dryRun = args.includes('--dry-run');
  const filtered = args.filter((a) => a !== '--dry-run');
  const text = filtered.join(' ').trim();

  if (!text) {
    console.error('Usage: npm run openclaw:ingest -- "작업 추가해줘 ..." [--dry-run]');
    process.exit(1);
  }

  try {
    const result = await processNaturalLanguageToSupabase({
      text,
      boardId: 1,
      dryRun,
    });
    console.log(JSON.stringify(result, null, 2));
  } catch (error) {
    console.error('[ERROR]', error.message);
    process.exit(1);
  }
}

main();
