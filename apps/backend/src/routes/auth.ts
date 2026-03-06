import { Router, Request, Response } from 'express'
import bcrypt from 'bcryptjs'
import jwt from 'jsonwebtoken'
import { z } from 'zod'
import { prisma } from '../db/client'
import { requireAuth } from '../middleware/auth'

const router = Router()

const registerSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8, 'Password must be at least 8 characters'),
  role: z.enum(['PARENT', 'STUDENT']).optional().default('PARENT'),
})

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string(),
})

function generateToken(payload: { id: string; email: string; role: string }) {
  const secret = process.env.JWT_SECRET
  if (!secret) {
    throw new Error('JWT_SECRET not configured')
  }
  return jwt.sign(payload, secret, { expiresIn: '7d' })
}

router.post('/register', async (req: Request, res: Response) => {
  const result = registerSchema.safeParse(req.body)
  if (!result.success) {
    return res.status(400).json({ error: result.error.errors })
  }

  const { email, password, role } = result.data

  const existingUser = await prisma.user.findUnique({
    where: { email },
  })
  if (existingUser) {
    return res.status(409).json({ error: 'Email already registered' })
  }

  const passwordHash = await bcrypt.hash(password, 10)

  const user = await prisma.user.create({
    data: {
      email,
      passwordHash,
      role,
    },
    select: {
      id: true,
      email: true,
      role: true,
      createdAt: true,
    },
  })

  const token = generateToken({
    id: user.id,
    email: user.email,
    role: user.role,
  })

  res.status(201).json({
    user,
    token,
  })
})

router.post('/login', async (req: Request, res: Response) => {
  const result = loginSchema.safeParse(req.body)
  if (!result.success) {
    return res.status(400).json({ error: result.error.errors })
  }

  const { email, password } = result.data

  const user = await prisma.user.findUnique({
    where: { email },
    select: {
      id: true,
      email: true,
      role: true,
      passwordHash: true,
      createdAt: true,
    },
  })

  if (!user) {
    return res.status(401).json({ error: 'Invalid credentials' })
  }

  const isPasswordValid = await bcrypt.compare(password, user.passwordHash)

  if (!isPasswordValid) {
    return res.status(401).json({ error: 'Invalid credentials' })
  }

  const token = generateToken({
    id: user.id,
    email: user.email,
    role: user.role,
  })

  const { passwordHash, ...userWithoutPassword } = user

  res.status(200).json({
    user: userWithoutPassword,
    token,
  })
})

router.get('/me', requireAuth, async (req: Request, res: Response) => {
  const user = await prisma.user.findUnique({
    where: { id: req.user!.id },
    select: {
      id: true,
      email: true,
      role: true,
      createdAt: true,
      updatedAt: true,
      familyMemberships: {
        include: {
          family: true,
        },
      },
    },
  })

  if (!user) {
    return res.status(404).json({ error: 'User not found' })
  }

  res.json(user)
})

export default router
