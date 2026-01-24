const { prisma } = require('../db/prisma');
const { getBalance } = require('../services/pointsService');
const { signAccessToken } = require('../utils/jwt');
const bcrypt = require('bcryptjs');

class HttpError extends Error {
  constructor(status, code, message, details) {
    super(message);
    this.status = status;
    this.code = code;
    this.details = details;
  }
}

async function register(req, res, next) {
  try {
    const { firstName, lastName, age, city, email, username, password } = req.body;

    // Normalize email to keep it case-insensitive across register/login.
    const normalizedEmail = email != null ? (email ?? '').trim().toLowerCase() : null;
    const normalizedUsername = username != null ? (username ?? '').trim() : null;

    const passwordHash = await bcrypt.hash(password, 10);

    const user = await prisma.user.create({
      data: {
        firstName,
        lastName,
        age,
        city,
        email: normalizedEmail,
        username: normalizedUsername,
        passwordHash,
        role: 'USER',
        status: 'ACTIVE',
        churchId: null
      }
    });

    const token = signAccessToken({
      userId: user.id,
      role: user.role,
      churchId: user.churchId
    });

    // Не возвращаем passwordHash
    const { passwordHash: _ph, ...safeUser } = user;

    return res.status(201).json({ token, user: safeUser });
  } catch (err) {
    return next(err);
  }
}

async function login(req, res, next) {
  try {
    const { identifier, password } = req.body;

    const rawIdentifier = (identifier ?? '').trim();
    const normalizedEmail = rawIdentifier.toLowerCase();

    // Allow login by either email OR username.
    const user = await prisma.user.findFirst({
      where: {
        OR: [
          { email: normalizedEmail },
          { username: rawIdentifier }
        ]
      },
      select: {
        id: true,
        role: true,
        churchId: true,
        status: true,
        passwordHash: true,
        email: true,
        username: true
      }
    });

    if (user && user.status === 'BANNED') {
      throw new HttpError(403, 'FORBIDDEN', 'User is banned');
    }

    if (!user || !user.passwordHash) {
      throw new HttpError(401, 'INVALID_CREDENTIALS', 'Invalid credentials');
    }

    const ok = await bcrypt.compare(password, user.passwordHash);
    if (!ok) {
      throw new HttpError(401, 'INVALID_CREDENTIALS', 'Invalid credentials');
    }

    const token = signAccessToken({
      userId: user.id,
      churchId: user.churchId,
      role: user.role
    });

    // Helpful for debugging role/token mismatches on client.
    return res.json({
      token,
      user: {
        id: user.id,
        email: user.email,
        username: user.username,
        role: user.role,
        churchId: user.churchId,
        status: user.status
      }
    });
  } catch (err) {
    return next(err);
  }
}

async function me(req, res, next) {
  try {
    // req.user установлен в authMiddleware
    const { id: userId } = req.user;

    const user = await prisma.user.findUnique({
      where: { id: userId },
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
    if (!user) {
      throw new HttpError(404, 'USER_NOT_FOUND', 'User not found');
    }

    const church = user.churchId
      ? await prisma.church.findUnique({ where: { id: user.churchId } })
      : null;

    // If user's church was soft-deleted, treat it as "no church" for the client.
    if (church && church.deletedAt != null) {
      user.churchId = null;
    }

    let balance = undefined;
    if (user.churchId) {
      try {
        balance = await getBalance(user.id, user.churchId);
      } catch (_) {
        balance = 0;
      }
    } else {
      balance = 0;
    }

    return res.json({ user, ...(church ? { church } : {}), ...(balance != null ? { balance } : {}) });
  } catch (err) {
    return next(err);
  }
}

module.exports = {
  register,
  login,
  me
};
