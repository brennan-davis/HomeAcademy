#!/bin/bash

# ============================================================
#  HomeSchool Hub — Project Scaffolder
#  Run this from the root of your project folder:
#  chmod +x scaffold.sh && ./scaffold.sh
# ============================================================

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}✔ $1${NC}"; }
info() { echo -e "${BLUE}→ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠ $1${NC}"; }

echo ""
echo "============================================"
echo "   HomeSchool Hub — Scaffolding Project     "
echo "============================================"
echo ""

# ── Prerequisites check ──────────────────────────────────────
info "Checking prerequisites..."
command -v node >/dev/null 2>&1 || { echo "Node.js is required. Install from https://nodejs.org"; exit 1; }
command -v docker >/dev/null 2>&1 || { warn "Docker not found — you'll need it for deployment later."; }
log "Prerequisites OK (Node $(node -v))"

# ── Directory structure ───────────────────────────────────────
info "Creating directory structure..."

mkdir -p apps/backend/src/{routes,services,middleware,db,utils}
mkdir -p apps/backend/prisma/migrations
mkdir -p apps/frontend/src/{pages,components/{ui,layout,forms},hooks,lib,types}
mkdir -p apps/frontend/public
mkdir -p packages/shared/src
mkdir -p nginx
mkdir -p scripts

log "Directories created"

# ── Root package.json ─────────────────────────────────────────
info "Writing root package.json..."
cat > package.json << 'EOF'
{
  "name": "homeschool-hub",
  "version": "0.1.0",
  "private": true,
  "workspaces": [
    "apps/backend",
    "apps/frontend",
    "packages/shared"
  ],
  "scripts": {
    "dev": "concurrently -n backend,frontend -c blue,green \"npm run dev --workspace=apps/backend\" \"npm run dev --workspace=apps/frontend\"",
    "build": "npm run build --workspace=packages/shared && npm run build --workspace=apps/backend && npm run build --workspace=apps/frontend",
    "db:migrate": "npm run db:migrate --workspace=apps/backend",
    "db:studio": "npm run db:studio --workspace=apps/backend",
    "db:seed": "npm run db:seed --workspace=apps/backend"
  },
  "devDependencies": {
    "concurrently": "^8.2.2"
  }
}
EOF
log "Root package.json written"

# ── Backend package.json ──────────────────────────────────────
info "Writing backend package.json..."
cat > apps/backend/package.json << 'EOF'
{
  "name": "@hsh/backend",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "ts-node-dev --respawn --transpile-only --exit-child src/server.ts",
    "build": "tsc",
    "start": "node dist/server.js",
    "db:migrate": "prisma migrate dev",
    "db:generate": "prisma generate",
    "db:studio": "prisma studio",
    "db:seed": "ts-node prisma/seed.ts",
    "db:reset": "prisma migrate reset --force"
  },
  "dependencies": {
    "@hsh/shared": "*",
    "@prisma/client": "^5.10.0",
    "bcryptjs": "^2.4.3",
    "cors": "^2.8.5",
    "dotenv": "^16.4.4",
    "express": "^4.18.2",
    "express-async-errors": "^3.1.1",
    "jsonwebtoken": "^9.0.2",
    "pino": "^8.18.0",
    "pino-pretty": "^11.0.0",
    "uuid": "^9.0.1",
    "zod": "^3.22.4"
  },
  "devDependencies": {
    "@types/bcryptjs": "^2.4.6",
    "@types/cors": "^2.8.17",
    "@types/express": "^4.17.21",
    "@types/jsonwebtoken": "^9.0.5",
    "@types/node": "^20.11.19",
    "@types/uuid": "^9.0.7",
    "prisma": "^5.10.0",
    "ts-node-dev": "^2.0.0",
    "typescript": "^5.3.3"
  }
}
EOF
log "Backend package.json written"

