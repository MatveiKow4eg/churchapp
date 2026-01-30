-- Migration: add_quiz_models
-- This migration adds the 'QUIZ' value to TaskCategory enum and creates quiz-related tables.

-- 1) Add 'QUIZ' value to TaskCategory enum if not present
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_type t
    JOIN pg_enum e ON t.oid = e.enumtypid
    WHERE t.typname = 'TaskCategory' AND e.enumlabel = 'QUIZ'
  ) THEN
    ALTER TYPE "TaskCategory" ADD VALUE 'QUIZ';
  END IF;
END$$;

-- 2) Quiz table (1:1 with Task)
CREATE TABLE IF NOT EXISTS "Quiz" (
  "id" TEXT PRIMARY KEY,
  "shuffleQuestions" BOOLEAN NOT NULL DEFAULT FALSE,
  "maxAttempts" INTEGER,
  "passScore" INTEGER NOT NULL DEFAULT 70,
  CONSTRAINT "Quiz_task_fkey" FOREIGN KEY ("id") REFERENCES "Task" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- 3) QuizQuestion table
CREATE TABLE IF NOT EXISTS "QuizQuestion" (
  "id" TEXT PRIMARY KEY,
  "quizId" TEXT NOT NULL,
  "order" INTEGER NOT NULL,
  "text" TEXT NOT NULL,
  "multiSelect" BOOLEAN NOT NULL DEFAULT FALSE,
  CONSTRAINT "QuizQuestion_quiz_fkey" FOREIGN KEY ("quizId") REFERENCES "Quiz" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX IF NOT EXISTS "QuizQuestion_quizId_order_idx" ON "QuizQuestion" ("quizId", "order");

-- 4) QuizOption table
CREATE TABLE IF NOT EXISTS "QuizOption" (
  "id" TEXT PRIMARY KEY,
  "questionId" TEXT NOT NULL,
  "order" INTEGER NOT NULL,
  "text" TEXT NOT NULL,
  "isCorrect" BOOLEAN NOT NULL,
  CONSTRAINT "QuizOption_question_fkey" FOREIGN KEY ("questionId") REFERENCES "QuizQuestion" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX IF NOT EXISTS "QuizOption_questionId_order_idx" ON "QuizOption" ("questionId", "order");

-- 5) QuizAttempt table
CREATE TABLE IF NOT EXISTS "QuizAttempt" (
  "id" TEXT PRIMARY KEY,
  "taskId" TEXT NOT NULL,
  "userId" TEXT NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "scorePercent" INTEGER NOT NULL,
  "isPassed" BOOLEAN NOT NULL,
  CONSTRAINT "QuizAttempt_task_fkey" FOREIGN KEY ("taskId") REFERENCES "Task" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "QuizAttempt_user_fkey" FOREIGN KEY ("userId") REFERENCES "User" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX IF NOT EXISTS "QuizAttempt_task_user_created_idx" ON "QuizAttempt" ("taskId", "userId", "createdAt");

-- 6) QuizAnswer table
CREATE TABLE IF NOT EXISTS "QuizAnswer" (
  "id" TEXT PRIMARY KEY,
  "attemptId" TEXT NOT NULL,
  "questionId" TEXT NOT NULL,
  "selectedOptionIds" JSONB NOT NULL,
  CONSTRAINT "QuizAnswer_attempt_fkey" FOREIGN KEY ("attemptId") REFERENCES "QuizAttempt" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT "QuizAnswer_question_fkey" FOREIGN KEY ("questionId") REFERENCES "QuizQuestion" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX IF NOT EXISTS "QuizAnswer_attempt_idx" ON "QuizAnswer" ("attemptId");
CREATE INDEX IF NOT EXISTS "QuizAnswer_question_idx" ON "QuizAnswer" ("questionId");
