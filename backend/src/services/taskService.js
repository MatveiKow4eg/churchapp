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
  offset = 0,
  userId
}) {
  const tasks = await prisma.task.findMany({
    where: {
      churchId,
      ...(activeOnly ? { isActive: true } : {}),
      ...(category ? { category } : {})
    },
    include: {
      quiz: true,
      quizAttempts: userId
          ? {
              where: { userId },
              select: { id: true }
            }
          : false
    },
    orderBy: { createdAt: 'desc' },
    take: limit,
    skip: offset
  });

  if (!userId) return tasks;

  const taskIds = tasks.map((t) => t.id);
  if (taskIds.length === 0) return tasks;

  const counts = await prisma.quizAttempt.groupBy({
    by: ['taskId'],
    where: {
      userId,
      taskId: { in: taskIds }
    },
    _count: { _all: true }
  });

  const attemptsMap = new Map(counts.map((c) => [c.taskId, c._count._all]));

  return tasks.map((t) => ({
    ...t,
    _attemptsUsed: attemptsMap.get(t.id) ?? 0
  }));
}

async function getTaskById(taskId) {
  return prisma.task.findUnique({
    where: { id: taskId }
  });
}

async function getTaskByIdFull(taskId) {
  return prisma.task.findUnique({
    where: { id: taskId },
    include: {
      quiz: {
        include: {
          questions: {
            orderBy: { order: 'asc' },
            include: { options: { orderBy: { order: 'asc' } } }
          }
        }
      }
    }
  });
}

