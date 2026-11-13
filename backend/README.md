# DearMe Web Push backend

A small Node.js service that stores **push subscriptions** and **delivery
times**, then sends Web Push messages through the browser's push service. It
never receives letter titles or letter text.

## What is stored

| Table | Data |
| --- | --- |
| `subscriptions` | Push endpoint, `p256dh`/`auth` public keys, locale, click base URL, optional user agent |
| `device_tokens` | SHA-256 hashes of random device tokens (the raw token is returned once to the browser) |
| `schedule` | Letter UUID, opening instant, delivery status, retry metadata |

No letter content or author identity is stored. The database is SQLite and
lives on the server volume.

## Requirements

- Node.js 24+ (Node 26 recommended; `node:sqlite` is built in)
- HTTPS in production. Web Push, Service Workers and `Notification` require a
  secure context. `http://localhost` is accepted for development.
- VAPID keys. Generate once:

```bash
cd backend
npm install
npm run generate-vapid
```

Copy the public and private keys into `.env`.

```bash
cp .env.example .env
# edit .env
npm start
```

The server refuses to start without valid VAPID configuration.

## Environment variables

| Variable | Required | Description |
| --- | --- | --- |
| `PORT` | no | HTTP port, default `8787` |
| `VAPID_SUBJECT` | yes | `mailto:` or `https:` contact for the push service |
| `VAPID_PUBLIC_KEY` | yes | Public VAPID key (also delivered to the app via `/api/config`) |
| `VAPID_PRIVATE_KEY` | yes | **Secret** private key. Never put it in Flutter/Web code |
| `ALLOWED_ORIGINS` | yes in production | Comma-separated origins, e.g. `https://dearme.example.com` |
| `DB_PATH` | no | SQLite path, default `./data/dearme.sqlite` |
| `PUSH_TTL_SECONDS` | no | How long the push service stores an undelivered message, default 1 day |
| `SCHEDULER_INTERVAL_MS` | no | Scheduler tick, default 30 seconds |
| `TRUST_PROXY` | no | Set to `1` only behind a trusted reverse proxy so rate limiting sees real IPs |

## API

All mutating endpoints except subscription creation require the bearer token
returned by `POST /api/subscriptions`.

| Method | Path | Auth | Purpose |
| --- | --- | --- | --- |
| `GET` | `/api/health` | no | Liveness check |
| `GET` | `/api/config` | no | VAPID public key for `PushManager.subscribe` |
| `POST` | `/api/subscriptions` | no | Register/refresh a push subscription; returns `{deviceToken}` |
| `PUT` | `/api/schedule` | yes | Replace the complete schedule with `{locale, clickBaseUrl, letters:[{id,openAt}]}` |
| `POST` | `/api/test` | yes | Send an immediate localized test push |
| `DELETE` | `/api/subscription` | yes | Remove the subscription and its schedule |

The schedule payload contains only UUIDs and ISO-8601 opening instants.

## Deployment

### Docker

```bash
docker compose up -d --build
```

The service listens on `8787`; put it behind HTTPS (Caddy, nginx, a cloud load
balancer, Fly.io, Render, etc.). Do not expose plain HTTP beyond local tests.

### Building the web client

```bash
flutter build web --release \
  --dart-define=DEARME_PUSH_API=https://push.example.com
```

Serve the `build/web` directory over HTTPS. The app must be on the same or an
allowed origin list as the backend.

### iOS Web Push

On iOS/iPadOS 16.4+, Web Push only works when the user adds the site to the
Home Screen. The manifest and `apple-mobile-web-app-*` metadata are already
included. Safari may still suspend or rate-limit background delivery.

### Browser support

Web Push is implemented by Chrome/Edge, Firefox, Safari 16.4+ (installed PWA on
iOS) and other Chromium browsers. Support is not universal; the Settings screen
reports when Push API, Service Worker or the backend is unavailable.

## Reliability notes

- The scheduler sends a notification once, then marks the row delivered.
  A crash between `sendNotification` and the database update can produce a
  duplicate. This is a deliberate at-least-once trade-off.
- Failed pushes are retried up to 10 times or for 24 hours after the opening
  instant, whichever comes first. `404`/`410` from the push service removes the
  subscription.
- The push service may delay delivery while a device is offline; `TTL` limits
  how long it is retained.
- Deleting a letter on the client replaces the complete server schedule, so its
  pending push is removed.
- The server does not know whether the letter was read.
- For very large production deployments, replace SQLite and the in-process
  scheduler with a managed queue/database. The API contract can stay the same.

## Security checklist

- Keep `VAPID_PRIVATE_KEY` only in the server environment or secret manager.
- Set `ALLOWED_ORIGINS` to the exact production origin(s).
- Terminate TLS before the service.
- Do not log request bodies; this implementation does not.
- Rotate the VAPID key pair only as a last resort: existing subscriptions must
  be recreated.
- Back up `data/dearme.sqlite` if delivery schedules matter; it contains push
  endpoints, which are secrets.