# ── Backend tsconfig ──────────────────────────────────────────
cat > apps/backend/tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "lib": ["ES2020"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "sourceMap": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
EOF
log "Backend tsconfig.json written"

# ── Backend .env.example ──────────────────────────────────────
cat > apps/backend/.env.example << 'EOF'
# Copy this to .env and fill in your values
DATABASE_URL=postgresql://hsh_user:hsh_password@localhost:5432/hsh_db
JWT_SECRET=change_this_to_a_long_random_string_minimum_32_chars
PORT=3001
NODE_ENV=development
FRONTEND_URL=http://localhost:5173
EOF

cp apps/backend/.env.example apps/backend/.env
log "Backend .env created (update JWT_SECRET before running)"

# ── Prisma schema ─────────────────────────────────────────────
info "Writing Prisma schema..."
cat > apps/backend/prisma/schema.prisma << 'EOF'
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

// ── Auth & Tenancy ────────────────────────────────────────────

model User {
  id           String   @id @default(uuid())
  email        String   @unique
  passwordHash String
  role         UserRole @default(PARENT)
  createdAt    DateTime @default(now())
  updatedAt    DateTime @updatedAt

  familyMemberships FamilyMember[]
  taughtCoopClasses CoopClass[]    @relation("CoopInstructor")
}

enum UserRole {
  ADMIN    // instance admin (co-op host)
  PARENT   // family parent
  STUDENT  // child with limited read-only access
}

model Family {
  id               String   @id @default(uuid())
  name             String
  state            String   // US state code e.g. "TN", "PA", "NY"
  schoolYearStart  DateTime
  schoolYearEnd    DateTime
  createdAt        DateTime @default(now())
  updatedAt        DateTime @updatedAt

  members   FamilyMember[]
  students  Student[]
  coopEnrollments CoopEnrollment[]
}

model FamilyMember {
  id       String           @id @default(uuid())
  userId   String
  familyId String
  role     FamilyMemberRole @default(PARENT)

  user   User   @relation(fields: [userId], references: [id], onDelete: Cascade)
  family Family @relation(fields: [familyId], references: [id], onDelete: Cascade)

  @@unique([userId, familyId])
}

enum FamilyMemberRole {
  PARENT
  STUDENT
}

// ── Students ──────────────────────────────────────────────────

model Student {
  id          String    @id @default(uuid())
  familyId    String
  userId      String?   // optional — links to a User account for student login
  firstName   String
  lastName    String
  gradeLevel  String    // "K", "1", "2" ... "12"
  dateOfBirth DateTime?
  createdAt   DateTime  @default(now())
  updatedAt   DateTime  @updatedAt

  family             Family             @relation(fields: [familyId], references: [id], onDelete: Cascade)
  subjects           Subject[]
  attendanceRecords  AttendanceRecord[]
  grades             Grade[]
  coopEnrollments    CoopEnrollment[]
  scheduledLessons   ScheduledLesson[]
}

// ── Curriculum & Lessons ──────────────────────────────────────

model Subject {
  id             String  @id @default(uuid())
  studentId      String
  name           String  // "Math", "Language Arts", etc.
  color          String  @default("#6366f1") // for calendar display
  curriculumName String? // e.g. "Saxon Math 5/4"
  isActive       Boolean @default(true)
  createdAt      DateTime @default(now())

  student      Student       @relation(fields: [studentId], references: [id], onDelete: Cascade)
  lessonPlans  LessonPlan[]
}

model LessonPlan {
  id               String  @id @default(uuid())
  subjectId        String
  title            String
  description      String?
  materials        String? // free text or JSON list
  estimatedMinutes Int     @default(60)
  createdAt        DateTime @default(now())

  subject          Subject           @relation(fields: [subjectId], references: [id], onDelete: Cascade)
  scheduledLessons ScheduledLesson[]
}

model ScheduledLesson {
  id            String        @id @default(uuid())
  lessonPlanId  String?       // null = ad-hoc lesson
  studentId     String
  title         String        // copied from lesson plan or entered directly
  scheduledDate DateTime
  status        LessonStatus  @default(SCHEDULED)
  completedAt   DateTime?
  notes         String?
  isCoopLesson  Boolean       @default(false)
  createdAt     DateTime      @default(now())
  updatedAt     DateTime      @updatedAt

  lessonPlan LessonPlan? @relation(fields: [lessonPlanId], references: [id])
  student    Student     @relation(fields: [studentId], references: [id], onDelete: Cascade)
  grades     Grade[]
}

enum LessonStatus {
  SCHEDULED
  COMPLETED
  SKIPPED
  RESCHEDULED
}

// ── Attendance ────────────────────────────────────────────────

model AttendanceRecord {
  id        String           @id @default(uuid())
  studentId String
  date      DateTime         @db.Date
  status    AttendanceStatus
  hours     Float?           // for hour-based tracking
  notes     String?          // field trip, illness, co-op day, etc.
  createdAt DateTime         @default(now())
  updatedAt DateTime         @updatedAt

  student Student @relation(fields: [studentId], references: [id], onDelete: Cascade)

  @@unique([studentId, date])
}

enum AttendanceStatus {
  PRESENT
  ABSENT
  HALF_DAY
  FIELD_TRIP
  COOP_DAY
}

// ── Gradebook ─────────────────────────────────────────────────

model Grade {
  id                String  @id @default(uuid())
  studentId         String
  scheduledLessonId String?
  assignmentTitle   String
  score             Float
  maxScore          Float   @default(100)
  weight            Float   @default(1.0)
  notes             String?
  gradedAt          DateTime @default(now())

  student         Student          @relation(fields: [studentId], references: [id], onDelete: Cascade)
  scheduledLesson ScheduledLesson? @relation(fields: [scheduledLessonId], references: [id])
}

// ── Co-op ─────────────────────────────────────────────────────

model CoopClass {
  id           String  @id @default(uuid())
  name         String
  description  String?
  instructorId String
  schedule     String? // e.g. "Tuesdays 10am"
  isActive     Boolean @default(true)
  createdAt    DateTime @default(now())

  instructor  User             @relation("CoopInstructor", fields: [instructorId], references: [id])
  enrollments CoopEnrollment[]
}

model CoopEnrollment {
  id          String @id @default(uuid())
  coopClassId String
  studentId   String
  familyId    String
  enrolledAt  DateTime @default(now())

  coopClass CoopClass @relation(fields: [coopClassId], references: [id], onDelete: Cascade)
  student   Student   @relation(fields: [studentId], references: [id], onDelete: Cascade)
  family    Family    @relation(fields: [familyId], references: [id], onDelete: Cascade)

  @@unique([coopClassId, studentId])
}

// ── State Requirements (seeded data) ─────────────────────────

model StateRequirement {
  id                      String   @id @default(uuid())
  stateCode               String   @unique // "TN", "PA", "NY" etc.
  stateName               String
  requiredDays            Int?     // null = no requirement
  requiredHours           Int?     // null = no requirement
  requiresNotification    Boolean  @default(false)
  requiresPortfolio       Boolean  @default(false)
  requiresQuarterlyReport Boolean  @default(false)
  requiredSubjects        Json?    // ["Math", "Language Arts", "Science", ...]
  testingGrades           Json?    // [3, 5, 8] grade levels requiring tests
  notes                   String?  // plain english summary
}
EOF
log "Prisma schema written"

# ── Prisma seed placeholder ───────────────────────────────────
cat > apps/backend/prisma/seed.ts << 'EOF'
import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

async function main() {
  console.log('Seeding state requirements...')

  // TODO: You'll build this out — add all 50 states
  // This is a great TypeScript exercise: typed seed data
  // Reference: https://hslda.org/legal for state-by-state requirements

  const states = [
    {
      stateCode: 'TN',
      stateName: 'Tennessee',
      requiredDays: 180,
      requiredHours: null,
      requiresNotification: false,
      requiresPortfolio: false,
      requiresQuarterlyReport: false,
      requiredSubjects: ['Math', 'Language Arts', 'Social Studies', 'Science'],
      testingGrades: null,
      notes: 'Tennessee has low regulation. No notice required. Must teach for 180 days.',
    },
    {
      stateCode: 'PA',
      stateName: 'Pennsylvania',
      requiredDays: 180,
      requiredHours: 900,
      requiresNotification: true,
      requiresPortfolio: true,
      requiresQuarterlyReport: false,
      requiredSubjects: ['Math', 'Language Arts', 'Science', 'Social Studies', 'Art', 'Music', 'PE', 'Health'],
      testingGrades: [3, 5, 8],
      notes: 'High regulation state. Annual affidavit, portfolio review by evaluator, standardized testing in grades 3, 5, 8.',
    },
    {
      stateCode: 'NY',
      stateName: 'New York',
      requiredDays: 180,
      requiredHours: null,
      requiresNotification: true,
      requiresPortfolio: false,
      requiresQuarterlyReport: true,
      requiredSubjects: ['Math', 'Language Arts', 'Science', 'Social Studies', 'Art', 'Music', 'PE', 'Health', 'Library Skills'],
      testingGrades: [4, 5, 6, 7, 8],
      notes: 'Requires annual IHIP (Individualized Home Instruction Plan) and quarterly reports.',
    },
    // Add remaining states here — great first coding task!
  ]

  for (const state of states) {
    await prisma.stateRequirement.upsert({
      where: { stateCode: state.stateCode },
      update: state,
      create: state,
    })
    console.log(`  ✔ ${state.stateName}`)
  }

  console.log('Seed complete.')
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect())
EOF
log "Prisma seed file written"

# ── Backend server entry point ────────────────────────────────
info "Writing backend server scaffold..."
cat > apps/backend/src/server.ts << 'EOF'
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
// TODO: Import and mount your routes here as you build them
// Example:
//   import authRoutes from './routes/auth'
//   app.use('/api/auth', authRoutes)
//
// Build order recommendation:
//   1. /api/auth          — register, login, me
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

app.listen(PORT, () => {
  logger.info(`🏫 HomeSchool Hub backend running on port ${PORT}`)
})

export default app
EOF
log "Backend server.ts written"

# ── Prisma client singleton ───────────────────────────────────
cat > apps/backend/src/db/client.ts << 'EOF'
import { PrismaClient } from '@prisma/client'

// Prevent multiple instances during development hot-reload
const globalForPrisma = globalThis as unknown as { prisma: PrismaClient }

export const prisma =
  globalForPrisma.prisma ||
  new PrismaClient({
    log: process.env.NODE_ENV === 'development' ? ['query', 'error', 'warn'] : ['error'],
  })

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma
EOF
log "Prisma client written"

# ── Logger utility ────────────────────────────────────────────
cat > apps/backend/src/utils/logger.ts << 'EOF'
import pino from 'pino'

export const logger = pino({
  transport:
    process.env.NODE_ENV !== 'production'
      ? { target: 'pino-pretty', options: { colorize: true } }
      : undefined,
  level: process.env.LOG_LEVEL || 'info',
})
EOF
log "Logger utility written"

# ── Auth middleware stub ──────────────────────────────────────
cat > apps/backend/src/middleware/auth.ts << 'EOF'
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
EOF
log "Auth middleware stub written"

# ── Route stubs ───────────────────────────────────────────────
info "Writing route stubs..."

ROUTES=("auth" "families" "students" "attendance" "subjects" "lessons" "grades" "compliance" "reports" "coop")

for route in "${ROUTES[@]}"; do
cat > apps/backend/src/routes/${route}.ts << ROUTEOF
import { Router } from 'express'
// import { requireAuth } from '../middleware/auth'

const router = Router()

// TODO: Build out the ${route} routes
// Refer to the build plan in server.ts for guidance

export default router
ROUTEOF
done

log "Route stubs written (${#ROUTES[@]} files)"

# ── Frontend package.json ─────────────────────────────────────
info "Writing frontend package.json..."
cat > apps/frontend/package.json << 'EOF'
{
  "name": "@hsh/frontend",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "@hsh/shared": "*",
    "@tanstack/react-query": "^5.24.1",
    "axios": "^1.6.7",
    "date-fns": "^3.3.1",
    "lucide-react": "^0.330.0",
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.22.1"
  },
  "devDependencies": {
    "@types/react": "^18.2.55",
    "@types/react-dom": "^18.2.19",
    "@vitejs/plugin-react": "^4.2.1",
    "autoprefixer": "^10.4.17",
    "postcss": "^8.4.35",
    "tailwindcss": "^3.4.1",
    "typescript": "^5.3.3",
    "vite": "^5.1.3"
  }
}
EOF
log "Frontend package.json written"

