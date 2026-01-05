/*
  Minimal smoke-test script:
  - creates Church
  - creates 2 shop items
  - lists items (activeOnly + type filter)

  Run:
    node scripts/checkShopItemService.js
*/

const { PrismaClient } = require('@prisma/client');
const { createItem, listItems } = require('../src/services/shopItemService');

const prisma = new PrismaClient();

async function main() {
  const church = await prisma.church.create({ data: {} });

  const item1 = await createItem({
    churchId: church.id,
    name: 'Cool Badge',
    description: 'A cosmetic badge for your profile',
    type: 'BADGE',
    pricePoints: 250
  });

  const item2 = await createItem({
    churchId: church.id,
    name: 'Profile Theme',
    description: 'Unlock a new profile theme',
    type: 'COSMETIC',
    pricePoints: 500
  });

  const activeAll = await listItems({ churchId: church.id, activeOnly: true });
  const onlyBadges = await listItems({
    churchId: church.id,
    activeOnly: true,
    type: 'BADGE'
  });

  console.log({ church, item1, item2, activeAllCount: activeAll.length, onlyBadgesCount: onlyBadges.length, activeAll, onlyBadges });
}

main()
  .catch((e) => {
    console.error(e);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
