import { Request, Response, NextFunction } from 'express'
import jwt from 'jsonwebtoken'

// TODO: Build this out as part of Step 1 (Auth)
// This is the middleware that protects all your routes
// It should:
//   1. Read the Authorization header
//   2. Verify the JWT against JWT_SECRET
//   3. Attach the decoded user payload to req.user
//   4. Call next() or return 401

interface JwtPayload {
  id: string
  email: string
  role: string
  familyId?: string
}

declare global {
  namespace Express {
    interface Request {
      user?: JwtPayload
    }
  }
}

export const requireAuth = (_req: Request, _res: Response, _next: NextFunction) => {
  // TODO: implement me
  throw new Error('requireAuth not implemented yet')
}

export const requireRole = (..._roles: string[]) => {
  return (_req: Request, _res: Response, _next: NextFunction) => {
    // TODO: implement me — check req.user.role against allowed roles
    throw new Error('requireRole not implemented yet')
  }
}
