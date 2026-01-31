-- This migration makes Submission.taskId nullable and changes FK behavior to preserve submissions
-- history (APPROVED/REJECTED) when a Task is deleted.

-- 1) Drop the existing foreign key (name may vary between environments)
DO $$
DECLARE
  fk_name text;
BEGIN
  SELECT tc.constraint_name INTO fk_name
  FROM information_schema.table_constraints tc
  JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
   AND tc.constraint_schema = kcu.constraint_schema
  WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_name = 'Submission'
    AND kcu.column_name = 'taskId'
  LIMIT 1;

  IF fk_name IS NOT NULL THEN
    EXECUTE format('ALTER TABLE "Submission" DROP CONSTRAINT %I', fk_name);
  END IF;
END $$;

-- 2) Make taskId nullable
ALTER TABLE "Submission" ALTER COLUMN "taskId" DROP NOT NULL;

-- 3) Re-create FK with ON DELETE SET NULL
ALTER TABLE "Submission"
  ADD CONSTRAINT "Submission_taskId_fkey"
  FOREIGN KEY ("taskId") REFERENCES "Task"("id")
  ON DELETE SET NULL ON UPDATE CASCADE;
