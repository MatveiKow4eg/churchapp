/*
  Warnings:

  - You are about to drop the `ShopItem` table. If the table is not empty, all the data it contains will be lost.

*/
-- DropForeignKey
ALTER TABLE "ShopItem" DROP CONSTRAINT "ShopItem_churchId_fkey";

-- AlterTable
ALTER TABLE "ShopCatalogItem" ALTER COLUMN "updatedAt" DROP DEFAULT;

-- AlterTable
ALTER TABLE "User" ADD COLUMN     "avatarConfig" JSONB,
ADD COLUMN     "avatarUpdatedAt" TIMESTAMP(3);

-- DropTable
DROP TABLE "ShopItem";

-- DropEnum
DROP TYPE "ShopItemType";
