/*
  Minimal smoke-test script:
  - creates Church
  - creates User and assigns to Church
  - adds 2 ledger entries (+ and -)
  - reads balance and monthly summary

  Run:
    node scripts/checkPointsService.js
*/

const { PrismaClient } = require('@prisma/client');
const { createUser, assignUserToChurch } = require('../src/services/userService');
const { addEntry, getBalance, getMonthlySummary } = require('../src/services/pointsService');

const prisma = new PrismaClient();

async function main() {
  const church = await prisma.church.create({ data: {} });

  const user = await createUser({
    firstName: 'Anna',
    lastName: 'Ivanova',
    age: 20,
    city: 'Sochi'
  });

  await assignUserToChurch(user.id, church.id);

  const e1 = await addEntry({
    churchId: church.id,
    userId: user.id,
    type: 'ADMIN_ADJUSTMENT',
    amount: 100,
    meta: { reason: 'Welcome bonus' }
  });

  const e2 = await addEntry({
    churchId: church.id,
    userId: user.id,
    type: 'ADMIN_ADJUSTMENT',
    amount: -30,
    meta: { reason: 'Test deduction' }
  });

  const balance = await getBalance(user.id, church.id);

  const month = new Date();
  const monthYYYYMM = `${month.getUTCFullYear()}-${String(month.getUTCMonth() + 1).padStart(2, '0')}`;
  const summary = await getMonthlySummary(user.id, church.id, monthYYYYMM);

  console.log({ church, user, e1, e2, balance, monthYYYYMM, summary });
}

main()
  .catch((e) => {
    console.error(e);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