async function createTask({
  churchId,
  title,
  description,
  category,
  pointsReward,
  createdById,
  quiz
}) {
  // Проверим наличие Church, чтобы вернуть 404, а не FK/500
  const church = await prisma.church.findUnique({
    where: { id: churchId },
    select: { id: true }
  });

  if (!church) {
    throw new HttpError(404, 'CHURCH_NOT_FOUND', 'Church not found');
  }

  if (category === 'QUIZ') {
    // Транзакционно создаём Task + Quiz + Questions + Options
    return prisma.$transaction(async (tx) => {
      const task = await tx.task.create({
        data: { churchId, title, description, category, pointsReward, createdById }
      });

      await tx.quiz.create({
        data: {
          id: task.id,
          shuffleQuestions: Boolean(quiz?.shuffleQuestions ?? false),
          maxAttempts: quiz?.maxAttempts ?? null,
          passScore: quiz?.passScore ?? 70
        }
      });

      const questions = quiz?.questions ?? [];
      for (let qi = 0; qi < questions.length; qi++) {
        const q = questions[qi];
        const createdQ = await tx.quizQuestion.create({
          data: {
            quizId: task.id,
            order: qi + 1,
            text: q.text,
            multiSelect: Boolean(q.multiSelect ?? false)
          }
        });

        for (let oi = 0; oi < (q.options ?? []).length; oi++) {
          const opt = q.options[oi];
          await tx.quizOption.create({
            data: {
              questionId: createdQ.id,
              order: oi + 1,
              text: opt.text,
              isCorrect: Boolean(opt.isCorrect)
            }
          });
        }
      }

      return task;
    });
  }

  // Обычное задание
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

async function updateTaskWithQuiz(taskId, patch, quizPatch) {
  return prisma.$transaction(async (tx) => {
    // Обновим сам Task
    const task = await tx.task.update({ where: { id: taskId }, data: patch });

    if (quizPatch) {
      // Убедимся, что quiz существует (если не существовал — создадим)
      let quiz = await tx.quiz.findUnique({ where: { id: taskId } });
      if (!quiz) {
        quiz = await tx.quiz.create({
          data: {
            id: taskId,
            shuffleQuestions: Boolean(quizPatch.shuffleQuestions ?? false),
            maxAttempts: quizPatch.maxAttempts ?? null,
            passScore: quizPatch.passScore ?? 70
          }
        });
      } else {
        // Обновим метаполя
        await tx.quiz.update({
          where: { id: taskId },
          data: {
            ...(quizPatch.shuffleQuestions !== undefined
              ? { shuffleQuestions: Boolean(quizPatch.shuffleQuestions) }
              : {}),
            ...(quizPatch.maxAttempts !== undefined ? { maxAttempts: quizPatch.maxAttempts } : {}),
            ...(quizPatch.passScore !== undefined ? { passScore: quizPatch.passScore } : {})
          }
        });
      }

      // Если присланы вопросы, проверим, нет ли попыток. Если есть — запретим структурные изменения.
      if (quizPatch.questions) {
        const attempts = await tx.quizAttempt.count({ where: { taskId } });
        if (attempts > 0) {
          throw new HttpError(409, 'QUIZ_LOCKED', 'Quiz structure cannot be changed after attempts exist');
        }

        // Пересоберём вопросы/варианты
        const existingQs = await tx.quizQuestion.findMany({ where: { quizId: taskId }, select: { id: true } });
        const existingQIds = existingQs.map((x) => x.id);
        if (existingQIds.length > 0) {
          await tx.quizOption.deleteMany({ where: { questionId: { in: existingQIds } } });
          await tx.quizQuestion.deleteMany({ where: { id: { in: existingQIds } } });
        }

        for (let qi = 0; qi < quizPatch.questions.length; qi++) {
          const q = quizPatch.questions[qi];
          const createdQ = await tx.quizQuestion.create({
            data: {
              quizId: taskId,
              order: qi + 1,
              text: q.text,
              multiSelect: Boolean(q.multiSelect ?? false)
            }
          });
          for (let oi = 0; oi < (q.options ?? []).length; oi++) {
            const opt = q.options[oi];
            await tx.quizOption.create({
              data: {
                questionId: createdQ.id,
                order: oi + 1,
                text: opt.text,
                isCorrect: Boolean(opt.isCorrect)
              }
            });
          }
        }
      }
    }

    return task;
  });
}

async function deactivateTask(taskId) {
  return prisma.task.update({
    where: { id: taskId },
    data: { isActive: false }
  });
}

async function deleteTask(taskId) {
  // Preserve user history by snapshotting task fields into submissions and DETACHING submissions
  // before the task is deleted.
  //
  // This works even if some DB relations are still configured with ON DELETE CASCADE,
  // because after detaching there are no Submission rows referencing the Task.
  return prisma.$transaction(async (tx) => {
    const task = await tx.task.findUnique({
      where: { id: taskId },
      select: { id: true, title: true, category: true, pointsReward: true }
    });

    if (task) {
      // Snapshot to all submissions of this task (any status)
      await tx.submission.updateMany({
        where: { taskId },
        data: {
          taskTitle: task.title,
          taskCategory: task.category,
          taskPointsReward: task.pointsReward,
          // Detach so submissions are not removed by cascade.
          taskId: null
        }
      });
    }

    return tx.task.delete({ where: { id: taskId } });
  });
}

async function startQuizAttempt({ userId, taskId }) {
  // Проверим пользователя и задание
  const user = await prisma.user.findUnique({ where: { id: userId }, select: { id: true, churchId: true, status: true } });
  if (!user) throw new HttpError(404, 'USER_NOT_FOUND', 'User not found');
  if (user.status !== 'ACTIVE') throw new HttpError(403, 'FORBIDDEN', 'Forbidden');
  if (!user.churchId) throw new HttpError(409, 'NO_CHURCH', 'User has no church selected');

  const task = await prisma.task.findUnique({
    where: { id: taskId },
    include: { quiz: true }
  });
  if (!task) throw new HttpError(404, 'TASK_NOT_FOUND', 'Task not found');
  if (!task.isActive) throw new HttpError(409, 'TASK_INACTIVE', 'Task is not active');
  if (task.churchId !== user.churchId) throw new HttpError(409, 'TASK_DIFFERENT_CHURCH', 'Task belongs to a different church');
  if (!task.quiz) throw new HttpError(409, 'NOT_A_QUIZ', 'Task is not a quiz');

  // Лимит попыток
  if (task.quiz.maxAttempts && task.quiz.maxAttempts > 0) {
    const attemptsCount = await prisma.quizAttempt.count({ where: { taskId, userId } });
    if (attemptsCount >= task.quiz.maxAttempts) {
      throw new HttpError(403, 'MAX_ATTEMPTS_REACHED', 'Max attempts reached');
    }
  }

  const attempt = await prisma.quizAttempt.create({
    data: {
      taskId,
      userId,
      scorePercent: 0,
      isPassed: false
    }
  });

  // If this attempt makes user reach the maxAttempts limit (and they haven't passed yet),
  // auto-create a REJECTED submission so the task moves to "My submissions -> Rejected".
  if (task.quiz.maxAttempts && task.quiz.maxAttempts > 0) {
    const attemptsCount = await prisma.quizAttempt.count({ where: { taskId, userId } });
    if (attemptsCount >= task.quiz.maxAttempts) {
      const approved = await prisma.submission.findFirst({
        where: { userId, taskId, status: 'APPROVED' },
        select: { id: true }
      });

      if (!approved) {
        const existingRejected = await prisma.submission.findFirst({
          where: { userId, taskId, status: 'REJECTED' },
          select: { id: true }
        });

        if (existingRejected) {
          await prisma.submission.update({
            where: { id: existingRejected.id },
            data: { decidedAt: new Date(), commentAdmin: 'MAX_ATTEMPTS_REACHED' }
          });
        } else {
          await prisma.submission.create({
            data: {
              churchId: task.churchId,
              userId,
              taskId,
              status: 'REJECTED',
              decidedAt: new Date(),
              commentAdmin: 'MAX_ATTEMPTS_REACHED'
            }
          });
        }
      }
    }
  }

  return attempt;
}

async function submitQuizAttempt({ userId, taskId, attemptId, answers }) {
  return prisma.$transaction(async (tx) => {
    const user = await tx.user.findUnique({ where: { id: userId }, select: { id: true, churchId: true, status: true } });
    if (!user) throw new HttpError(404, 'USER_NOT_FOUND', 'User not found');
    if (user.status !== 'ACTIVE') throw new HttpError(403, 'FORBIDDEN', 'Forbidden');
    if (!user.churchId) throw new HttpError(409, 'NO_CHURCH', 'User has no church selected');

    const task = await tx.task.findUnique({
      where: { id: taskId },
      include: {
        church: { select: { id: true } },
        quiz: {
          include: {
            questions: { include: { options: true } }
          }
        }
      }
    });
    if (!task) throw new HttpError(404, 'TASK_NOT_FOUND', 'Task not found');
    if (!task.isActive) throw new HttpError(409, 'TASK_INACTIVE', 'Task is not active');
    if (task.churchId !== user.churchId) throw new HttpError(409, 'TASK_DIFFERENT_CHURCH', 'Task belongs to a different church');
    if (!task.quiz) throw new HttpError(409, 'NOT_A_QUIZ', 'Task is not a quiz');

    // Проверим попытку
    const attempt = await tx.quizAttempt.findUnique({ where: { id: attemptId } });
    if (!attempt || attempt.taskId !== taskId || attempt.userId !== userId) {
      throw new HttpError(404, 'ATTEMPT_NOT_FOUND', 'Attempt not found');
    }

    // Составим карту правильных ответов по каждому вопросу
    const correctMap = new Map(); // questionId -> Set(correct option ids)
    for (const q of task.quiz.questions) {
      const correct = new Set(q.options.filter((o) => o.isCorrect).map((o) => o.id));
      correctMap.set(q.id, { correct, multiSelect: q.multiSelect });
    }

    // Подсчёт правильных
    let correctCount = 0;
    let total = task.quiz.questions.length;

    for (const ans of answers ?? []) {
      const qm = correctMap.get(ans.questionId);
      if (!qm) continue; // неизвестный вопрос — игнорируем
      const selected = new Set((ans.selectedOptionIds ?? []).map(String));
      const corr = qm.correct;
      // Ответ верен, если множества совпада��т
      if (selected.size === corr.size && [...selected].every((id) => corr.has(id))) {
        correctCount += 1;
      }
    }

    const scorePercent = total > 0 ? Math.round((correctCount / total) * 100) : 0;
    const isPassed = scorePercent >= (task.quiz.passScore ?? 70);

    // Сохраним ответы
    for (const ans of answers ?? []) {
      await tx.quizAnswer.create({
        data: {
          attemptId: attempt.id,
          questionId: ans.questionId,
          selectedOptionIds: ans.selectedOptionIds ?? []
        }
      });
    }

    // Обновим результат попытки
    await tx.quizAttempt.update({
      where: { id: attempt.id },
      data: { scorePercent, isPassed }
    });

    // Если не прошёл и это была последняя попытка — авто-отклоняем.
    // Это нужно, чтобы заявка сразу появилась в "Мои заявки -> Отклонено"
    // (без ожидания следующего запроса startQuizAttempt / перезапуска приложения).
    if (!isPassed && task.quiz.maxAttempts && task.quiz.maxAttempts > 0) {
      const attemptsCount = await tx.quizAttempt.count({ where: { taskId, userId } });
      if (attemptsCount >= task.quiz.maxAttempts) {
        const approved = await tx.submission.findFirst({
          where: { userId, taskId, status: 'APPROVED' },
          select: { id: true }
        });

        if (!approved) {
          const existingRejected = await tx.submission.findFirst({
            where: { userId, taskId, status: 'REJECTED' },
            select: { id: true }
          });

          if (existingRejected) {
            await tx.submission.update({
              where: { id: existingRejected.id },
              data: { decidedAt: new Date(), commentAdmin: 'MAX_ATTEMPTS_REACHED' }
            });
          } else {
            await tx.submission.create({
              data: {
                churchId: task.churchId,
                userId,
                taskId,
                status: 'REJECTED',
                decidedAt: new Date(),
                commentAdmin: 'MAX_ATTEMPTS_REACHED'
              }
            });
          }
        }
      }
    }

    // Если прошёл — авто-approve награды (без модерации), один раз на пользователя и задачу
    if (isPassed) {
      const alreadyApproved = await tx.submission.findFirst({
        where: { userId, taskId, status: 'APPROVED' },
        select: { id: true }
      });
      if (!alreadyApproved) {
        const submission = await tx.submission.create({
          data: {
            churchId: task.churchId,
            userId,
            taskId,
            status: 'APPROVED',
            decidedAt: new Date(),
            rewardPointsApplied: task.pointsReward
          },
          select: { id: true }
        });

        await tx.pointsLedger.create({
          data: {
            churchId: task.churchId,
            userId,
            type: 'TASK_REWARD',
            amount: task.pointsReward,
            meta: { taskId, submissionId: submission.id }
          }
        });
      }
    }

    return { scorePercent, isPassed };
  });
}

module.exports = {
  prisma,
  HttpError,
  listTasks,
  getTaskById,
  getTaskByIdFull,
  createTask,
  updateTask,
  updateTaskWithQuiz,
  deactivateTask,
  deleteTask,
  startQuizAttempt,
  submitQuizAttempt
};
