const { HttpError } = require('../services/taskService');
const taskService = require('../services/taskService');
const { improveTaskText } = require('../services/aiTextService');

const ALLOWED_TASK_PATCH_FIELDS = [
  'title',
  'description',
  'category',
  'pointsReward',
  'isActive'
];

async function deactivateTask(req, res, next) {
  try {
    const churchId = req.user?.churchId;
    if (!churchId) {
      throw new HttpError(409, 'NO_CHURCH', 'Admin has no church selected');
    }

    const taskId = req.params.id;

    const task = await taskService.getTaskById(taskId);
    if (!task) {
      throw new HttpError(404, 'NOT_FOUND', 'Task not found');
    }

    // SUPERADMIN/DEVELOPER can deactivate any task. ADMIN is church-scoped.
    if (req.user?.role !== 'SUPERADMIN' && req.user?.role !== 'DEVELOPER' && task.churchId !== churchId) {
      throw new HttpError(403, 'FORBIDDEN', 'Forbidden');
    }

    // Idempotent: if already inactive, return the same task.
    if (task.isActive === false) {
      return res.status(200).json({
        task: {
          id: task.id,
          title: task.title,
          description: task.description,
          category: task.category,
          pointsReward: task.pointsReward,
          isActive: task.isActive,
          createdAt: task.createdAt
        }
      });
    }

    const updated = await taskService.deactivateTask(taskId);

    return res.status(200).json({
      task: {
        id: updated.id,
        title: updated.title,
        description: updated.description,
        category: updated.category,
        pointsReward: updated.pointsReward,
        isActive: updated.isActive,
        createdAt: updated.createdAt
      }
    });
  } catch (err) {
    return next(err);
  }
}

async function createTask(req, res, next) {
  try {
    const churchId = req.user?.churchId;
    if (!churchId) {
      throw new HttpError(409, 'NO_CHURCH', 'Admin has no church selected');
    }

    const { title, description, category, pointsReward, quiz } = req.body;

    const task = await taskService.createTask({
      churchId,
      title,
      description,
      category,
      pointsReward,
      createdById: req.user.id,
      quiz
    });

    return res.status(201).json({
      task: {
        id: task.id,
        title: task.title,
        description: task.description,
        category: task.category,
        pointsReward: task.pointsReward,
        isActive: task.isActive,
        createdAt: task.createdAt
      }
    });
  } catch (err) {
    return next(err);
  }
}

async function listTasks(req, res, next) {
  try {
    const churchId = req.user?.churchId;
    if (!churchId) {
      throw new HttpError(409, 'NO_CHURCH', 'User has no church selected');
    }

    const {
      activeOnly = true,
      category,
      limit = 30,
      offset = 0
    } = req.query;

    const items = await taskService.listTasks({
      churchId,
      activeOnly,
      category,
      limit,
      offset,
      userId: req.user?.id
    });

    // В списке НЕ возвращаем вопросы/варианты (экономия трафика и не раскрываем ответы),
    // но мета для UI (например maxAttempts) можно отдавать.
    return res.status(200).json({
      items: items.map((t) => ({
        id: t.id,
        title: t.title,
        description: t.description,
        category: t.category,
        pointsReward: t.pointsReward,
        isActive: t.isActive,
        createdAt: t.createdAt,
        ...(t.quiz
          ? {
              quiz: {
                maxAttempts: t.quiz.maxAttempts,
                attemptsUsed: Array.isArray(t.quizAttempts)
                    ? t.quizAttempts.length
                    : 0,
                passScore: t.quiz.passScore,
                shuffleQuestions: t.quiz.shuffleQuestions
              }
            }
          : {})
      })),
      limit,
      offset,
      total: items.length
    });
  } catch (err) {
    return next(err);
  }
}

async function getTaskById(req, res, next) {
  try {
    const churchId = req.user?.churchId;
    if (!churchId) {
      throw new HttpError(409, 'NO_CHURCH', 'User has no church selected');
    }

    const userId = req.user?.id;
    const taskId = req.params.id;

    const task = await taskService.getTaskByIdFull(taskId);
    if (!task) {
      throw new HttpError(404, 'NOT_FOUND', 'Task not found');
    }

    // SUPERADMIN/DEVELOPER can access any task. Others are church-scoped.
    if (req.user?.role !== 'SUPERADMIN' && req.user?.role !== 'DEVELOPER' && task.churchId !== churchId) {
      throw new HttpError(403, 'FORBIDDEN', 'Forbidden');
    }

    const base = {
      id: task.id,
      title: task.title,
      description: task.description,
      category: task.category,
      pointsReward: task.pointsReward,
      isActive: task.isActive,
      createdAt: task.createdAt
    };

    if (task.category !== 'QUIZ' || !task.quiz) {
      return res.status(200).json({ task: base });
    }

    const isAdminRole = ['ADMIN', 'SUPERADMIN', 'DEVELOPER'].includes(req.user?.role);

    const attemptsUsed = await taskService.prisma.quizAttempt.count({
      where: { taskId: task.id, userId }
    });

    const quiz = {
      shuffleQuestions: task.quiz.shuffleQuestions,
      maxAttempts: task.quiz.maxAttempts,
      passScore: task.quiz.passScore,
      attemptsUsed,
      questions: task.quiz.questions.map((q) => ({
        id: q.id,
        text: q.text,
        multiSelect: q.multiSelect,
        options: q.options.map((o) => (
          isAdminRole ? { id: o.id, text: o.text, isCorrect: o.isCorrect } : { id: o.id, text: o.text }
        ))
      }))
    };

    return res.status(200).json({ task: { ...base, quiz } });
  } catch (err) {
    return next(err);
  }
}

