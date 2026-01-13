const { prisma } = require('../db/prisma');
const { awardTaskXp } = require('./xpService');

class HttpError extends Error {
  constructor(status, code, message, details) {
    super(message);
    this.status = status;
    this.code = code;
    this.details = details;
  }
}

async function createSubmission({ userId, taskId, commentUser }) {
  // 1) user должен существовать и состоять в церкви
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { id: true, churchId: true }
  });

  if (!user) {
    throw new HttpError(404, 'USER_NOT_FOUND', 'User not found');
  }
  if (!user.churchId) {
    throw new HttpError(409, 'USER_NOT_IN_CHURCH', 'User is not assigned to a church');
  }

  // 2) task должен существовать, быть активным и принадлежать той же церкви
  const task = await prisma.task.findUnique({
    where: { id: taskId },
    select: { id: true, churchId: true, isActive: true }
  });

  if (!task) {
    throw new HttpError(404, 'TASK_NOT_FOUND', 'Task not found');
  }
  if (task.churchId !== user.churchId) {
    throw new HttpError(409, 'TASK_DIFFERENT_CHURCH', 'Task belongs to a different church');
  }
  if (!task.isActive) {
    throw new HttpError(409, 'TASK_INACTIVE', 'Task is not active');
  }

  // 3) запрет дублей: нельзя иметь несколько "активных" сабмитов на одно задание.
  // Разрешаем повторную отправку после REJECTED (админ отклонил) — пользователь может попытаться снова.
  // После APPROVED повторная отправка запрещена.
  const existingActive = await prisma.submission.findFirst({
    where: {
      userId,
      taskId,
      status: { in: ['PENDING', 'APPROVED'] }
    },
    select: { id: true, status: true },
    orderBy: { createdAt: 'desc' }
  });

  if (existingActive) {
    if (existingActive.status === 'PENDING') {
      throw new HttpError(409, 'ALREADY_PENDING', 'Submission for this task is already pending');
    }
    if (existingActive.status === 'APPROVED') {
      throw new HttpError(409, 'ALREADY_APPROVED', 'Task already approved');
    }

    // Defensive fallback
    throw new HttpError(409, 'CONFLICT', 'Conflict');
  }

  try {
    return await prisma.submission.create({
      data: {
        churchId: user.churchId,
        userId,
        taskId,
        commentUser
      }
    });
  } catch (e) {
    // Defensive mapping for any remaining uniqueness / race conditions
    // Prisma unique violation: P2002
    if (e && e.code === 'P2002') {
      throw new HttpError(409, 'CONFLICT', 'Conflict', {
        prismaCode: e.code,
        target: e.meta?.target
      });
    }
    throw e;
  }
}

async function listMySubmissions(
  userId,
  { status, limit = 30, offset = 0, sort = 'new' } = {}
) {
  const where = {
    userId,
    ...(status ? { status } : {})
  };

  const orderBy = { createdAt: sort === 'old' ? 'asc' : 'desc' };

  const [total, items] = await prisma.$transaction([
    prisma.submission.count({ where }),
    prisma.submission.findMany({
      where,
      orderBy,
      take: limit,
      skip: offset,
      include: {
        task: {
          select: {
            id: true,
            title: true,
            pointsReward: true,
            category: true
          }
        }
      }
    })
  ]);

  return { items, total };
}

async function listPendingForChurch(
  churchId,
  { limit = 30, offset = 0, sort = 'new' } = {}
) {
  const where = { churchId, status: 'PENDING' };
  const orderBy = { createdAt: sort === 'old' ? 'asc' : 'desc' };

  const [total, items] = await prisma.$transaction([
    prisma.submission.count({ where }),
    prisma.submission.findMany({
      where,
      orderBy,
      take: limit,
      skip: offset,
      select: {
        id: true,
        status: true,
        createdAt: true,
        commentUser: true,
        user: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            age: true,
            city: true
          }
        },
        task: {
          select: {
            id: true,
            title: true,
            pointsReward: true,
            category: true
          }
        }
      }
    })
  ]);

  return { items, total };
}

