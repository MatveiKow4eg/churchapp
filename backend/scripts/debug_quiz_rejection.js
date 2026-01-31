const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

(async () => {
  const taskId = process.argv[2];
  const userId = process.argv[3];

  if (!taskId || !userId) {
    console.error('Usage: node scripts/debug_quiz_rejection.js <taskId> <userId>');
    process.exit(1);
  }

  const attempts = await prisma.quizAttempt.findMany({
    where: { taskId, userId },
    select: { id: true, createdAt: true, scorePercent: true, isPassed: true },
    orderBy: { createdAt: 'asc' }
  });

  const submissions = await prisma.submission.findMany({
    where: { taskId, userId },
    select: { id: true, status: true, createdAt: true, decidedAt: true, commentAdmin: true },
    orderBy: { createdAt: 'asc' }
  });

  console.log(JSON.stringify({ attempts, submissions }, null, 2));

  await prisma.$disconnect();
})().catch(async (e) => {
  console.error(e);
  try {
    await prisma.$disconnect();
  } catch {}
  process.exit(1);
});
