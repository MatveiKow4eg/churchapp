-- Fix: Submission.taskId must be nullable for ON DELETE SET NULL to work.

ALTER TABLE "Submission"
  ALTER COLUMN "taskId" DROP NOT NULL;
