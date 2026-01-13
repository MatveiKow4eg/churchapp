const statsService = require('../services/statsService');
const { HttpError } = require('../services/submissionService');

async function getMyMonthlyStats(req, res, next) {
  try {
    const userId = req.user?.id;
    const churchId = req.user?.churchId;

    if (!churchId) {
      throw new HttpError(409, 'NO_CHURCH', 'User has no church selected');
    }

    const { month } = req.query;

    const stats = await statsService.getUserMonthlyStats({
      userId,
      churchId,
      monthYYYYMM: month
    });

    // If topCategories is empty, still return it (optional field in spec)
    const { topCategories, ...rest } = stats;

    return res.status(200).json({
      ...rest,
      ...(topCategories && topCategories.length > 0 ? { topCategories } : {})
    });
  } catch (err) {
    return next(err);
  }
}

async function getChurchStats(req, res, next) {
  try {
    const churchId = req.user?.churchId;

    if (!churchId) {
      throw new HttpError(409, 'NO_CHURCH', 'User has no church selected');
    }

    const { month } = req.query;

    const stats = await statsService.getChurchMonthlyStats({
      churchId,
      monthYYYYMM: month
    });

    const { topTasks, members, ...rest } = stats;

    return res.status(200).json({
      ...rest,
      ...(topTasks && topTasks.length > 0 ? { topTasks } : {}),
      ...(members && members.length > 0 ? { members } : { members: [] })
    });
  } catch (err) {
    return next(err);
  }
}

module.exports = {
  getMyMonthlyStats,
  getChurchStats
};
