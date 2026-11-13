import 'dotenv/config';

import { createHash, randomBytes } from 'node:crypto';
import { mkdirSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { DatabaseSync } from 'node:sqlite';

import express from 'express';
import * as webpush from 'web-push';

const __dirname = dirname(fileURLToPath(import.meta.url));

const PORT = Number.parseInt(process.env.PORT ?? '8787', 10);
const DB_PATH = resolve(
  __dirname,
  process.env.DB_PATH ?? './data/dearme.sqlite',
);
const VAPID_SUBJECT = process.env.VAPID_SUBJECT ?? '';
const VAPID_PUBLIC_KEY = process.env.VAPID_PUBLIC_KEY ?? '';
const VAPID_PRIVATE_KEY = process.env.VAPID_PRIVATE_KEY ?? '';
const PUSH_TTL_SECONDS = clampInt(
  Number.parseInt(process.env.PUSH_TTL_SECONDS ?? '86400', 10),
  60,
  2419200,
);
const SCHEDULER_INTERVAL_MS = clampInt(
  Number.parseInt(process.env.SCHEDULER_INTERVAL_MS ?? '30000', 10),
  5000,
  300000,
);
const ALLOWED_ORIGINS = new Set(
  (process.env.ALLOWED_ORIGINS ?? '')
    .split(',')
    .map((origin) => origin.trim().replace(/\/$/, ''))
    .filter(Boolean),
);

if (!VAPID_SUBJECT || !VAPID_PUBLIC_KEY || !VAPID_PRIVATE_KEY) {
  console.error(
    'Missing VAPID configuration. Copy .env.example to .env and run `npm run generate-vapid`.',
  );
  process.exit(1);
}
if (
  !VAPID_SUBJECT.startsWith('mailto:') &&
  !VAPID_SUBJECT.startsWith('https://')
) {
  console.error('VAPID_SUBJECT must be a mailto: or https:// address.');
  process.exit(1);
}

webpush.setVapidDetails(
  VAPID_SUBJECT,
  VAPID_PUBLIC_KEY,
  VAPID_PRIVATE_KEY,
);

mkdirSync(dirname(DB_PATH), { recursive: true });
const db = new DatabaseSync(DB_PATH);
db.exec('PRAGMA journal_mode = WAL;');
db.exec('PRAGMA foreign_keys = ON;');
db.exec(`
  CREATE TABLE IF NOT EXISTS subscriptions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    endpoint TEXT NOT NULL UNIQUE,
    p256dh TEXT NOT NULL,
    auth TEXT NOT NULL,
    locale TEXT NOT NULL DEFAULT 'ru',
    click_base_url TEXT NOT NULL,
    user_agent TEXT,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
  );

  CREATE TABLE IF NOT EXISTS device_tokens (
    token_hash TEXT PRIMARY KEY,
    subscription_id INTEGER NOT NULL REFERENCES subscriptions(id) ON DELETE CASCADE,
    created_at INTEGER NOT NULL
  );

  CREATE TABLE IF NOT EXISTS schedule (
    subscription_id INTEGER NOT NULL REFERENCES subscriptions(id) ON DELETE CASCADE,
    letter_id TEXT NOT NULL,
    deliver_at INTEGER NOT NULL,
    created_at INTEGER NOT NULL,
    delivered_at INTEGER,
    attempts INTEGER NOT NULL DEFAULT 0,
    last_error TEXT,
    PRIMARY KEY (subscription_id, letter_id)
  );

  CREATE INDEX IF NOT EXISTS idx_schedule_due
    ON schedule(delivered_at, deliver_at);
`);

const MESSAGES = {
  ru: {
    title: 'Твоё письмо из прошлого 💌',
    body: 'Письмо, которое ты написал себе, готово к открытию.',
    testTitle: 'DearMe на связи',
    testBody: 'Уведомления настроены. Письма из прошлого найдут тебя.',
  },
  en: {
    title: 'A letter from your past 💌',
    body: 'Your letter to your future self is ready to open.',
    testTitle: 'DearMe is here',
    testBody: 'Notifications are ready. Letters from the past will find you.',
  },
};

const app = express();
app.disable('x-powered-by');
if (process.env.TRUST_PROXY === '1') {
  app.set('trust proxy', 1);
}
app.use(express.json({ limit: '64kb' }));
app.use((req, res, next) => {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('Referrer-Policy', 'no-referrer');
  res.setHeader('Cache-Control', 'no-store');
  next();
});
app.use(corsMiddleware);
app.use(rateLimit());
app.use('/api/subscriptions', rateLimit(20, 60_000));
app.use('/api/test', rateLimit(10, 60_000));

app.get('/api/health', (req, res) => {
  res.json({ ok: true, app: 'dearme-push' });
});

app.get('/api/config', (req, res) => {
  res.json({
    app: 'dearme',
    vapidPublicKey: VAPID_PUBLIC_KEY,
    pushTtlSeconds: PUSH_TTL_SECONDS,
  });
});

app.post('/api/subscriptions', (req, res) => {
  try {
    const { subscription, locale, clickBaseUrl, userAgent } = req.body ?? {};
    const parsed = validateSubscription(subscription);
    const safeLocale = locale === 'en' ? 'en' : 'ru';
    const safeClickBase = normalizeClickBase(clickBaseUrl);
    const safeUserAgent = limitString(userAgent, 512) ?? null;

    const now = Date.now();
    const existing = db
      .prepare('SELECT id FROM subscriptions WHERE endpoint = ?')
      .get(parsed.endpoint);

    let subscriptionId;
    if (existing) {
      subscriptionId = existing.id;
      db.prepare(
        `UPDATE subscriptions
         SET p256dh = ?, auth = ?, locale = ?, click_base_url = ?,
             user_agent = ?, updated_at = ?
         WHERE id = ?`,
      ).run(
        parsed.p256dh,
        parsed.auth,
        safeLocale,
        safeClickBase,
        safeUserAgent,
        now,
        subscriptionId,
      );
      db.prepare('DELETE FROM device_tokens WHERE subscription_id = ?').run(
        subscriptionId,
      );
    } else {
      const result = db
        .prepare(
          `INSERT INTO subscriptions
             (endpoint, p256dh, auth, locale, click_base_url, user_agent,
              created_at, updated_at)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
        )
        .run(
          parsed.endpoint,
          parsed.p256dh,
          parsed.auth,
          safeLocale,
          safeClickBase,
          safeUserAgent,
          now,
          now,
        );
      subscriptionId = Number(result.lastInsertRowid);
    }

    const deviceToken = randomBytes(32).toString('base64url');
    db.prepare(
      'INSERT INTO device_tokens (token_hash, subscription_id, created_at) VALUES (?, ?, ?)',
    ).run(hashToken(deviceToken), subscriptionId, now);

    res.status(201).json({ deviceToken });
  } catch (error) {
    respondValidationError(res, error);
  }
});

app.put('/api/schedule', authenticate, (req, res) => {
  try {
    const subscription = req.subscription;
    const letters = req.body?.letters;
    if (!Array.isArray(letters)) {
      return res.status(400).json({ error: 'letters_required' });
    }
    if (letters.length > 500) {
      return res.status(400).json({ error: 'too_many_letters' });
    }

    const locale = req.body?.locale === 'en' ? 'en' : 'ru';
    const clickBase = req.body?.clickBaseUrl
      ? normalizeClickBase(req.body.clickBaseUrl)
      : subscription.click_base_url;
    const userAgent = limitString(req.body?.userAgent, 512) ?? null;

    const now = Date.now();
    const unique = new Map();
    for (const item of letters) {
      if (!item || typeof item !== 'object') {
        throw new ValidationError('invalid_letter');
      }
      const id = item.id;
      if (typeof id !== 'string' || !/^[A-Za-z0-9_-]{8,128}$/.test(id)) {
        throw new ValidationError('invalid_letter_id');
      }
      const deliverAt = Date.parse(item.openAt);
      if (!Number.isFinite(deliverAt)) {
        throw new ValidationError('invalid_open_at');
      }
      if (deliverAt > now + 100 * 365 * 24 * 60 * 60 * 1000) {
        throw new ValidationError('open_at_too_far');
      }
      unique.set(id, deliverAt);
    }

    db.prepare(
      `UPDATE subscriptions
       SET locale = ?, click_base_url = ?, user_agent = COALESCE(?, user_agent),
           updated_at = ?
       WHERE id = ?`,
    ).run(
      locale,
      clickBase,
      userAgent,
      now,
      subscription.id,
    );

    db.exec('BEGIN IMMEDIATE');
    try {
      db.prepare('DELETE FROM schedule WHERE subscription_id = ?').run(
        subscription.id,
      );
      const insert = db.prepare(
        `INSERT INTO schedule
           (subscription_id, letter_id, deliver_at, created_at)
         VALUES (?, ?, ?, ?)`,
      );
      for (const [letterId, deliverAt] of unique) {
        insert.run(subscription.id, letterId, deliverAt, now);
      }
      db.exec('COMMIT');
    } catch (error) {
      db.exec('ROLLBACK');
      throw error;
    }

    res.status(204).end();
  } catch (error) {
    respondValidationError(res, error);
  }
});

app.post('/api/test', authenticate, async (req, res) => {
  const subscription = req.subscription;
  const locale = req.body?.locale === 'en' ? 'en' : subscription.locale;
  const messages = MESSAGES[locale] ?? MESSAGES.ru;
  const clickBase = subscription.click_base_url;
  const payload = {
    title: messages.testTitle,
    body: messages.testBody,
    url: clickBase,
    icon: new URL('icons/Icon-192.png', clickBase).toString(),
    tag: `dearme-test-${Date.now()}`,
  };

  try {
    await sendToSubscription(subscription, payload);
    res.status(204).end();
  } catch (error) {
    if (isGone(error)) {
      deleteSubscription(subscription.id);
      return res.status(410).json({ error: 'subscription_gone' });
    }
    console.error('Test push failed:', error.statusCode ?? error.message);
    res.status(502).json({ error: 'push_failed' });
  }
});

app.delete('/api/subscription', authenticate, (req, res) => {
  deleteSubscription(req.subscription.id);
  res.status(204).end();
});

app.use((req, res) => {
  res.status(404).json({ error: 'not_found' });
});

app.use((error, req, res, next) => {
  if (
    error instanceof SyntaxError ||
    error.type === 'entity.parse.failed'
  ) {
    return res.status(400).json({ error: 'invalid_json' });
  }
  console.error('Unhandled error:', error.message);
  if (!res.headersSent) {
    res.status(500).json({ error: 'internal_error' });
  }
});

const server = app.listen(PORT, () => {
  console.log(`DearMe push backend listening on http://localhost:${PORT}`);
  if (ALLOWED_ORIGINS.size === 0) {
    console.warn(
      'ALLOWED_ORIGINS is empty. Only loopback origins are accepted; set it before deploying.',
    );
  }
});

let schedulerRunning = false;

async function runScheduler() {
  if (schedulerRunning) {
    return;
  }
  schedulerRunning = true;
  try {
    const now = Date.now();
    const due = db
      .prepare(
        `SELECT
           sch.subscription_id, sch.letter_id, sch.deliver_at, sch.attempts,
           sub.endpoint, sub.p256dh, sub.auth, sub.locale, sub.click_base_url
         FROM schedule sch
         JOIN subscriptions sub ON sub.id = sch.subscription_id
         WHERE sch.delivered_at IS NULL AND sch.deliver_at <= ?
         ORDER BY sch.deliver_at ASC
         LIMIT 50`,
      )
      .all(now);

    for (const row of due) {
      const messages = MESSAGES[row.locale] ?? MESSAGES.ru;
      const url = buildClickUrl(row.click_base_url, row.letter_id);
      const payload = {
        title: messages.title,
        body: messages.body,
        url,
        icon: new URL('icons/Icon-192.png', row.click_base_url).toString(),
        tag: `dearme-letter-${row.letter_id}`,
      };

      try {
        await sendToSubscription(row, payload);
        db.prepare(
          `UPDATE schedule
           SET delivered_at = ?, attempts = attempts + 1, last_error = NULL
           WHERE subscription_id = ? AND letter_id = ?`,
        ).run(Date.now(), row.subscription_id, row.letter_id);
      } catch (error) {
        if (isGone(error)) {
          deleteSubscription(row.subscription_id);
          continue;
        }
        const attempts = row.attempts + 1;
        const tooOld = Date.now() - row.deliver_at > 24 * 60 * 60 * 1000;
        db.prepare(
          `UPDATE schedule
           SET attempts = ?, last_error = ?, delivered_at = ?
           WHERE subscription_id = ? AND letter_id = ?`,
        ).run(
          attempts,
          limitString(error.message, 500),
          attempts >= 10 || tooOld ? Date.now() : null,
          row.subscription_id,
          row.letter_id,
        );
        console.error(
          `Push failed (attempt ${attempts}, status ${error.statusCode ?? 'n/a'}) for a scheduled letter.`,
        );
      }
    }

    // Keep the reference database small. Delivered rows older than 30 days no
    // longer have any purpose; undelivered rows are kept for inspection.
    db.prepare(
      'DELETE FROM schedule WHERE delivered_at IS NOT NULL AND delivered_at < ?',
    ).run(Date.now() - 30 * 24 * 60 * 60 * 1000);
  } catch (error) {
    console.error('Scheduler error:', error.message);
  } finally {
    schedulerRunning = false;
  }
}

setInterval(() => {
  void runScheduler();
}, SCHEDULER_INTERVAL_MS).unref();
void runScheduler();

function authenticate(req, res, next) {
  const header = req.headers.authorization ?? '';
  if (!header.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'unauthorized' });
  }
  const token = header.slice('Bearer '.length).trim();
  if (token.length < 20 || token.length > 128) {
    return res.status(401).json({ error: 'unauthorized' });
  }
  const row = db
    .prepare(
      `SELECT sub.*
       FROM device_tokens tok
       JOIN subscriptions sub ON sub.id = tok.subscription_id
       WHERE tok.token_hash = ?`,
    )
    .get(hashToken(token));
  if (!row) {
    return res.status(401).json({ error: 'unauthorized' });
  }
  req.subscription = row;
  next();
}

async function sendToSubscription(subscription, payload) {
  await webpush.sendNotification(
    {
      endpoint: subscription.endpoint,
      keys: {
        p256dh: subscription.p256dh,
        auth: subscription.auth,
      },
    },
    JSON.stringify(payload),
    {
      TTL: PUSH_TTL_SECONDS,
      urgency: 'normal',
    },
  );
}

function deleteSubscription(id) {
  db.prepare('DELETE FROM subscriptions WHERE id = ?').run(id);
}

function isGone(error) {
  return error?.statusCode === 404 || error?.statusCode === 410;
}

function buildClickUrl(base, letterId) {
  const url = new URL(base);
  url.searchParams.set('letter', letterId);
  return url.toString();
}

function validateSubscription(subscription) {
  if (!subscription || typeof subscription !== 'object') {
    throw new ValidationError('subscription_required');
  }
  const endpoint = subscription.endpoint;
  if (typeof endpoint !== 'string' || endpoint.length > 2048) {
    throw new ValidationError('invalid_endpoint');
  }
  let endpointUrl;
  try {
    endpointUrl = new URL(endpoint);
  } catch {
    throw new ValidationError('invalid_endpoint');
  }
  if (endpointUrl.protocol !== 'https:' && !isLoopback(endpointUrl.hostname)) {
    throw new ValidationError('endpoint_must_be_https');
  }
  const keys = subscription.keys;
  if (!keys || typeof keys !== 'object') {
    throw new ValidationError('keys_required');
  }
  const p256dh = keys.p256dh;
  const auth = keys.auth;
  if (!isBase64Url(p256dh, 40, 200) || !isBase64Url(auth, 8, 100)) {
    throw new ValidationError('invalid_keys');
  }
  return { endpoint, p256dh, auth };
}

function normalizeClickBase(value) {
  if (typeof value !== 'string' || value.length > 2048) {
    throw new ValidationError('invalid_click_url');
  }
  let url;
  try {
    url = new URL(value);
  } catch {
    throw new ValidationError('invalid_click_url');
  }
  if (url.username || url.password) {
    throw new ValidationError('invalid_click_url');
  }
  if (url.protocol !== 'https:' && !isLoopback(url.hostname)) {
    throw new ValidationError('click_url_must_be_https');
  }
  if (ALLOWED_ORIGINS.size > 0 && !ALLOWED_ORIGINS.has(url.origin)) {
    throw new ValidationError('origin_not_allowed');
  }
  if (ALLOWED_ORIGINS.size === 0 && !isLoopback(url.hostname)) {
    throw new ValidationError('origin_not_allowed');
  }
  url.hash = '';
  url.search = '';
  return url.toString();
}

function isBase64Url(value, min, max) {
  return (
    typeof value === 'string' &&
    value.length >= min &&
    value.length <= max &&
    /^[A-Za-z0-9_-]+$/.test(value)
  );
}

function limitString(value, max) {
  if (value === null || value === undefined) {
    return null;
  }
  return String(value).slice(0, max);
}

function hashToken(token) {
  return createHash('sha256').update(token).digest('hex');
}

function isLoopback(hostname) {
  return (
    hostname === 'localhost' ||
    hostname === '127.0.0.1' ||
    hostname === '::1' ||
    hostname === '[::1]'
  );
}

function corsMiddleware(req, res, next) {
  const origin = req.headers.origin;
  if (origin) {
    let allowed = false;
    try {
      allowed =
        ALLOWED_ORIGINS.size > 0
          ? ALLOWED_ORIGINS.has(origin)
          : isLoopback(new URL(origin).hostname);
    } catch {
      allowed = false;
    }
    if (!allowed) {
      return res.status(403).json({ error: 'origin_not_allowed' });
    }
    res.setHeader('Access-Control-Allow-Origin', origin);
    res.setHeader('Vary', 'Origin');
    res.setHeader(
      'Access-Control-Allow-Headers',
      'content-type, authorization',
    );
    res.setHeader('Access-Control-Allow-Methods', 'GET,POST,PUT,DELETE,OPTIONS');
    res.setHeader('Access-Control-Max-Age', '600');
  }
  if (req.method === 'OPTIONS') {
    return res.status(204).end();
  }
  next();
}

const buckets = new Map();

function rateLimit(limit = 180, windowMs = 60_000) {
  return (req, res, next) => {
    const key = `${req.ip}:${req.path}`;
    const now = Date.now();
    let bucket = buckets.get(key);
    if (!bucket || bucket.resetAt <= now) {
      bucket = { count: 0, resetAt: now + windowMs };
      buckets.set(key, bucket);
    }
    bucket.count += 1;
    if (bucket.count > limit) {
      res.setHeader('Retry-After', Math.ceil((bucket.resetAt - now) / 1000));
      return res.status(429).json({ error: 'rate_limited' });
    }
    next();
  };
}

setInterval(() => {
  const now = Date.now();
  for (const [key, bucket] of buckets) {
    if (bucket.resetAt <= now) {
      buckets.delete(key);
    }
  }
}, 5 * 60_000).unref();

function respondValidationError(res, error) {
  if (error instanceof ValidationError) {
    return res.status(400).json({ error: error.code });
  }
  console.error('Request error:', error.message);
  return res.status(500).json({ error: 'internal_error' });
}

function clampInt(value, min, max) {
  if (!Number.isFinite(value)) {
    return min;
  }
  return Math.min(max, Math.max(min, value));
}

class ValidationError extends Error {
  constructor(code) {
    super(code);
    this.name = 'ValidationError';
    this.code = code;
  }
}

function shutdown() {
  console.log('Shutting down...');
  server.close(() => {
    db.close();
    process.exit(0);
  });
  setTimeout(() => process.exit(0), 5000).unref();
}

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);
