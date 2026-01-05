/*
  Warnings:

  - A unique constraint covering the columns `[name]` on the table `Church` will be added. If there are existing duplicate values, this will fail.
  - Added the required column `name` to the `Church` table without a default value. This is not possible if the table is not empty.

*/
-- AlterTable
ALTER TABLE "Church" ADD COLUMN     "city" TEXT,
ADD COLUMN     "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN     "name" TEXT NOT NULL;

-- CreateIndex
CREATE UNIQUE INDEX "Church_name_key" ON "Church"("name");
