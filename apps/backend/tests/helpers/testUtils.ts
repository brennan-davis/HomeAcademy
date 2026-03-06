import jwt from 'jsonwebtoken'
import bcrypt from 'bcryptjs'
import { prisma } from '../../src/db/client'

export async function createTestUser(data?: {
  email?: string
  password?: string
  role?: 'ADMIN' | 'PARENT' | 'STUDENT'
}) {
  const email = data?.email || `test-${Date.now()}@example.com`
  const password = data?.password || 'password123'
  const role = data?.role || 'PARENT'

  const passwordHash = await bcrypt.hash(password, 10)

  const user = await prisma.user.create({
    data: {
      email,
      passwordHash,
      role,
    },
  })

  return { user, password }
}

export function generateTestToken(payload: {
  id: string
  email: string
  role: string
}) {
  const secret = process.env.JWT_SECRET || 'test-secret'
  return jwt.sign(payload, secret, { expiresIn: '7d' })
}

export async function createTestFamily(userId: string, data?: { name?: string; state?: string }) {
  return await prisma.family.create({
    data: {
      name: data?.name || 'Test Family',
      state: data?.state || 'TN',
      schoolYearStart: new Date('2024-08-01'),
      schoolYearEnd: new Date('2025-05-31'),
      members: {
        create: {
          userId,
          role: 'PARENT',
        },
      },
    },
    include: {
      members: true,
    },
  })
}

export async function createTestStudent(familyId: string, data?: {
  firstName?: string
  lastName?: string
  gradeLevel?: string
}) {
  return await prisma.student.create({
    data: {
      familyId,
      firstName: data?.firstName || 'Test',
      lastName: data?.lastName || 'Student',
      gradeLevel: data?.gradeLevel || '5',
    },
  })
}
