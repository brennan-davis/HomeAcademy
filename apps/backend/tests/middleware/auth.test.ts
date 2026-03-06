import { Request, Response } from 'express'
import { requireAuth, requireRole } from '../../src/middleware/auth'
import { generateTestToken, createTestUser } from '../helpers/testUtils'

describe('requireAuth middleware', () => {
  let mockRequest: Partial<Request>
  let mockResponse: Partial<Response>
  let nextFunction: jest.Mock

  beforeEach(() => {
    mockRequest = {
      headers: {},
    }
    mockResponse = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn().mockReturnThis(),
    }
    nextFunction = jest.fn()
  })

  it('should call next() with valid token', async () => {
    const { user } = await createTestUser()
    const token = generateTestToken({
      id: user.id,
      email: user.email,
      role: user.role,
    })

    mockRequest.headers = {
      authorization: `Bearer ${token}`,
    }

    requireAuth(mockRequest as Request, mockResponse as Response, nextFunction)

    expect(nextFunction).toHaveBeenCalled()
    expect(mockRequest.user).toBeDefined()
    expect(mockRequest.user?.id).toBe(user.id)
  })

  it('should return 401 if no authorization header', () => {
    requireAuth(mockRequest as Request, mockResponse as Response, nextFunction)

    expect(mockResponse.status).toHaveBeenCalledWith(401)
    expect(mockResponse.json).toHaveBeenCalledWith({ error: 'No token provided' })
    expect(nextFunction).not.toHaveBeenCalled()
  })

  it('should return 401 if authorization header does not start with Bearer', () => {
    mockRequest.headers = {
      authorization: 'NotBearer token',
    }

    requireAuth(mockRequest as Request, mockResponse as Response, nextFunction)

    expect(mockResponse.status).toHaveBeenCalledWith(401)
    expect(mockResponse.json).toHaveBeenCalledWith({ error: 'No token provided' })
    expect(nextFunction).not.toHaveBeenCalled()
  })

  it('should return 401 with invalid token', () => {
    mockRequest.headers = {
      authorization: 'Bearer invalid-token',
    }

    requireAuth(mockRequest as Request, mockResponse as Response, nextFunction)

    expect(mockResponse.status).toHaveBeenCalledWith(401)
    expect(mockResponse.json).toHaveBeenCalledWith({ error: 'Invalid or expired token' })
    expect(nextFunction).not.toHaveBeenCalled()
  })
})

describe('requireRole middleware', () => {
  let mockRequest: Partial<Request>
  let mockResponse: Partial<Response>
  let nextFunction: jest.Mock

  beforeEach(() => {
    mockRequest = {}
    mockResponse = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn().mockReturnThis(),
    }
    nextFunction = jest.fn()
  })

  it('should call next() if user has required role', () => {
    mockRequest.user = {
      id: '123',
      email: 'test@example.com',
      role: 'ADMIN',
    }

    const middleware = requireRole('ADMIN', 'PARENT')
    middleware(mockRequest as Request, mockResponse as Response, nextFunction)

    expect(nextFunction).toHaveBeenCalled()
    expect(mockResponse.status).not.toHaveBeenCalled()
  })

  it('should return 403 if user does not have required role', () => {
    mockRequest.user = {
      id: '123',
      email: 'test@example.com',
      role: 'STUDENT',
    }

    const middleware = requireRole('ADMIN', 'PARENT')
    middleware(mockRequest as Request, mockResponse as Response, nextFunction)

    expect(mockResponse.status).toHaveBeenCalledWith(403)
    expect(mockResponse.json).toHaveBeenCalledWith({ error: 'Insufficient permissions' })
    expect(nextFunction).not.toHaveBeenCalled()
  })

  it('should return 401 if user is not authenticated', () => {
    mockRequest.user = undefined

    const middleware = requireRole('ADMIN')
    middleware(mockRequest as Request, mockResponse as Response, nextFunction)

    expect(mockResponse.status).toHaveBeenCalledWith(401)
    expect(mockResponse.json).toHaveBeenCalledWith({ error: 'Authentication required' })
    expect(nextFunction).not.toHaveBeenCalled()
  })

  it('should work with single role', () => {
    mockRequest.user = {
      id: '123',
      email: 'test@example.com',
      role: 'PARENT',
    }

    const middleware = requireRole('PARENT')
    middleware(mockRequest as Request, mockResponse as Response, nextFunction)

    expect(nextFunction).toHaveBeenCalled()
  })
})
