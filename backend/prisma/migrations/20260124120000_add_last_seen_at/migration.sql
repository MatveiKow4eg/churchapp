-- Add lastSeenAt field used for online presence approximation
ALTER TABLE "User" ADD COLUMN IF NOT EXISTS "lastSeenAt" TIMESTAMP(3);

-- Helpful index for online lookups per church
CREATE INDEX IF NOT EXISTS "User_lastSeenAt_idx" ON "User"("lastSeenAt");
