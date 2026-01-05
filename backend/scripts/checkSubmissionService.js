/*
  Minimal smoke-test script:
  - creates a Church
  - creates a User and assigns to Church
  - creates a Task for that Church
  - creates a Submission
  - lists my submissions

  Run:
    node scripts/checkSubmissionService.js

  Requires:
    - DATABASE_URL in backend/.env
    - applied migrations
*/

const { PrismaClient } = require('@prisma/client');
const { createUser, assignUserToChurch } = require('../src/services/userService');
const { createTask } = require('../src/services/taskService');
const { createSubmission, listMySubmissions } = require('../src/services/submissionService');

const prisma = new PrismaClient();

async function main() {
  const church = await prisma.church.create({ data: {} });

  const user = await createUser({
    firstName: 'Pavel',
    lastName: 'Sidorov',
    age: 19,
    city: 'Kazan'
  });

  await assignUserToChurch(user.id, church.id);

  const task = await createTask({
    churchId: church.id,
    title: 'Community help',
    description: 'Help the community with organizing a small event and cleaning the area afterwards.',
    category: 'COMMUNITY',
    pointsReward: 120
  });

  const submission = await createSubmission({
    userId: user.id,
    taskId: task.id,
    commentUser: 'Done! Please review.'
  });

  const my = await listMySubmissions(user.id);

  console.log({ church, user, task, submission, myCount: my.length, my });
}

main()
  .catch((e) => {
    console.error(e);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
