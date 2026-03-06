# 🏫 HomeAcademy

Self-hostable homeschool management platform for families and co-ops.

## Quick Start

```bash
npm install
docker compose up postgres -d
npm run db:migrate
npm run db:seed
npm run dev
```

Backend: http://localhost:3001
Frontend: http://localhost:5173

## Stack

- **Frontend:** React 18, TypeScript, Vite, Tailwind CSS, React Query
- **Backend:** Node.js, Express, TypeScript, Prisma ORM
- **Database:** PostgreSQL 16
- **Deployment:** Docker Compose + Nginx

## Testing

```bash
npm test              # Run all tests
npm run test:watch    # Watch mode
npm run test:coverage # Coverage report
```

## Production

```bash
docker compose up --build -d
```