async function updateTask(req, res, next) {
  try {
    const churchId = req.user?.churchId;
    if (!churchId) {
      throw new HttpError(409, 'NO_CHURCH', 'Admin has no church selected');
    }

    const taskId = req.params.id;

    // Empty patch guard (only allow the whitelisted fields)
    const patch = {};
    for (const key of ALLOWED_TASK_PATCH_FIELDS) {
      if (req.body[key] !== undefined) patch[key] = req.body[key];
    }
    const quizPatch = req.body.quiz;

    if (Object.keys(patch).length === 0 && quizPatch === undefined) {
      throw new HttpError(400, 'EMPTY_PATCH', 'Patch body is empty');
    }

    const task = await taskService.getTaskById(taskId);
    if (!task) {
      throw new HttpError(404, 'NOT_FOUND', 'Task not found');
    }

    // SUPERADMIN/DEVELOPER can edit any task. ADMIN is church-scoped.
    if (req.user?.role !== 'SUPERADMIN' && req.user?.role !== 'DEVELOPER' && task.churchId !== churchId) {
      throw new HttpError(403, 'FORBIDDEN', 'Forbidden');
    }

    const updated = quizPatch !== undefined
      ? await taskService.updateTaskWithQuiz(taskId, patch, quizPatch)
      : await taskService.updateTask(taskId, patch);

    return res.status(200).json({
      task: {
        id: updated.id,
        title: updated.title,
        description: updated.description,
        category: updated.category,
        pointsReward: updated.pointsReward,
        isActive: updated.isActive,
        createdAt: updated.createdAt
      }
    });
  } catch (err) {
    return next(err);
  }
}

async function deleteTask(req, res, next) {
  try {
    const churchId = req.user?.churchId;
    if (!churchId) {
      throw new HttpError(409, 'NO_CHURCH', 'Admin has no church selected');
    }

    const taskId = req.params.id;

    const task = await taskService.getTaskById(taskId);
    if (!task) {
      throw new HttpError(404, 'NOT_FOUND', 'Task not found');
    }

    // SUPERADMIN/DEVELOPER can delete any task. ADMIN is church-scoped.
    if (req.user?.role !== 'SUPERADMIN' && req.user?.role !== 'DEVELOPER' && task.churchId !== churchId) {
      throw new HttpError(403, 'FORBIDDEN', 'Forbidden');
    }

    await taskService.deleteTask(taskId);

    return res.status(200).json({ ok: true });
  } catch (err) {
    return next(err);
  }
}

async function improveTaskTextController(req, res, next) {
  try {
    const churchId = req.user?.churchId;
    if (!churchId) {
      throw new HttpError(409, 'NO_CHURCH', 'Admin has no church selected');
    }

    const { title, description } = req.body;

    const improved = await improveTaskText({ title, description });

    return res.status(200).json({
      title: improved.title,
      description: improved.description
    });
  } catch (err) {
    return next(err);
  }
}

async function startQuizAttemptController(req, res, next) {
  try {
    const userId = req.user?.id;
    const churchId = req.user?.churchId;
    if (!churchId) throw new HttpError(409, 'NO_CHURCH', 'User has no church selected');
    const taskId = req.params.id;

    const attempt = await taskService.startQuizAttempt({ userId, taskId });
    return res.status(201).json({ attemptId: attempt.id, createdAt: attempt.createdAt });
  } catch (err) {
    return next(err);
  }
}

async function submitQuizAttemptController(req, res, next) {
  try {
    const userId = req.user?.id;
    const churchId = req.user?.churchId;
    if (!churchId) throw new HttpError(409, 'NO_CHURCH', 'User has no church selected');
    const taskId = req.params.id;
    const attemptId = req.params.attemptId;
    const { answers } = req.body || {};

    const result = await taskService.submitQuizAttempt({ userId, taskId, attemptId, answers });
    return res.status(200).json(result);
  } catch (err) {
    return next(err);
  }
}

module.exports = {
  listTasks,
  getTaskById,
  createTask,
  updateTask,
  deactivateTask,
  deleteTask,
  improveTaskTextController,
  startQuizAttemptController,
  submitQuizAttemptController
};
