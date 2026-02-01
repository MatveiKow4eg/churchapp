-- CreateTable
CREATE TABLE "ChurchMember" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "churchId" TEXT NOT NULL,
    "role" TEXT NOT NULL DEFAULT 'MEMBER',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ChurchMember_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "ChurchMember_churchId_idx" ON "ChurchMember"("churchId");

-- CreateIndex
CREATE INDEX "ChurchMember_userId_idx" ON "ChurchMember"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "ChurchMember_userId_churchId_key" ON "ChurchMember"("userId", "churchId");

-- AddForeignKey
ALTER TABLE "ChurchMember" ADD CONSTRAINT "ChurchMember_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ChurchMember" ADD CONSTRAINT "ChurchMember_churchId_fkey" FOREIGN KEY ("churchId") REFERENCES "Church"("id") ON DELETE CASCADE ON UPDATE CASCADE;
