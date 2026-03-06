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
