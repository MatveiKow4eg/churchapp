-- CreateEnum
CREATE TYPE "XpCategory" AS ENUM ('SPIRITUAL', 'SERVICE', 'COMMUNITY', 'CREATIVITY', 'REFLECTION', 'OTHER');

-- CreateEnum
CREATE TYPE "XpDifficulty" AS ENUM ('S', 'M', 'L', 'XL');

-- AlterTable
ALTER TABLE "Task" ADD COLUMN     "xpCategory" "XpCategory" NOT NULL DEFAULT 'OTHER',
ADD COLUMN     "xpDifficulty" "XpDifficulty" NOT NULL DEFAULT 'M';
