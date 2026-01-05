const { PrismaClient } = require('@prisma/client');

// Singleton Prisma Client for the whole app.
// Prevents creating multiple DB connections across services/routes.
const prisma = new PrismaClient();

module.exports = { prisma };