# ── Frontend config files ─────────────────────────────────────
cat > apps/frontend/tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true
  },
  "include": ["src"]
}
EOF

cat > apps/frontend/vite.config.ts << 'EOF'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    proxy: {
      '/api': 'http://localhost:3001',
    },
  },
})
EOF

cat > apps/frontend/postcss.config.js << 'EOF'
export default {
  plugins: { tailwindcss: {}, autoprefixer: {} },
}
EOF

cat > apps/frontend/tailwind.config.js << 'EOF'
/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        // Brand colors — customize to your taste
        primary: {
          50:  '#f0f9ff',
          500: '#0ea5e9',
          600: '#0284c7',
          700: '#0369a1',
        },
      },
    },
  },
  plugins: [],
}
EOF

cat > apps/frontend/.env.example << 'EOF'
VITE_API_URL=http://localhost:3001
EOF

cp apps/frontend/.env.example apps/frontend/.env
log "Frontend config files written"

# ── Frontend index.html ───────────────────────────────────────
cat > apps/frontend/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>HomeSchool Hub</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
EOF
log "index.html written"

# ── Frontend entry files ──────────────────────────────────────
cat > apps/frontend/src/index.css << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;
EOF

cat > apps/frontend/src/main.tsx << 'EOF'
import React from 'react'
import ReactDOM from 'react-dom/client'
import { BrowserRouter } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import App from './App'
import './index.css'

