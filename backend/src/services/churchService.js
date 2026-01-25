const { prisma } = require('../db/prisma');
const { generateJoinCode } = require('../utils/joinCode');

async function createChurch({ name, city }) {
  // joinCode must be unique. If collision occurs, retry.
  // Prisma throws P2002 (unique constraint) on conflict.
  for (let attempt = 0; attempt < 10; attempt += 1) {
    try {
      return await prisma.church.create({
        data: {
          name,
          ...(city !== undefined ? { city } : {}),
          joinCode: generateJoinCode(8)
        }
      });
    } catch (err) {
      if (err && err.code === 'P2002') continue;
      throw err;
    }
  }

  // Fallback (extremely unlikely)
  return prisma.church.create({
    data: {
      name,
      ...(city !== undefined ? { city } : {}),
      joinCode: generateJoinCode(10)
    }
  });
}

async function rotateChurchJoinCode(churchId) {
  // Ensure church exists
  const exists = await prisma.church.findUnique({
    where: { id: churchId },
    select: { id: true }
  });

  if (!exists) {
    const e = new Error('Church not found');
    e.status = 404;
    e.code = 'NOT_FOUND';
    throw e;
  }

  for (let attempt = 0; attempt < 10; attempt += 1) {
    try {
      return await prisma.church.update({
        where: { id: churchId },
        data: { joinCode: generateJoinCode(8) }
      });
    } catch (err) {
      if (err && err.code === 'P2002') continue;
      throw err;
    }
  }

  return prisma.church.update({
    where: { id: churchId },
    data: { joinCode: generateJoinCode(10) }
  });
}

async function searchChurches({ search, limit = 20 }) {
  const q = (search ?? '').trim();

  // If no search query provided, return first churches (for "Create church" screen, etc.)
  const where = q
    ? {
        OR: [
          { name: { contains: q, mode: 'insensitive' } },
          { city: { contains: q, mode: 'insensitive' } }
        ]
      }
    : undefined;

  const [items, total] = await Promise.all([
    prisma.church.findMany({
      ...(where ? { where } : {}),
      take: limit,
      orderBy: [{ name: 'asc' }],
      select: { id: true, name: true, city: true }
    }),
    prisma.church.count(where ? { where } : undefined)
  ]);

  return { items, total };
}

module.exports = {
  createChurch,
  rotateChurchJoinCode,
  searchChurches
};
