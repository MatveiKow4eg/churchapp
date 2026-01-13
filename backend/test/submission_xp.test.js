const test = require('node:test');
const assert = require('node:assert/strict');

const { prisma } = require('../src/db/prisma');
const submissionService = require('../src/services/submissionService');

async function createFixture() {
  const church = await prisma.church.create({
    data: {
      name: `Test Church ${Date.now()} ${Math.random()}`,
      city: 'Test City'
    },
    select: { id: true }
  });

  const user = await prisma.user.create({
    data: {
      firstName: 'Test',
      lastName: 'User',
      age: 15,
      city: 'Test City',
      role: 'USER',
      status: 'ACTIVE',
      churchId: church.id,
      email: `u_${Date.now()}_${Math.random()}@test.local`,
      passwordHash: 'x',
      // make sure streak starts from a known state
      streakDays: 0,
      lastTaskCompletedAt: null,
      // XP fields default to 0, but we keep them explicit for determinism
      level: 1,
      levelXp: 0,
      xpSpiritual: 0,
      xpService: 0,
      xpCommunity: 0,
      xpCreativity: 0,
      xpReflection: 0,
      xpOther: 0,
      lifetimeXp: 0,
      lifetimeXpSpiritual: 0,
      lifetimeXpService: 0,
      lifetimeXpCommunity: 0,
      lifetimeXpCreativity: 0,
      lifetimeXpReflection: 0,
      lifetimeXpOther: 0
    },
    select: { id: true, churchId: true }
  });

  const admin = await prisma.user.create({
    data: {
      firstName: 'Admin',
      lastName: 'User',
      age: 30,
      city: 'Test City',
      role: 'ADMIN',
      status: 'ACTIVE',
      churchId: church.id,
      email: `a_${Date.now()}_${Math.random()}@test.local`,
      passwordHash: 'x'
    },
    select: { id: true, churchId: true, role: true }
  });

  const task = await prisma.task.create({
    data: {
      churchId: church.id,
      title: 'Test Task',
      description: 'Test',
      // XP category is derived automatically from task.category
      category: 'SPIRITUAL',
      pointsReward: 10,
      isActive: true
    },
    select: { id: true, churchId: true }
  });

  const submission = await prisma.submission.create({
    data: {
      churchId: church.id,
      userId: user.id,
      taskId: task.id,
      status: 'PENDING',
      commentUser: 'please approve'
    },
    select: { id: true, userId: true, taskId: true, churchId: true, status: true }
  });

  return { church, user, admin, task, submission };
}

async function cleanupFixture({ churchId }) {
  // Delete in safe order; onDelete cascades exist but we keep explicit cleanup.
  await prisma.xpLedger.deleteMany({ where: { user: { churchId } } });
  await prisma.pointsLedger.deleteMany({ where: { churchId } });
  await prisma.submission.deleteMany({ where: { churchId } });
  await prisma.task.deleteMany({ where: { churchId } });
  await prisma.user.deleteMany({ where: { churchId } });
  await prisma.church.delete({ where: { id: churchId } });
}

test('XP 1) approve начисляет XP', async () => {
  const { church, user, admin, task, submission } = await createFixture();

  try {
    const beforeUser = await prisma.user.findUnique({ where: { id: user.id } });
    assert.equal(beforeUser.levelXp, 0);
    assert.equal(beforeUser.xpSpiritual, 0);

    await submissionService.approveSubmission({
      submissionId: submission.id,
      adminId: admin.id,
      adminChurchId: church.id,
      adminRole: admin.role,
      commentAdmin: 'ok'
    });

    const updatedSubmission = await prisma.submission.findUnique({ where: { id: submission.id } });
    assert.equal(updatedSubmission.status, 'APPROVED');
    assert.ok(updatedSubmission.xpAppliedAt);

    const updatedUser = await prisma.user.findUnique({ where: { id: user.id } });
    assert.ok(updatedUser.levelXp > 0);
    assert.ok(updatedUser.xpSpiritual > 0);

    const taskLedgers = await prisma.xpLedger.findMany({
      where: {
        userId: user.id,
        taskId: task.id,
        source: 'TASK',
        category: 'SPIRITUAL'
      }
    });
    assert.equal(taskLedgers.length, 1);
    assert.ok(taskLedgers[0].xpGranted > 0);
  } finally {
    await cleanupFixture({ churchId: church.id });
  }
});

