const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

(async () => {
  const models = prisma._runtimeDataModel?.models;
  console.log('runtime models:', models ? Object.keys(models) : null);
  await prisma.$disconnect();
})().catch(async (e) => {
  console.error(e);
  try {
    await prisma.$disconnect();
  } catch {}
  process.exit(1);
});
