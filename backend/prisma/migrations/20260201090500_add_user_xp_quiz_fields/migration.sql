-- Add dedicated quiz XP counters to User so /me/xp can expose quiz progress
-- the same way as other categories (spiritual/service/community/creativity/reflection).

ALTER TABLE "User" ADD COLUMN IF NOT EXISTS "xpQuiz" INTEGER NOT NULL DEFAULT 0;
ALTER TABLE "User" ADD COLUMN IF NOT EXISTS "lifetimeXpQuiz" INTEGER NOT NULL DEFAULT 0;
