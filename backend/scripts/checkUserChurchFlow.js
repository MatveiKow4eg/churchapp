/*
  Minimal smoke-test script:
  - creates a Church
  - creates a User
  - assigns User to Church

  Run:
    node scripts/checkUserChurchFlow.js

  Requires:
    - DATABASE_URL in backend/.env
    - applied migrations
*/

const { PrismaClient } = require('@prisma/client');
const {
  createUser,
  assignUserToChurch,
  getUserById
} = require('../src/services/userService');

const prisma = new PrismaClient();

async function main() {
  const church = await prisma.church.create({ data: {} });

  const user = await createUser({
    firstName: 'Ivan',
    lastName: 'Petrov',
    age: 18,
    city: 'Moscow'
  });

  const assigned = await assignUserToChurch(user.id, church.id);
  const loaded = await getUserById(user.id);

  console.log({ church, user, assigned, loaded });
}

main()
  .catch((e) => {
    console.error(e);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
