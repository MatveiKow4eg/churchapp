/*
  Minimal smoke-test script:
  - creates a Church
  - creates a Task
  - fetches listTasks

  Run:
    node scripts/checkTaskService.js

  Requires:
    - DATABASE_URL in backend/.env
    - applied migrations
*/

const { PrismaClient } = require('@prisma/client');
const { createTask, listTasks } = require('../src/services/taskService');

const prisma = new PrismaClient();

async function main() {
  const church = await prisma.church.create({ data: {} });

  const task = await createTask({
    churchId: church.id,
    title: 'Help with Sunday service',
    description: 'Assist the team with preparation and organization for the Sunday service.',
    category: 'SERVICE',
    pointsReward: 50
  });

  const tasksActive = await listTasks({ churchId: church.id, activeOnly: true });
  const tasksAll = await listTasks({ churchId: church.id, activeOnly: false });

  console.log({ church, task, tasksActiveCount: tasksActive.length, tasksAllCount: tasksAll.length, tasksActive, tasksAll });
}

main()
  .catch((e) => {
    console.error(e);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