async function rejectSubmission({
  submissionId,
  adminId,
  adminChurchId,
  adminRole,
  commentAdmin
}) {
  return prisma.$transaction(async (tx) => {
    const submission = await tx.submission.findUnique({
      where: { id: submissionId },
      select: {
        id: true,
        status: true,
        churchId: true
      }
    });

    if (!submission) {
      throw new HttpError(404, 'NOT_FOUND', 'Not found');
    }

    if (submission.status !== 'PENDING') {
      throw new HttpError(409, 'CONFLICT', 'Already decided');
    }

    if (adminRole !== 'SUPERADMIN') {
      if (!adminChurchId) {
        throw new HttpError(409, 'NO_CHURCH', 'User has no church selected');
      }

      if (submission.churchId !== adminChurchId) {
        throw new HttpError(403, 'FORBIDDEN', 'Forbidden');
      }
    }

    return tx.submission.update({
      where: { id: submissionId },
      data: {
        status: 'REJECTED',
        decidedAt: new Date(),
        decidedById: adminId,
        ...(commentAdmin !== undefined ? { commentAdmin } : {}),
        rewardPointsApplied: 0
      },
      select: {
        id: true,
        status: true,
        decidedAt: true,
        decidedById: true,
        commentAdmin: true,
        rewardPointsApplied: true
      }
    });
  });
}

async function approveSubmission({
  submissionId,
  adminId,
  adminChurchId,
  adminRole,
  commentAdmin
}) {
  const result = await prisma.$transaction(async (tx) => {
    const submission = await tx.submission.findUnique({
      where: { id: submissionId },
      select: {
        id: true,
        status: true,
        churchId: true,
        taskId: true,
        userId: true,
        xpAppliedAt: true,
        task: {
          select: {
            id: true,
            churchId: true,
            pointsReward: true
          }
        },
        user: {
          select: {
            id: true,
            status: true
          }
        }
      }
    });

    if (!submission) {
      throw new HttpError(404, 'NOT_FOUND', 'Not found');
    }

    if (submission.status !== 'PENDING') {
      throw new HttpError(409, 'CONFLICT', 'Already decided');
    }

    // Church restriction for ADMIN; SUPERADMIN can approve across churches
    if (adminRole !== 'SUPERADMIN') {
      if (!adminChurchId) {
        throw new HttpError(409, 'NO_CHURCH', 'User has no church selected');
      }
      if (submission.churchId !== adminChurchId) {
        throw new HttpError(403, 'FORBIDDEN', 'Forbidden');
      }
    }

    if (!submission.task || submission.task.churchId !== submission.churchId) {
      // Should not happen if DB constraints are consistent, but keep guard
      throw new HttpError(409, 'CONFLICT', 'Task belongs to a different church');
    }

    if (!submission.user || submission.user.status !== 'ACTIVE') {
      throw new HttpError(403, 'FORBIDDEN', 'Forbidden');
    }

    const pointsReward = submission.task.pointsReward;

    const updatedSubmission = await tx.submission.update({
      where: { id: submissionId },
      data: {
        status: 'APPROVED',
        decidedAt: new Date(),
        decidedById: adminId,
        ...(commentAdmin !== undefined ? { commentAdmin } : {}),
        rewardPointsApplied: pointsReward
      },
      select: {
        id: true,
        status: true,
        decidedAt: true,
        decidedById: true,
        rewardPointsApplied: true,
        commentAdmin: true
      }
    });

    await tx.pointsLedger.create({
      data: {
        churchId: submission.churchId,
        userId: submission.userId,
        type: 'TASK_REWARD',
        amount: pointsReward,
        meta: {
          submissionId: submission.id,
          taskId: submission.taskId
        }
      }
    });

    // Award XP only once per submission approval.
    if (!submission.xpAppliedAt) {
      await awardTaskXp({ userId: submission.userId, taskId: submission.taskId, at: new Date(), tx });

      await tx.submission.update({
        where: { id: submissionId },
        data: { xpAppliedAt: new Date() }
      });
    }

    return {
      submission: updatedSubmission,
      userId: submission.userId,
      churchId: submission.churchId
    };
  });

  return result;
}

module.exports = {
  prisma,
  HttpError,
  createSubmission,
  listMySubmissions,
  listPendingForChurch,
  approveSubmission,
  rejectSubmission
};