const queryClient = new QueryClient({
  defaultOptions: {
    queries: { retry: 1, staleTime: 30_000 },
  },
})

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>
        <App />
      </BrowserRouter>
    </QueryClientProvider>
  </React.StrictMode>
)
EOF

# ── App.tsx stub ──────────────────────────────────────────────
cat > apps/frontend/src/App.tsx << 'EOF'
// TODO: Build out your routes here as you complete each step
// Suggested page build order mirrors the backend:
//   1. /login, /register       — Auth pages
//   2. /setup                  — First-run family + student setup wizard
//   3. /dashboard              — Home with compliance summary
//   4. /attendance             — Calendar attendance view
//   5. /lessons                — Lesson planner
//   6. /grades                 — Gradebook
//   7. /reports                — Export reports
//   8. /coop                   — Co-op management
//   9. /settings               — Family & student settings

export default function App() {
  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center">
      <div className="text-center">
        <h1 className="text-3xl font-bold text-primary-700 mb-2">🏫 HomeSchool Hub</h1>
        <p className="text-gray-500">Scaffolding complete. Time to build!</p>
      </div>
    </div>
  )
}
EOF
log "Frontend entry files written"

# ── Frontend API client stub ──────────────────────────────────
cat > apps/frontend/src/lib/api.ts << 'EOF'
import axios from 'axios'