test('XP 2) повторный approve не начисляет снова', async () => {
  const { church, user, admin, submission } = await createFixture();

  try {
    await submissionService.approveSubmission({
      submissionId: submission.id,
      adminId: admin.id,
      adminChurchId: church.id,
      adminRole: admin.role
    });

    const afterFirst = await prisma.user.findUnique({ where: { id: user.id } });
    const ledgerCountAfterFirst = await prisma.xpLedger.count({ where: { userId: user.id } });

    await assert.rejects(
      () =>
        submissionService.approveSubmission({
          submissionId: submission.id,
          adminId: admin.id,
          adminChurchId: church.id,
          adminRole: admin.role
        }),
      (err) => {
        assert.equal(err.status, 409);
        assert.equal(err.code, 'CONFLICT');
        return true;
      }
    );

    const afterSecond = await prisma.user.findUnique({ where: { id: user.id } });
    const ledgerCountAfterSecond = await prisma.xpLedger.count({ where: { userId: user.id } });

    assert.equal(ledgerCountAfterSecond, ledgerCountAfterFirst);
    assert.equal(afterSecond.levelXp, afterFirst.levelXp);
  } finally {
    await cleanupFixture({ churchId: church.id });
  }
});

test('XP 3) streak бонус на 7 день', async () => {
  const { church, user, admin, submission } = await createFixture();

  try {
    const now = new Date();
    const yesterday = new Date(now);
    yesterday.setDate(now.getDate() - 1);

    await prisma.user.update({
      where: { id: user.id },
      data: {
        streakDays: 6,
        lastTaskCompletedAt: yesterday
      }
    });

    await submissionService.approveSubmission({
      submissionId: submission.id,
      adminId: admin.id,
      adminChurchId: church.id,
      adminRole: admin.role
    });

    const updatedUser = await prisma.user.findUnique({ where: { id: user.id } });
    assert.equal(updatedUser.streakDays, 7);

    const streakLedgers = await prisma.xpLedger.findMany({
      where: {
        userId: user.id,
        source: 'STREAK',
        category: 'OTHER'
      },
      orderBy: { createdAt: 'desc' }
    });

    assert.ok(streakLedgers.length >= 1);
    // On day 7, base bonus should be 60 according to rules.
    assert.equal(streakLedgers[0].xpBase, 60);
  } finally {
    await cleanupFixture({ churchId: church.id });
  }
});

test('XP 4) soft-cap после 400 XP (M => base 15, awarded 3)', async () => {
  const { church, user, admin, task, submission } = await createFixture();

  try {
    const now = new Date();

    // Make sure user already has 400 XP today.
    await prisma.xpLedger.create({
      data: {
        userId: user.id,
        taskId: null,
        xpGranted: 400,
        xpBase: 400,
        category: 'OTHER',
        source: 'TASK',
        createdAt: now
      }
    });

    await submissionService.approveSubmission({
      submissionId: submission.id,
      adminId: admin.id,
      adminChurchId: church.id,
      adminRole: admin.role
    });

    const newestTaskLedger = await prisma.xpLedger.findFirst({
      where: {
        userId: user.id,
        taskId: task.id,
        source: 'TASK',
        category: 'SPIRITUAL'
      },
      orderBy: { createdAt: 'desc' }
    });

    assert.ok(newestTaskLedger);
    assert.equal(newestTaskLedger.xpGranted, 3);
  } finally {
    await cleanupFixture({ churchId: church.id });
  }
});
