# SPM Backend

The backend is a Node.js HTTP API using only Node built-ins. It requires Node.js 20 or later.

## Start

```powershell
Set-Location .\backend
npm run dev
```

The server listens at `http://127.0.0.1:4000` by default. Run `npm start` for a non-watch process and `npm test` to run the backend test suite. Bearer sessions expire after 8 hours; `POST /api/auth/logout` revokes the current token.

Configuration:

- `BACKEND_PORT` — HTTP port; defaults to `4000`.
- `BACKEND_DATA_DIRECTORY` — JSON data directory; defaults to `backend/data/`.
- `BACKEND_CORS_ORIGIN` — allowed browser origin; defaults to `http://localhost:3000`.

Local JSON stores are created from seed data on first access and are ignored by Git. Do not commit local data files.

See [the backend route contract](../docs/api/backend-routes.md) for methods, inputs, outputs, and access notes. This backend snapshot does not include the Flutter TSSA `/api/v1/*` service.
