-- Add QUIZ category/source to XP ledger enums
-- This enables tracking quiz XP separately in analytics and in the XP progress card.

-- 1) Extend XpCategory enum
ALTER TYPE "XpCategory" ADD VALUE IF NOT EXISTS 'QUIZ';

-- 2) Extend XpSource enum
ALTER TYPE "XpSource" ADD VALUE IF NOT EXISTS 'QUIZ';
