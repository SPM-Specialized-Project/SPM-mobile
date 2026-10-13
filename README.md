# SPM Mobile

This repository contains the Flutter mobile app, the Node.js API, and the React/Vite web app.

## Project layout

- `lib/` — Flutter application.
- `backend/` — Node.js HTTP API and its tests.
- `frontend/` — React/Vite web application.
- `docs/api/backend-routes.md` — backend routes with request and response contracts.

## Run locally

Start the backend from one terminal:

```powershell
Set-Location .\backend
npm run dev
```

Start the web frontend from another terminal:

```powershell
Set-Location .\frontend
npm install
npm run dev
```

The Vite development server listens on port `3000` and proxies `/api` to `http://127.0.0.1:4000` by default. Override the target with `VITE_BACKEND_PROXY_TARGET`.

Run Flutter from the repository root:

```powershell
flutter run -d emulator-5554
```

The Android emulator uses `http://10.0.2.2:4000` by default. Set `--dart-define=API_BASE_URL=...` for another device or server.

## Current API scope

The imported backend serves the `/api/*` and `/api/codepulse/*` routes documented in [the route contract](docs/api/backend-routes.md). The Flutter TSSA feature currently calls `/api/v1/*`; those TSSA server routes are not part of this backend snapshot yet.
