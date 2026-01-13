/*
  Warnings:

  - You are about to drop the column `xpCategory` on the `Task` table. All the data in the column will be lost.
  - You are about to drop the column `xpDifficulty` on the `Task` table. All the data in the column will be lost.

*/
-- AlterTable
ALTER TABLE "Task" DROP COLUMN "xpCategory",
DROP COLUMN "xpDifficulty";

-- DropEnum
DROP TYPE "XpDifficulty";
