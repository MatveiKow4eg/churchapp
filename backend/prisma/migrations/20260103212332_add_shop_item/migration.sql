-- CreateEnum
CREATE TYPE "ShopItemType" AS ENUM ('COSMETIC', 'UPGRADE', 'BADGE', 'OTHER');

-- CreateTable
CREATE TABLE "ShopItem" (
    "id" TEXT NOT NULL,
    "churchId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "type" "ShopItemType" NOT NULL DEFAULT 'OTHER',
    "pricePoints" INTEGER NOT NULL,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ShopItem_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "ShopItem_churchId_idx" ON "ShopItem"("churchId");

-- CreateIndex
CREATE INDEX "ShopItem_isActive_idx" ON "ShopItem"("isActive");

-- CreateIndex
CREATE INDEX "ShopItem_type_idx" ON "ShopItem"("type");

-- CreateIndex
CREATE UNIQUE INDEX "ShopItem_churchId_name_key" ON "ShopItem"("churchId", "name");

-- AddForeignKey
ALTER TABLE "ShopItem" ADD CONSTRAINT "ShopItem_churchId_fkey" FOREIGN KEY ("churchId") REFERENCES "Church"("id") ON DELETE CASCADE ON UPDATE CASCADE;
