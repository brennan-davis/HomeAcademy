# 🏫 HomeAcademy

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
