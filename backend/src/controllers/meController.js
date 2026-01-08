const inventoryService = require('../services/inventoryService');
const { prisma } = require('../db/prisma');
const { HttpError } = require('../services/submissionService');
const bcrypt = require('bcryptjs');

async function getInventory(req, res, next) {
  try {
    const userId = req.user?.id;
    const churchId = req.user?.churchId;

    if (!churchId) {
      throw new HttpError(409, 'NO_CHURCH', 'User has no church selected');
    }

    const items = await inventoryService.getUserInventory(userId);

    return res.status(200).json({
      items: items.map((it) => ({
        id: it.id,
        itemKey: it.itemKey,
        acquiredAt: it.acquiredAt,
        quantity: it.quantity
      })),
      total: items.length
    });
  } catch (err) {
    return next(err);
  }
}

async function updateAvatar(req, res, next) {
  try {
    const userId = req.user?.id;

    const user = await prisma.user.update({
      where: { id: userId },
      data: {
        avatarConfig: req.body.avatarConfig,
        avatarUpdatedAt: new Date()
      },
      select: {
        id: true,
        firstName: true,
        lastName: true,
        age: true,
        city: true,
        email: true,
        role: true,
        status: true,
        churchId: true,
        createdAt: true,
        updatedAt: true,
        avatarConfig: true,
        avatarUpdatedAt: true
      }
    });

    return res.status(200).json({ user });
  } catch (err) {
    // Prisma throws P2025 when record to update not found
    if (err && err.code === 'P2025') {
      return next(new HttpError(404, 'USER_NOT_FOUND', 'User not found'));
    }
    return next(err);
  }
}

async function updateProfile(req, res, next) {
  try {
    const userId = req.user?.id;
    const { firstName, lastName, city } = req.body;

    const user = await prisma.user.update({
      where: { id: userId },
      data: {
        firstName,
        lastName,
        ...(city !== undefined ? { city } : {})
      },
      select: {
        id: true,
        firstName: true,
        lastName: true,
        age: true,
        city: true,
        email: true,
        role: true,
        status: true,
        churchId: true,
        createdAt: true,
        updatedAt: true,
        avatarConfig: true,
        avatarUpdatedAt: true
      }
    });

    return res.status(200).json({ user });
  } catch (err) {
    if (err && err.code === 'P2025') {
      return next(new HttpError(404, 'USER_NOT_FOUND', 'User not found'));
    }
    return next(err);
  }
}

async function leaveChurch(req, res, next) {
  try {
    const userId = req.user?.id;

    const user = await prisma.user.update({
      where: { id: userId },
      data: {
        churchId: null
      },
      select: {
        id: true,
        churchId: true,
        role: true
      }
    });

    return res.status(200).json({ user });
  } catch (err) {
    if (err && err.code === 'P2025') {
      return next(new HttpError(404, 'USER_NOT_FOUND', 'User not found'));
    }
    return next(err);
  }
}

async function changePassword(req, res, next) {
  try {
    const userId = req.user?.id;
    const { currentPassword, newPassword } = req.body;

    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, passwordHash: true, status: true }
    });

    if (!user) {
      throw new HttpError(404, 'USER_NOT_FOUND', 'User not found');
    }

    if (user.status === 'BANNED') {
      throw new HttpError(403, 'FORBIDDEN', 'User is banned');
    }

    if (!user.passwordHash) {
      throw new HttpError(409, 'NO_PASSWORD', 'User has no password set');
    }

    const ok = await bcrypt.compare(currentPassword, user.passwordHash);
    if (!ok) {
      throw new HttpError(400, 'INVALID_PASSWORD', 'Current password is incorrect');
    }

    const passwordHash = await bcrypt.hash(newPassword, 10);

    await prisma.user.update({
      where: { id: userId },
      data: { passwordHash }
    });

    return res.status(200).json({ ok: true });
  } catch (err) {
    return next(err);
  }
}

async function changeEmail(req, res, next) {
  try {
    const userId = req.user?.id;
    const { newEmail } = req.body;

    // Check email uniqueness
    const existing = await prisma.user.findUnique({
      where: { email: newEmail },
      select: { id: true }
    });

    if (existing && existing.id !== userId) {
      throw new HttpError(409, 'EMAIL_TAKEN', 'Email already in use');
    }

    const user = await prisma.user.update({
      where: { id: userId },
      data: { email: newEmail },
      select: {
        id: true,
        email: true,
        firstName: true,
        lastName: true,
        role: true,
        churchId: true
      }
    });

    return res.status(200).json({ user });
  } catch (err) {
    if (err && err.code === 'P2025') {
      return next(new HttpError(404, 'USER_NOT_FOUND', 'User not found'));
    }
    return next(err);
  }
}

module.exports = {
  getInventory,
  updateAvatar,
  updateProfile,
  leaveChurch,
  changePassword,
  changeEmail
};
