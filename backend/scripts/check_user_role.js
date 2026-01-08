const { prisma } = require('../src/db/prisma');

async function main() {
  const userId = process.argv[2];
  if (!userId) {
    console.error('Usage: node scripts/check_user_role.js <userId>');
    process.exit(1);
  }

  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: {
      id: true,
      email: true,
      role: true,
      status: true,
      churchId: true,
      createdAt: true,
      updatedAt: true
    }
  });

  console.log(user);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
