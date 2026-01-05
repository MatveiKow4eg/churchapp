const { prisma } = require('../db/prisma');

async function createChurch({ name, city }) {
  return prisma.church.create({
    data: {
      name,
      ...(city !== undefined ? { city } : {})
    }
  });
}

async function searchChurches({ search, limit = 20 }) {
  const q = search.trim();

  const where = {
    OR: [
      { name: { contains: q, mode: 'insensitive' } },
      { city: { contains: q, mode: 'insensitive' } }
    ]
  };

  const [items, total] = await Promise.all([
    prisma.church.findMany({
      where,
      take: limit,
      orderBy: [{ name: 'asc' }],
      select: { id: true, name: true, city: true }
    }),
    prisma.church.count({ where })
  ]);

  return { items, total };
}

module.exports = {
  createChurch,
  searchChurches
};
