const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

(async () => {
  const keys = Object.keys(prisma).filter((k) => !k.startsWith('_'));
  console.log('Prisma keys (first 50):', keys.slice(0, 50));
  console.log('has submission:', !!prisma.submission);
  console.log('has quizAttempt:', !!prisma.quizAttempt);
  await prisma.$disconnect();
})().catch(async (e) => {
  console.error(e);
  try {
    await prisma.$disconnect();
  } catch {}
  process.exit(1);
});
