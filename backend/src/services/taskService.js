const { prisma } = require('../db/prisma');

class HttpError extends Error {
  constructor(status, code, message, details) {
    super(message);
    this.status = status;
    this.code = code;
    this.details = details;
  }
}

async function listTasks({
  churchId,
  activeOnly = true,
  category,
  limit = 30,
  offset = 0
}) {
  return prisma.task.findMany({
    where: {
      churchId,
      ...(activeOnly ? { isActive: true } : {}),
      ...(category ? { category } : {})
    },
    orderBy: { createdAt: 'desc' },
    take: limit,
    skip: offset
  });
}

async function getTaskById(taskId) {
  return prisma.task.findUnique({
    where: { id: taskId }
  });
}

async function createTask({
  churchId,
  title,
  description,
  category,
  pointsReward,
  createdById
}) {
  // Проверим наличие Church, чтобы вернуть 404, а не FK/500
  const church = await prisma.church.findUnique({
    where: { id: churchId },
    select: { id: true }
  });

  if (!church) {
    throw new HttpError(404, 'CHURCH_NOT_FOUND', 'Church not found');
  }

  return prisma.task.create({
    data: {
      churchId,
      title,
      description,
      category,
      pointsReward,
      createdById
    }
  });
}

async function updateTask(taskId, patch) {
  return prisma.task.update({
    where: { id: taskId },
    data: patch
  });
}

async function deactivateTask(taskId) {
  return prisma.task.update({
    where: { id: taskId },
    data: { isActive: false }
  });
}

module.exports = {
  prisma,
  HttpError,
  listTasks,
  getTaskById,
  createTask,
  updateTask,
  deactivateTask
};
