/*
  Warnings:

  - You are about to drop the column `avatarConfig` on the `User` table. All the data in the column will be lost.
  - You are about to drop the column `avatarUpdatedAt` on the `User` table. All the data in the column will be lost.

*/
-- AlterTable
ALTER TABLE "User" DROP COLUMN "avatarConfig",
DROP COLUMN "avatarUpdatedAt";