// TODO: This is your central API client.
// All backend calls should go through here.
// Add request/response interceptors for:
//   - Attaching the JWT token to every request
//   - Redirecting to /login on 401 responses
//   - Global error handling/toast notifications

export const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL || 'http://localhost:3001',
})

// TODO: Add interceptors
// api.interceptors.request.use(...)
// api.interceptors.response.use(...)
EOF

# ── Frontend auth hook stub ───────────────────────────────────
cat > apps/frontend/src/hooks/useAuth.ts << 'EOF'
// TODO: Build this out as part of Step 1 (Auth)
// This hook should:
//   - Store the JWT token in localStorage
//   - Expose login(), logout(), and the current user
//   - Be used by ProtectedRoute to guard pages

export const useAuth = () => {
  // TODO: implement me
  return {
    token: null as string | null,
    user: null,
    login: (_token: string) => {},
    logout: () => {},
  }
}
EOF
log "Frontend lib and hooks stubs written"

# ── Shared types package ──────────────────────────────────────
info "Writing shared types package..."
cat > packages/shared/package.json << 'EOF'
{
  "name": "@hsh/shared",
  "version": "0.1.0",
  "main": "./src/index.ts",
  "types": "./src/index.ts",
  "devDependencies": {
    "typescript": "^5.3.3"
  }
}
EOF

cat > packages/shared/src/index.ts << 'EOF'
// ── Shared types used by both frontend and backend ────────────
// Keep these in sync with your Prisma schema.
// This is the contract between your API and your UI.

export type UserRole = 'ADMIN' | 'PARENT' | 'STUDENT'

