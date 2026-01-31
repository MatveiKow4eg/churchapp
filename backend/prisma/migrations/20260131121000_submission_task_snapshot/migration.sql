-- Add snapshot fields to Submission to preserve task text/category/points
-- even if Task is deleted later.

ALTER TABLE "Submission"
  ADD COLUMN IF NOT EXISTS "taskTitle" text,
  ADD COLUMN IF NOT EXISTS "taskCategory" "TaskCategory",
  ADD COLUMN IF NOT EXISTS "taskPointsReward" integer;

-- Backfill snapshot fields for existing rows (best-effort)
UPDATE "Submission" s
SET
  "taskTitle" = COALESCE(s."taskTitle", t."title"),
  "taskCategory" = COALESCE(s."taskCategory", t."category"),
  "taskPointsReward" = COALESCE(s."taskPointsReward", t."pointsReward")
FROM "Task" t
WHERE s."taskId" = t."id";
