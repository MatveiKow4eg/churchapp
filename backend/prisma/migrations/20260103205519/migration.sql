-- CreateTable
CREATE TABLE "HealthPing" (
    "id" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "HealthPing_pkey" PRIMARY KEY ("id")
);
