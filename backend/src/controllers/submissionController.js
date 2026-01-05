const submissionService = require('../services/submissionService');
const userService = require('../services/userService');
const pointsService = require('../services/pointsService');
const { HttpError } = require('../services/submissionService');

async function createSubmission(req, res, next) {
  try {
    const userId = req.user?.id;
    const churchId = req.user?.churchId;

    if (!churchId) {
      throw new HttpError(409, 'NO_CHURCH', 'User has no church selected');
    }

    // Requirement: if user.status=BANNED -> 403 FORBIDDEN
    const me = await userService.getUserById(userId);
    if (!me) {
      throw new HttpError(404, 'USER_NOT_FOUND', 'User not found');
    }
    if (me.status === 'BANNED') {
      throw new HttpError(403, 'FORBIDDEN', 'Forbidden');
    }

    const { taskId, commentUser } = req.body;

    // Ensure user's church matches JWT church
    if (me.churchId !== churchId) {
      throw new HttpError(409, 'NO_CHURCH', 'User has no church selected');
    }

    const submission = await submissionService.createSubmission({
      userId,
      taskId,
      commentUser
    });

    return res.status(201).json({
      submission: {
        id: submission.id,
        status: submission.status,
        taskId: submission.taskId,
        userId: submission.userId,
        churchId: submission.churchId,
        commentUser: submission.commentUser,
        createdAt: submission.createdAt
      }
    });
  } catch (err) {
    // Normalize duplicate error code per spec
    if (err && err.status === 409) {
      if (err.code === 'SUBMISSION_ALREADY_EXISTS') {
        err.code = 'CONFLICT';
        if (!err.message) err.message = 'Conflict';
      }
    }

    return next(err);
  }
}

async function listMine(req, res, next) {
  try {
    const userId = req.user?.id;
    const churchId = req.user?.churchId;

    if (!churchId) {
      throw new HttpError(409, 'NO_CHURCH', 'User has no church selected');
    }

    const { status, limit, offset, sort } = req.query;

    const { items, total } = await submissionService.listMySubmissions(userId, {
      status,
      limit,
      offset,
      sort
    });

    return res.status(200).json({
      items: items.map((s) => ({
        id: s.id,
        status: s.status,
        createdAt: s.createdAt,
        decidedAt: s.decidedAt,
        commentUser: s.commentUser,
        commentAdmin: s.commentAdmin,
        rewardPointsApplied: s.rewardPointsApplied,
        task: s.task
          ? {
              id: s.task.id,
              title: s.task.title,
              pointsReward: s.task.pointsReward,
              category: s.task.category
            }
          : null
      })),
      limit,
      offset,
      total
    });
  } catch (err) {
    return next(err);
  }
}

async function listPending(req, res, next) {
  try {
    const churchId = req.user?.churchId;

    if (!churchId) {
      throw new HttpError(409, 'NO_CHURCH', 'User has no church selected');
    }

    const { limit, offset, sort } = req.query;

    const { items, total } = await submissionService.listPendingForChurch(churchId, {
      limit,
      offset,
      sort
    });

    return res.status(200).json({
      items,
      limit,
      offset,
      total
    });
  } catch (err) {
    return next(err);
  }
}

async function approve(req, res, next) {
  try {
    const submissionId = req.params.id;

    const adminId = req.user?.id;
    const adminRole = req.user?.role;
    const adminChurchId = req.user?.churchId;

    // Spec: if admin has no churchId -> 409 NO_CHURCH
    // (even though SUPERADMIN could approve across churches, we keep spec in controller only for admins?)
    // Spec explicitly says: churchId брать из req.user.churchId; если отсутствует -> 409 NO_CHURCH
    // We'll enforce it for any admin role.
    if (!adminChurchId) {
      throw new HttpError(409, 'NO_CHURCH', 'User has no church selected');
    }

    const { commentAdmin } = req.body || {};

    const { submission, userId, churchId } = await submissionService.approveSubmission({
      submissionId,
      adminId,
      adminChurchId,
      adminRole,
      commentAdmin
    });

    const balance = await pointsService.getBalance(userId, churchId);

    return res.status(200).json({
      submission: {
        id: submission.id,
        status: submission.status,
        decidedAt: submission.decidedAt,
        decidedById: submission.decidedById,
        rewardPointsApplied: submission.rewardPointsApplied,
        ...(submission.commentAdmin ? { commentAdmin: submission.commentAdmin } : {})
      },
      balance
    });
  } catch (err) {
    return next(err);
  }
}

async function reject(req, res, next) {
  try {
    const submissionId = req.params.id;

    const adminId = req.user?.id;
    const adminRole = req.user?.role;
    const adminChurchId = req.user?.churchId;

    if (!adminChurchId) {
      throw new HttpError(409, 'NO_CHURCH', 'User has no church selected');
    }

    const { commentAdmin } = req.body || {};

    const submission = await submissionService.rejectSubmission({
      submissionId,
      adminId,
      adminChurchId,
      adminRole,
      commentAdmin
    });

    return res.status(200).json({
      submission: {
        id: submission.id,
        status: submission.status,
        decidedAt: submission.decidedAt,
        decidedById: submission.decidedById,
        rewardPointsApplied: submission.rewardPointsApplied,
        ...(submission.commentAdmin ? { commentAdmin: submission.commentAdmin } : {})
      }
    });
  } catch (err) {
    return next(err);
  }
}

module.exports = {
  createSubmission,
  listMine,
  listPending,
  approve,
  reject
};
