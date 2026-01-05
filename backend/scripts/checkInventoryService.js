/*
  Minimal smoke-test script:
  - creates Church
  - creates User and assigns to Church
  - creates ShopItem
  - adds item to inventory
  - reads inventory

  Run:
    node scripts/checkInventoryService.js
*/

const { PrismaClient } = require('@prisma/client');
const { createUser, assignUserToChurch } = require('../src/services/userService');
const { createItem } = require('../src/services/shopItemService');
const { addItemToInventory, getUserInventory, hasItem } = require('../src/services/inventoryService');

const prisma = new PrismaClient();

async function main() {
  const church = await prisma.church.create({ data: {} });

  const user = await createUser({
    firstName: 'Oleg',
    lastName: 'Smirnov',
    age: 21,
    city: 'Perm'
  });

  await assignUserToChurch(user.id, church.id);

  const item = await createItem({
    churchId: church.id,
    name: 'Starter Badge',
    description: 'MVP badge',
    type: 'BADGE',
    pricePoints: 10
  });

  const inv = await addItemToInventory(user.id, item.id);
  const has = await hasItem(user.id, item.id);
  const inventory = await getUserInventory(user.id);

  console.log({ church, user, item, inv, has, inventoryCount: inventory.length, inventory });
}

main()
  .catch((e) => {
    console.error(e);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
