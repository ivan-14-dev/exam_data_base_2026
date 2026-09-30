# ICTU Events in Next.js

This app uses the existing `ictu_events` MySQL/MariaDB database and stored procedure from `../database`.

## Requirements

- Node.js 20.9 or newer
- MySQL 8 or MariaDB 10.6 or newer, with the project database initialized

## Run locally

```bash
cp .env.example .env.local
```

Set `SESSION_SECRET` in `.env.local` to a random secret of at least 32 characters. Keep the database settings aligned with `database/07_app_user.sql`.

```bash
npm install
npm run dev
```

Open `http://localhost:3000`. The PHP version remains available separately in `../webapp`.