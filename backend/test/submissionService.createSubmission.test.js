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
      passwordHash: 'x'
    },
    select: { id: true, churchId: true }
  });

  const task = await prisma.task.create({
    data: {
      churchId: church.id,
      title: 'Test Task',
      description: 'Test',
      category: 'OTHER',
      pointsReward: 10,
      isActive: true
    },
    select: { id: true, churchId: true }
  });

  return { church, user, task };
}

async function cleanupFixture({ churchId }) {
  // Cascade relations should remove tasks/submissions/users as needed,
  // but we explicitly delete in safe order to be robust.
  await prisma.submission.deleteMany({ where: { churchId } });
  await prisma.task.deleteMany({ where: { churchId } });
  await prisma.user.deleteMany({ where: { churchId } });
  await prisma.church.delete({ where: { id: churchId } });
}

test('A) existing PENDING -> 409 ALREADY_PENDING', async () => {
  const { church, user, task } = await createFixture();

  try {
    await prisma.submission.create({
      data: {
        churchId: church.id,
        userId: user.id,
        taskId: task.id,
        status: 'PENDING',
        commentUser: 'first'
      }
    });

    await assert.rejects(
      () => submissionService.createSubmission({ userId: user.id, taskId: task.id, commentUser: 'second' }),
      (err) => {
        assert.equal(err.status, 409);
        assert.equal(err.code, 'ALREADY_PENDING');
        return true;
      }
    );
  } finally {
    await cleanupFixture({ churchId: church.id });
  }
});

test('B) existing APPROVED -> 409 ALREADY_APPROVED', async () => {
  const { church, user, task } = await createFixture();

  try {
    await prisma.submission.create({
      data: {
        churchId: church.id,
        userId: user.id,
        taskId: task.id,
        status: 'APPROVED',
        commentUser: 'first',
        decidedAt: new Date(),
        decidedById: 'admin_test',
        rewardPointsApplied: 10
      }
    });

    await assert.rejects(
      () => submissionService.createSubmission({ userId: user.id, taskId: task.id, commentUser: 'second' }),
      (err) => {
        assert.equal(err.status, 409);
        assert.equal(err.code, 'ALREADY_APPROVED');
        return true;
      }
    );
  } finally {
    await cleanupFixture({ churchId: church.id });
  }
});

test('C) existing REJECTED -> 201-equivalent: create new PENDING and history preserved', async () => {
  const { church, user, task } = await createFixture();

  try {
    await prisma.submission.create({
      data: {
        churchId: church.id,
        userId: user.id,
        taskId: task.id,
        status: 'REJECTED',
        commentUser: 'first',
        decidedAt: new Date(),
        decidedById: 'admin_test',
        commentAdmin: 'nope',
        rewardPointsApplied: 0
      }
    });

    const beforeCount = await prisma.submission.count({ where: { userId: user.id, taskId: task.id } });

    const created = await submissionService.createSubmission({
      userId: user.id,
      taskId: task.id,
      commentUser: 'second'
    });

    assert.ok(created);
    assert.equal(created.status, 'PENDING');
    assert.equal(created.userId, user.id);
    assert.equal(created.taskId, task.id);

    const afterCount = await prisma.submission.count({ where: { userId: user.id, taskId: task.id } });
    assert.equal(afterCount, beforeCount + 1);
  } finally {
    await cleanupFixture({ churchId: church.id });
  }
});
