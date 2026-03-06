import request from 'supertest'
import app from '../../src/server'
import { createTestUser, generateTestToken } from '../helpers/testUtils'
import { prisma } from '../../src/db/client'

describe('POST /api/auth/register', () => {
  it('should register a new user and return token', async () => {
    const response = await request(app)
      .post('/api/auth/register')
      .send({
        email: 'newuser@example.com',
        password: 'password123',
      })
      .expect(201)

    expect(response.body).toHaveProperty('user')
    expect(response.body).toHaveProperty('token')
    expect(response.body.user.email).toBe('newuser@example.com')
    expect(response.body.user.role).toBe('PARENT')
    expect(response.body.user).not.toHaveProperty('passwordHash')
  })

  it('should register user with specified role', async () => {
    const response = await request(app)
      .post('/api/auth/register')
      .send({
        email: 'student@example.com',
        password: 'password123',
        role: 'STUDENT',
      })
      .expect(201)

    expect(response.body.user.role).toBe('STUDENT')
  })

  it('should reject duplicate email', async () => {
    await createTestUser({ email: 'duplicate@example.com' })

    const response = await request(app)
      .post('/api/auth/register')
      .send({
        email: 'duplicate@example.com',
        password: 'password123',
      })
      .expect(409)

    expect(response.body.error).toBe('Email already registered')
  })

  it('should reject invalid email', async () => {
    const response = await request(app)
      .post('/api/auth/register')
      .send({
        email: 'not-an-email',
        password: 'password123',
      })
      .expect(400)

    expect(response.body).toHaveProperty('error')
  })

  it('should reject short password', async () => {
    const response = await request(app)
      .post('/api/auth/register')
      .send({
        email: 'test@example.com',
        password: 'short',
      })
      .expect(400)

    expect(response.body).toHaveProperty('error')
  })
})

describe('POST /api/auth/login', () => {
  it('should login with valid credentials', async () => {
    const { user, password } = await createTestUser({
      email: 'login@example.com',
    })

    const response = await request(app)
      .post('/api/auth/login')
      .send({
        email: 'login@example.com',
        password,
      })
      .expect(200)

    expect(response.body).toHaveProperty('user')
    expect(response.body).toHaveProperty('token')
    expect(response.body.user.id).toBe(user.id)
    expect(response.body.user).not.toHaveProperty('passwordHash')
  })

  it('should reject invalid email', async () => {
    const response = await request(app)
      .post('/api/auth/login')
      .send({
        email: 'nonexistent@example.com',
        password: 'password123',
      })
      .expect(401)

    expect(response.body.error).toBe('Invalid credentials')
  })

  it('should reject wrong password', async () => {
    await createTestUser({ email: 'test@example.com' })

    const response = await request(app)
      .post('/api/auth/login')
      .send({
        email: 'test@example.com',
        password: 'wrongpassword',
      })
      .expect(401)

    expect(response.body.error).toBe('Invalid credentials')
  })

  it('should reject invalid email format', async () => {
    const response = await request(app)
      .post('/api/auth/login')
      .send({
        email: 'not-an-email',
        password: 'password123',
      })
      .expect(400)

    expect(response.body).toHaveProperty('error')
  })
})

describe('GET /api/auth/me', () => {
  it('should return current user with valid token', async () => {
    const { user } = await createTestUser()
    const token = generateTestToken({
      id: user.id,
      email: user.email,
      role: user.role,
    })

    const response = await request(app)
      .get('/api/auth/me')
      .set('Authorization', `Bearer ${token}`)
      .expect(200)

    expect(response.body.id).toBe(user.id)
    expect(response.body.email).toBe(user.email)
    expect(response.body).toHaveProperty('familyMemberships')
  })

  it('should reject request without token', async () => {
    const response = await request(app)
      .get('/api/auth/me')
      .expect(401)

    expect(response.body.error).toBe('No token provided')
  })

  it('should reject invalid token', async () => {
    const response = await request(app)
      .get('/api/auth/me')
      .set('Authorization', 'Bearer invalid-token')
      .expect(401)

    expect(response.body.error).toBe('Invalid or expired token')
  })

  it('should reject malformed authorization header', async () => {
    const response = await request(app)
      .get('/api/auth/me')
      .set('Authorization', 'NotBearer token')
      .expect(401)

    expect(response.body.error).toBe('No token provided')
  })
})