export type LessonStatus = 'SCHEDULED' | 'COMPLETED' | 'SKIPPED' | 'RESCHEDULED'

export type AttendanceStatus = 'PRESENT' | 'ABSENT' | 'HALF_DAY' | 'FIELD_TRIP' | 'COOP_DAY'

export interface User {
  id: string
  email: string
  role: UserRole
}

export interface Family {
  id: string
  name: string
  state: string
  schoolYearStart: string
  schoolYearEnd: string
}

export interface Student {
  id: string
  familyId: string
  firstName: string
  lastName: string
  gradeLevel: string
  dateOfBirth?: string
}

export interface AttendanceRecord {
  id: string
  studentId: string
  date: string
  status: AttendanceStatus
  hours?: number
  notes?: string
}

export interface Subject {
  id: string
  studentId: string
  name: string
  color: string
  curriculumName?: string
  isActive: boolean
}

export interface LessonPlan {
  id: string
  subjectId: string
  title: string
  description?: string
  estimatedMinutes: number
}

export interface ScheduledLesson {
  id: string
  studentId: string
  title: string
  scheduledDate: string
  status: LessonStatus
  completedAt?: string
  notes?: string
}

export interface Grade {
  id: string
  studentId: string
  assignmentTitle: string
  score: number
  maxScore: number
  weight: number
  gradedAt: string
}

export interface StateRequirement {
  stateCode: string
  stateName: string
  requiredDays?: number
  requiredHours?: number
  requiresNotification: boolean
  requiresPortfolio: boolean
  requiresQuarterlyReport: boolean
  requiredSubjects?: string[]
  testingGrades?: number[]
  notes?: string
}

// ── API response shapes ───────────────────────────────────────

export interface ApiError {
  error: string
  details?: unknown
}

export interface ComplianceStatus {
  studentId: string
  daysCompleted: number
  daysRequired: number | null
  hoursCompleted: number
  hoursRequired: number | null
  onTrack: boolean
  subjectsCovered: string[]
  subjectsRequired: string[]
  portfolioDue: boolean
  quarterlyReportDue: boolean
}
EOF
log "Shared types written"

# ── Docker files ──────────────────────────────────────────────
info "Writing Docker configuration..."
cat > docker-compose.yml << 'EOF'
version: '3.9'

services:
  postgres:
    image: postgres:16-alpine
    restart: unless-stopped
    environment:
      POSTGRES_USER: hsh_user
      POSTGRES_PASSWORD: hsh_password
      POSTGRES_DB: hsh_db
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - '5432:5432'
    healthcheck:
      test: ['CMD-SHELL', 'pg_isready -U hsh_user -d hsh_db']
      interval: 5s
      timeout: 5s
      retries: 5

  backend:
    build:
      context: .
      dockerfile: apps/backend/Dockerfile
    restart: unless-stopped
    depends_on:
      postgres:
        condition: service_healthy
    env_file: apps/backend/.env
    environment:
      DATABASE_URL: postgresql://hsh_user:hsh_password@postgres:5432/hsh_db
      NODE_ENV: production
    ports:
      - '3001:3001'

  frontend:
    build:
      context: .
      dockerfile: apps/frontend/Dockerfile
    restart: unless-stopped
    depends_on:
      - backend
    ports:
      - '80:80'
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/conf.d/default.conf:ro

volumes:
  postgres_data:
EOF

cat > apps/backend/Dockerfile << 'EOF'
FROM node:20-alpine AS builder
WORKDIR /app
COPY package.json ./
COPY apps/backend/package.json ./apps/backend/
COPY packages/shared/package.json ./packages/shared/
RUN npm install --workspace=apps/backend --workspace=packages/shared
COPY apps/backend ./apps/backend
COPY packages/shared ./packages/shared
RUN npm run db:generate --workspace=apps/backend
RUN npm run build --workspace=apps/backend

FROM node:20-alpine AS runner
WORKDIR /app
COPY --from=builder /app/apps/backend/dist ./dist
COPY --from=builder /app/apps/backend/node_modules ./node_modules
COPY --from=builder /app/apps/backend/prisma ./prisma
COPY --from=builder /app/apps/backend/package.json ./
EXPOSE 3001
CMD ["sh", "-c", "npx prisma migrate deploy && node dist/server.js"]
EOF

