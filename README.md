# LiftGo

This repository contains the LiftGo platform projects (admin web app, backend API, and landing site).

## Projects

- **Admin portal (React/Vite)**: `lift-go-admin-portal/`  
  - App lives in `lift-go-admin-portal/apps/` (uses Bun)
  - Docs: `lift-go-admin-portal/README.md`

- **Backend service (FastAPI)**: `lift-go-backend-service/`  
  - Docs: `lift-go-backend-service/README.md`

- **Landing site (React/Vite)**: `lift-go-landing/`

## Quick start (local development)

### Backend API

Follow the backend README for full setup (DB, env, Prisma, Redis, worker). In short:

```bash
cd lift-go-backend-service
cd infra/scripts && make setup
cd infra/scripts && make dev
```

The API should be on `http://localhost:8000` (Swagger docs at `/docs`).

### Admin portal

```bash
cd lift-go-admin-portal/apps
bun install
bun run dev
```

The app runs on `http://localhost:3000` and expects the API at `http://localhost:8000` (see `lift-go-admin-portal/apps/.env`).

### Landing site

```bash
cd lift-go-landing
npm install
npm run dev
```

## Repo notes

- **Environment files**: `.env` files are ignored by git. Use the example/env templates inside each project folder.
- **Where to look for more**:
  - Admin portal deployment docs: `lift-go-admin-portal/infra/deploy/README.md`
  - Backend docs: `lift-go-backend-service/docs/`

