/**
 * One-off script to normalize existing user emails to lowercase.
 *
 * Why:
 * - Login uses `email.toLowerCase()`.
 * - If DB contains mixed-case emails, login may fail to find the user.
 *
 * This script is safe by default:
 * - It refuses to run if normalization would create duplicates.
 *
 * If you understand what you're doing, you can pass:
 *   --delete-duplicate=<strategy>
 *
 * Supported strategies:
 * - newest: keep newest (by createdAt), delete older duplicates
 * - oldest: keep oldest (by createdAt), delete newer duplicates
 * - keep=<USER_ID>: keep specific user id, delete others
 *
 * Example:
 *   cd backend
 *   node scripts/normalize_emails_lowercase.js --delete-duplicate=newest
 */

const { prisma } = require('../src/db/prisma');

function parseArgs(argv) {
  const out = { strategy: null, keepId: null };
  const arg = argv.find((a) => a.startsWith('--delete-duplicate='));
  if (!arg) return out;

  const value = arg.split('=')[1] ?? '';
  if (value === 'newest' || value === 'oldest') {
    out.strategy = value;
    return out;
  }
  if (value.startsWith('keep=')) {
    out.strategy = 'keep';
    out.keepId = value.slice('keep='.length);
    return out;
  }

  throw new Error(
    `Unknown --delete-duplicate strategy: ${value}. Use newest|oldest|keep=<USER_ID>`
  );
}

async function main() {
  const { strategy, keepId } = parseArgs(process.argv.slice(2));

  const users = await prisma.user.findMany({
    select: { id: true, email: true, createdAt: true }
  });

  // Group by normalized email
  const byNormalized = new Map(); // normalizedEmail -> [{id,email,createdAt}]
  for (const u of users) {
    const original = (u.email ?? '').trim();
    const normalized = original.toLowerCase();
    if (!normalized) continue;
    if (!byNormalized.has(normalized)) byNormalized.set(normalized, []);
    byNormalized.get(normalized).push({
      id: u.id,
      email: original,
      createdAt: u.createdAt
    });
  }

  const duplicateGroups = [...byNormalized.entries()].filter(([, arr]) => arr.length > 1);

  if (duplicateGroups.length > 0 && !strategy) {
    console.error('Email normalization would create duplicates. Resolve manually first:');
    for (const [email, arr] of duplicateGroups) {
      console.error(`  ${email} -> userIds: ${arr.map((x) => x.id).join(', ')}`);
    }
    console.error(
      '\nEither delete/merge duplicates manually, or re-run with one of:\n' +
        '  --delete-duplicate=newest\n' +
        '  --delete-duplicate=oldest\n' +
        '  --delete-duplicate=keep=<USER_ID>\n'
    );
    process.exitCode = 1;
    return;
  }

  // If strategy is provided, resolve duplicates by deleting the losing users.
  if (duplicateGroups.length > 0 && strategy) {
    console.log(`Found ${duplicateGroups.length} duplicate email groups. Resolving by strategy: ${strategy}`);

    for (const [email, arr] of duplicateGroups) {
      // Sort by createdAt
      const sorted = [...arr].sort((a, b) => new Date(a.createdAt) - new Date(b.createdAt));

      let winner;
      if (strategy === 'oldest') {
        winner = sorted[0];
      } else if (strategy === 'newest') {
        winner = sorted[sorted.length - 1];
      } else if (strategy === 'keep') {
        winner = arr.find((x) => x.id === keepId);
        if (!winner) {
          throw new Error(`keep strategy requested USER_ID=${keepId}, but it is not in group for email=${email}`);
        }
      }

      const losers = arr.filter((x) => x.id !== winner.id);

      console.log(`  Email: ${email}`);
      console.log(`    Keeping: ${winner.id} (${winner.email}, createdAt=${winner.createdAt})`);
      console.log(`    Deleting: ${losers.map((x) => x.id).join(', ')}`);

      // IMPORTANT: delete losers in a transaction.
      // If your schema has relations with ON DELETE RESTRICT, this can fail.
      // In that case you'll need to migrate relations first.
      await prisma.$transaction(async (tx) => {
        for (const l of losers) {
          await tx.user.delete({ where: { id: l.id } });
        }
      });
    }
  }

  // Re-fetch after potential deletions
  const usersAfter = await prisma.user.findMany({
    select: { id: true, email: true }
  });

  const updates = [];
  for (const u of usersAfter) {
    const original = (u.email ?? '').trim();
    const normalized = original.toLowerCase();
    if (!normalized) continue;
    if (original !== normalized) {
      updates.push({ id: u.id, from: original, to: normalized });
    }
  }

  if (updates.length === 0) {
    console.log('No emails to normalize. All emails are already lowercase.');
    return;
  }

  console.log(`Normalizing ${updates.length} emails...`);
  for (const u of updates) {
    await prisma.user.update({
      where: { id: u.id },
      data: { email: u.to }
    });
    console.log(`  ${u.id}: ${u.from} -> ${u.to}`);
  }

  console.log('Done.');
}

main()
  .catch((e) => {
    console.error(e);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
