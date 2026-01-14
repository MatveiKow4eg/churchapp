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

    // SUPERADMIN can deactivate any task. ADMIN is church-scoped.
    if (req.user?.role !== 'SUPERADMIN' && task.churchId !== churchId) {
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

    const { title, description, category, pointsReward } = req.body;

    const task = await taskService.createTask({
      churchId,
      title,
      description,
      category,
      pointsReward,
      createdById: req.user.id
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
      offset
    });

    return res.status(200).json({
      items: items.map((t) => ({
        id: t.id,
        title: t.title,
        description: t.description,
        category: t.category,
        pointsReward: t.pointsReward,
        isActive: t.isActive,
        createdAt: t.createdAt
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

    const taskId = req.params.id;

    const task = await taskService.getTaskById(taskId);
    if (!task) {
      throw new HttpError(404, 'NOT_FOUND', 'Task not found');
    }

    // SUPERADMIN can access any task. Others are church-scoped.
    if (req.user?.role !== 'SUPERADMIN' && task.churchId !== churchId) {
      throw new HttpError(403, 'FORBIDDEN', 'Forbidden');
    }

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

    if (Object.keys(patch).length === 0) {
      throw new HttpError(400, 'EMPTY_PATCH', 'Patch body is empty');
    }

    const task = await taskService.getTaskById(taskId);
    if (!task) {
      throw new HttpError(404, 'NOT_FOUND', 'Task not found');
    }

    // SUPERADMIN can edit any task. ADMIN is church-scoped.
    if (req.user?.role !== 'SUPERADMIN' && task.churchId !== churchId) {
      throw new HttpError(403, 'FORBIDDEN', 'Forbidden');
    }

    const updated = await taskService.updateTask(taskId, patch);

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

    // SUPERADMIN can delete any task. ADMIN is church-scoped.
    if (req.user?.role !== 'SUPERADMIN' && task.churchId !== churchId) {
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

module.exports = {
  listTasks,
  getTaskById,
  createTask,
  updateTask,
  deactivateTask,
  deleteTask,
  improveTaskTextController
};
