-- CreateEnum
CREATE TYPE "LedgerType" AS ENUM ('TASK_REWARD', 'PURCHASE', 'ADMIN_ADJUSTMENT');

-- CreateTable
CREATE TABLE "PointsLedger" (
    "id" TEXT NOT NULL,
    "churchId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "type" "LedgerType" NOT NULL,
    "amount" INTEGER NOT NULL,
    "meta" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "PointsLedger_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "PointsLedger_churchId_idx" ON "PointsLedger"("churchId");

-- CreateIndex
CREATE INDEX "PointsLedger_userId_idx" ON "PointsLedger"("userId");

-- CreateIndex
CREATE INDEX "PointsLedger_type_idx" ON "PointsLedger"("type");

-- CreateIndex
CREATE INDEX "PointsLedger_createdAt_idx" ON "PointsLedger"("createdAt");

-- AddForeignKey
ALTER TABLE "PointsLedger" ADD CONSTRAINT "PointsLedger_churchId_fkey" FOREIGN KEY ("churchId") REFERENCES "Church"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PointsLedger" ADD CONSTRAINT "PointsLedger_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
