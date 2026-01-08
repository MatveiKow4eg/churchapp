-- DropIndex
DROP INDEX "Submission_userId_taskId_key";

-- CreateIndex
CREATE INDEX "Submission_userId_taskId_createdAt_idx" ON "Submission"("userId", "taskId", "createdAt");
