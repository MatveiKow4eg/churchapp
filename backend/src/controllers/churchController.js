const { createChurch, searchChurches, rotateChurchJoinCode } = require('../services/churchService');
const { prisma } = require('../db/prisma');
const { assignUserToChurch } = require('../services/userService');
const { signAccessToken } = require('../utils/jwt');
const { normalizeJoinCode } = require('../utils/joinCode');

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

    // This controller is used by both /churches (admin-protected) and /admin/churches.
    // Return joinCode ONLY for admins.
    const isAdmin = req.user && (req.user.role === 'ADMIN' || req.user.role === 'SUPERADMIN');

    return res.status(201).json({
      church: {
        id: church.id,
        name: church.name,
        city: church.city,
        createdAt: church.createdAt,
        ...(isAdmin ? { joinCode: church.joinCode } : {})
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

    const codeInput = normalizeJoinCode(req.body?.code);

    const churchWithCode = await prisma.church.findUnique({
      where: { id: churchId },
      select: { id: true, name: true, joinCode: true }
    });

    if (!churchWithCode) {
      throw new HttpError(404, 'NOT_FOUND', 'Church not found');
    }

    if (codeInput !== normalizeJoinCode(churchWithCode.joinCode)) {
      throw new HttpError(403, 'INVALID_CHURCH_CODE', 'INVALID_CHURCH_CODE');
    }

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
      church: { id: churchWithCode.id, name: churchWithCode.name }
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

async function rotateJoinCode(req, res, next) {
  try {
    const churchId = req.params.id;
    const church = await rotateChurchJoinCode(churchId);

    return res.json({
      church: {
        id: church.id,
        name: church.name,
        city: church.city,
        joinCode: church.joinCode,
        createdAt: church.createdAt
      }
    });
  } catch (err) {
    return next(err);
  }
}

module.exports = {
  create,
  joinChurch,
  rotateJoinCode,
  search
};
