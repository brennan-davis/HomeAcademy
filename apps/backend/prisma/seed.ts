import { PrismaClient, Prisma } from '@prisma/client'

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
      testingGrades: Prisma.JsonNull,
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