cat > apps/frontend/Dockerfile << 'EOF'
FROM node:20-alpine AS builder
WORKDIR /app
COPY package.json ./
COPY apps/frontend/package.json ./apps/frontend/
COPY packages/shared/package.json ./packages/shared/
RUN npm install --workspace=apps/frontend --workspace=packages/shared
COPY apps/frontend ./apps/frontend
COPY packages/shared ./packages/shared
RUN npm run build --workspace=apps/frontend

FROM nginx:alpine AS runner
COPY --from=builder /app/apps/frontend/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF

cat > nginx/nginx.conf << 'EOF'
server {
    listen 80;
    server_name _;

    root /usr/share/nginx/html;
    index index.html;

    # React SPA — all unknown routes go to index.html
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Proxy API calls to backend
    location /api/ {
        proxy_pass         http://backend:3001;
        proxy_http_version 1.1;
        proxy_set_header   Host $host;
        proxy_set_header   X-Real-IP $remote_addr;
    }

    location /health {
        proxy_pass http://backend:3001;
    }
}
EOF
log "Docker configuration written"

# ── .gitignore ────────────────────────────────────────────────
cat > .gitignore << 'EOF'
node_modules/
dist/
.env
*.local
.DS_Store
*.log
prisma/migrations/dev*
EOF
log ".gitignore written"

# ── README ────────────────────────────────────────────────────
cat > README.md << 'EOF'
# 🏫 HomeSchool Hub

Self-hostable homeschool management platform for families and co-ops.

## Stack
- **Frontend:** React 18, TypeScript, Vite, Tailwind CSS, React Query
- **Backend:** Node.js, Express, TypeScript, Prisma ORM
- **Database:** PostgreSQL 16
- **Deployment:** Docker + Docker Compose + Nginx

## Getting Started (Local Dev)

### 1. Install dependencies
```bash
npm install
```

### 2. Start the database
```bash
docker compose up postgres -d
```

### 3. Run migrations + seed state data
```bash
npm run db:migrate
npm run db:seed
```

### 4. Start dev servers
```bash
npm run dev
# Backend → http://localhost:3001
# Frontend → http://localhost:5173
```

## Build Order
Work through these one step at a time:

| Step | Feature | Key concepts practiced |
|------|---------|----------------------|
| 1 | Auth (register, login, JWT) | bcrypt, JWT, middleware, protected routes |
| 2 | Family + Student setup | relational data, CRUD, React forms |
| 3 | Attendance tracking | date handling, calendar UI, aggregations |
| 4 | Subjects + Lesson planning | nested relations, scheduling logic |
| 5 | Compliance dashboard | data aggregation, state requirements |
| 6 | Gradebook + GPA | weighted calculations, React Query |
| 7 | PDF reports | server-side rendering, file download |
| 8 | Co-op mode | multi-tenancy, role permissions |

## Production Deploy
```bash
docker compose up --build -d
```
EOF
log "README written"

# ── Install dependencies ──────────────────────────────────────
echo ""
info "Installing dependencies (this may take a minute)..."
npm install
log "Dependencies installed"

# ── Final instructions ────────────────────────────────────────
echo ""
echo "============================================"
echo -e "   ${GREEN}Scaffolding complete!${NC}                   "
echo "============================================"
echo ""
echo -e "  ${BLUE}Next steps:${NC}"
echo ""
echo "  1. Start Postgres:"
echo "     docker compose up postgres -d"
echo ""
echo "  2. Run your first migration:"
echo "     npm run db:migrate"
echo "     (name it: 'init')"
echo ""
echo "  3. Seed state requirements:"
echo "     npm run db:seed"
echo ""
echo "  4. Start dev servers:"
echo "     npm run dev"
echo ""
echo "  5. Open Claude Code and start with Step 1:"
echo "     → apps/backend/src/routes/auth.ts"
echo "     → apps/backend/src/middleware/auth.ts"
echo ""
echo -e "  ${YELLOW}Build tip:${NC} Each route stub and TODO comment"
echo "  is a prompt for Claude Code. Ask it to help"
echo "  you implement one piece at a time so you"
echo "  understand what you're building."
echo ""
