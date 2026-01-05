-- Step 14.5.2 (Variant A)
--
-- NOTE (MVP): We reset existing shop/inventory data because we cannot map old ShopItem.id (cuid)
-- to new itemKey without a mapping table.

-- 1) Create new ShopCatalogItem
CREATE TABLE IF NOT EXISTS "ShopCatalogItem" (
  "itemKey" TEXT NOT NULL,
  "churchId" TEXT NOT NULL,
  "isActive" BOOLEAN NOT NULL DEFAULT TRUE,
  "pricePoints" INTEGER NOT NULL,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Unique per church
CREATE UNIQUE INDEX IF NOT EXISTS "ShopCatalogItem_churchId_itemKey_key" ON "ShopCatalogItem"("churchId", "itemKey");
CREATE INDEX IF NOT EXISTS "ShopCatalogItem_churchId_idx" ON "ShopCatalogItem"("churchId");
CREATE INDEX IF NOT EXISTS "ShopCatalogItem_isActive_idx" ON "ShopCatalogItem"("isActive");

-- FK to Church
DO $$ BEGIN
  ALTER TABLE "ShopCatalogItem" ADD CONSTRAINT "ShopCatalogItem_churchId_fkey"
    FOREIGN KEY ("churchId") REFERENCES "Church"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- 2) Reset inventory and old shop items
-- Remove inventory first due to FK to ShopItem
DELETE FROM "Inventory";

-- Remove old shop items (admin CRUD removed)
DELETE FROM "ShopItem";

-- 3) Inventory refactor: replace itemId -> itemKey
ALTER TABLE "Inventory" ADD COLUMN IF NOT EXISTS "itemKey" TEXT;

-- For safety (after delete), no mapping needed.
ALTER TABLE "Inventory" ALTER COLUMN "itemKey" SET NOT NULL;

-- Drop old FK + column itemId
DO $$ BEGIN
  ALTER TABLE "Inventory" DROP CONSTRAINT "Inventory_itemId_fkey";
EXCEPTION WHEN undefined_object THEN NULL;
END $$;

ALTER TABLE "Inventory" DROP COLUMN IF EXISTS "itemId";

-- 4) Fix unique/indexes
DROP INDEX IF EXISTS "Inventory_userId_itemId_key";
DROP INDEX IF EXISTS "Inventory_itemId_idx";

CREATE UNIQUE INDEX IF NOT EXISTS "Inventory_userId_itemKey_key" ON "Inventory"("userId", "itemKey");
CREATE INDEX IF NOT EXISTS "Inventory_itemKey_idx" ON "Inventory"("itemKey");

-- 5) Update updatedAt trigger-like behavior (Prisma handles @updatedAt, but DB needs default)
-- Not adding triggers here; Prisma will set updatedAt on update.
