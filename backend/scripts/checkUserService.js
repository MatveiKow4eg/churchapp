// Простой скрипт проверки Prisma моделей и userService без эндпоинтов.
// Запуск:
//   node scripts/checkUserService.js

require('dotenv').config();

const {
  prisma,
  createUser,
  assignUserToChurch,
  getUserById
} = require('../src/services/userService');

async function main() {
  // 1) Создаём церковь
  const church = await prisma.church.create({ data: {} });

  // 2) Создаём пользователя
  const user = await createUser({
    firstName: 'John',
    lastName: 'Doe',
    age: 18,
    city: 'Boston'
  });

  // 3) Привязываем пользователя к церкви
  const updated = await assignUserToChurch(user.id, church.id);

  // 4) Достаём пользователя
  const loaded = await getUserById(user.id);

  console.log({ church, user, updated, loaded });
}

main()
  .catch((e) => {
    console.error(e);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
