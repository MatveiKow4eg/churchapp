const { prisma } = require('../db/prisma');

class HttpError extends Error {
  constructor(status, code, message, details) {
    super(message);
    this.status = status;
    this.code = code;
    this.details = details;
  }
}

async function createUser({ firstName, lastName, age, city }) {
  return prisma.user.create({
    data: {
      firstName,
      lastName,
      age,
      city
    }
  });
}

async function getUserById(userId) {
  return prisma.user.findUnique({
    where: { id: userId }
  });
}

async function assignUserToChurch(userId, churchId) {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { id: true, churchId: true }
  });

  if (!user) {
    throw new HttpError(404, 'USER_NOT_FOUND', 'User not found');
  }

  if (user.churchId) {
    throw new HttpError(
      409,
      'CONFLICT',
      'User already joined a church'
    );
  }

  // Проверим, что церковь существует (чтобы вернуть 404, а не 500/foreign key)
  const church = await prisma.church.findUnique({
    where: { id: churchId },
    select: { id: true }
  });

  if (!church) {
    throw new HttpError(404, 'NOT_FOUND', 'Church not found');
  }

  return prisma.user.update({
    where: { id: userId },
    data: { churchId }
  });
}

async function setUserRole(userId, role) {
  // role валидируется на уровне zod/контроллера позже
  return prisma.user.update({
    where: { id: userId },
    data: { role }
  });
}

module.exports = {
  prisma,
  HttpError,
  createUser,
  getUserById,
  assignUserToChurch,
  setUserRole
};
