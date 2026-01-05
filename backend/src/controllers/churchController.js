const { createChurch, searchChurches } = require('../services/churchService');
const { prisma } = require('../db/prisma');
const { assignUserToChurch } = require('../services/userService');
const { signAccessToken } = require('../utils/jwt');

class HttpError extends Error {
  constructor(status, code, message, details) {
    super(message);
    this.status = status;
    this.code = code;
    this.details = details;
  }
}

async function create(req, res, next) {
  try {
    const church = await createChurch(req.body);

    return res.status(201).json({
      church: {
        id: church.id,
        name: church.name,
        city: church.city,
        createdAt: church.createdAt
      }
    });
  } catch (err) {
    return next(err);
  }
}

async function joinChurch(req, res, next) {
  try {
    const churchId = req.params.id;
    const userId = req.user.id;

    // Need status check (BANNED => 403)
    const userBefore = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        firstName: true,
        lastName: true,
        role: true,
        status: true,
        churchId: true
      }
    });

    if (!userBefore) {
      throw new HttpError(404, 'NOT_FOUND', 'User not found');
    }

    if (userBefore.status === 'BANNED') {
      throw new HttpError(403, 'FORBIDDEN', 'User is banned');
    }

    const updatedUser = await assignUserToChurch(userId, churchId);

    // Return minimal church {id, name}
    const church = await prisma.church.findUnique({
      where: { id: churchId },
      select: { id: true, name: true }
    });

    // If something deleted church between checks (very unlikely), keep response consistent
    if (!church) {
      throw new HttpError(404, 'NOT_FOUND', 'Church not found');
    }

    const token = signAccessToken({
      userId: updatedUser.id,
      role: updatedUser.role,
      churchId: updatedUser.churchId
    });

    return res.json({
      token,
      user: {
        id: updatedUser.id,
        firstName: updatedUser.firstName,
        lastName: updatedUser.lastName,
        churchId: updatedUser.churchId,
        role: updatedUser.role
      },
      church
    });
  } catch (err) {
    return next(err);
  }
}

async function search(req, res, next) {
  try {
    const { search, limit } = req.query;
    const result = await searchChurches({ search, limit: limit ?? 20 });
    return res.json(result);
  } catch (err) {
    return next(err);
  }
}

module.exports = {
  create,
  joinChurch,
  search
};
