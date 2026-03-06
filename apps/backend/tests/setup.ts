import { prisma } from '../src/db/client'

// Clean up database before each test
beforeEach(async () => {
  // Delete in order to respect foreign key constraints
  await prisma.grade.deleteMany()
  await prisma.attendanceRecord.deleteMany()
  await prisma.scheduledLesson.deleteMany()
  await prisma.lessonPlan.deleteMany()
  await prisma.subject.deleteMany()
  await prisma.coopEnrollment.deleteMany()
  await prisma.coopClass.deleteMany()
  await prisma.student.deleteMany()
  await prisma.familyMember.deleteMany()
  await prisma.family.deleteMany()
  await prisma.user.deleteMany()
})

// Disconnect after all tests
afterAll(async () => {
  await prisma.$disconnect()
})
