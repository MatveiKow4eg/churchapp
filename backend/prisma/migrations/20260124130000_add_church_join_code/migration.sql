-- Add joinCode to Church and enforce uniqueness

ALTER TABLE "Church"
ADD COLUMN     "joinCode" TEXT;

-- Backfill existing rows (deterministic-ish) to satisfy NOT NULL + unique
-- Uses random values; if collision occurs it is extremely unlikely.
UPDATE "Church"
SET "joinCode" = upper(substring(md5(random()::text) from 1 for 8))
WHERE "joinCode" IS NULL;

ALTER TABLE "Church"
ALTER COLUMN "joinCode" SET NOT NULL;

CREATE UNIQUE INDEX "Church_joinCode_key" ON "Church"("joinCode");
