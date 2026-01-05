/*
  Seed ShopCatalogItem rows from a JSON file.

  Usage:
    node src/scripts/seedCatalog.js --churchId <cuid> [--file docs/catalog.seed.json]

  The JSON file must be an array of objects:
    { itemKey: string, pricePoints: number, isActive?: boolean }
*/

const fs = require('fs');
const path = require('path');

const { prisma } = require('../db/prisma');

function parseArgs(argv) {
  const args = {};
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--churchId') args.churchId = argv[++i];
    if (a === '--file') args.file = argv[++i];
  }
  return args;
}

async function main() {
  const { churchId, file } = parseArgs(process.argv.slice(2));

  if (!churchId) {
    console.error('Missing --churchId');
    process.exit(1);
  }

  const filePath = file
    ? path.resolve(process.cwd(), file)
    : path.resolve(process.cwd(), 'docs/catalog.seed.json');

  const raw = fs.readFileSync(filePath, 'utf-8');
  const items = JSON.parse(raw);

  if (!Array.isArray(items)) {
    throw new Error('Seed file must be a JSON array');
  }

  const church = await prisma.church.findUnique({
    where: { id: churchId },
    select: { id: true }
  });

  if (!church) {
    throw new Error('Church not found: ' + churchId);
  }

  const upserts = items.map((it) => {
    const itemKey = String(it.itemKey ?? '').trim();
    const pricePoints = Number(it.pricePoints);
    const isActive = it.isActive !== undefined ? Boolean(it.isActive) : true;

    if (!itemKey) {
      throw new Error('Invalid itemKey in seed');
    }
    if (!Number.isFinite(pricePoints) || pricePoints < 0) {
      throw new Error(`Invalid pricePoints for ${itemKey}`);
    }

    return prisma.shopCatalogItem.upsert({
      where: {
        churchId_itemKey: {
          churchId,
          itemKey
        }
      },
      create: {
        churchId,
        itemKey,
        pricePoints,
        isActive
      },
      update: {
        pricePoints,
        isActive
      }
    });
  });

  await prisma.$transaction(upserts);

  console.log(`Seeded ${items.length} catalog items for church ${churchId}`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
