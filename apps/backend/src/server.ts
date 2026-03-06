import 'express-async-errors'
import express from 'express'
import cors from 'cors'
import dotenv from 'dotenv'
import { logger } from './utils/logger'

dotenv.config()

const app = express()
const PORT = process.env.PORT || 3001

// ── Middleware ────────────────────────────────────────────────
app.use(cors({ origin: process.env.FRONTEND_URL, credentials: true }))
app.use(express.json())

// ── Routes ────────────────────────────────────────────────────
import authRoutes from './routes/auth'

app.use('/api/auth', authRoutes)

// TODO: Mount additional routes as you build them:
//   2. /api/families      — create family, get my family
//   3. /api/students      — CRUD students within a family
//   4. /api/attendance    — log attendance, get records, totals
//   5. /api/subjects      — CRUD subjects per student
//   6. /api/lessons       — lesson plans + scheduled lessons
//   7. /api/grades        — record grades, calculate GPA
//   8. /api/compliance    — state requirements + compliance status
//   9. /api/reports       — generate PDF exports
//  10. /api/coop          — co-op classes and enrollments

// ── Health check ──────────────────────────────────────────────
app.get('/health', (_req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() })
})

// ── Global error handler ──────────────────────────────────────
app.use((err: Error, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  logger.error({ err }, 'Unhandled error')
  res.status(500).json({ error: 'Internal server error' })
})

// Only start server if not in test mode
if (process.env.NODE_ENV !== 'test') {
  app.listen(PORT, () => {
    logger.info(`🏫 HomeAcademy backend running on port ${PORT}`)
  })
}

export default app
