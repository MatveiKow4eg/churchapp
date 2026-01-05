const statsService = require('../services/statsService');
const { HttpError } = require('../services/submissionService');

async function getLeaderboard(req, res, next) {
  try {
    const churchId = req.user?.churchId;
    const userId = req.user?.id;

    if (!churchId) {
      throw new HttpError(409, 'NO_CHURCH', 'User has no church selected');
    }

    const { month, limit, offset, includeMe } = req.query;

    const data = await statsService.getChurchLeaderboard({
      churchId,
      monthYYYYMM: month,
      limit,
      offset,
      includeMeUserId: includeMe ? userId : undefined
    });

    return res.status(200).json(data);
  } catch (err) {
    return next(err);
  }
}

module.exports = {
  getLeaderboard
};
