/*
 * DearMe Web Push service worker.
 *
 * This worker is intentionally registered on a narrow scope (/push-scope/) so
 * it can never take over the page from Flutter's own generated service worker.
 * It only handles Push API messages and notification clicks.
 */

'use strict';

self.addEventListener('install', function (event) {
  self.skipWaiting();
});

self.addEventListener('activate', function (event) {
  event.waitUntil(self.clients.claim());
});

self.addEventListener('push', function (event) {
  var payload = {};
  try {
    if (event.data) {
      payload = event.data.json();
    }
  } catch (error) {
    try {
      payload = { body: event.data ? event.data.text() : '' };
    } catch (ignored) {
      payload = {};
    }
  }

  var title = payload.title || 'DearMe';
  var body = payload.body || '';
  var icon = payload.icon || new URL('icons/Icon-192.png', self.location.origin).href;
  var url = payload.url || new URL('./', self.location.origin).href;
  var tag = payload.tag || 'dearme-letter';

  event.waitUntil(
    self.registration.showNotification(title, {
      body: body,
      icon: icon,
      badge: icon,
      tag: tag,
      renotify: true,
      requireInteraction: false,
      data: { url: url },
      vibrate: [90, 50, 90],
      timestamp: Date.now()
    })
  );
});

self.addEventListener('notificationclick', function (event) {
  event.notification.close();
  var targetUrl = event.notification.data && event.notification.data.url
    ? event.notification.data.url
    : new URL('./', self.location.origin).href;

  event.waitUntil(
    (async function () {
      var windowClients = await self.clients.matchAll({
        type: 'window',
        includeUncontrolled: true
      });

      for (var i = 0; i < windowClients.length; i++) {
        var client = windowClients[i];
        if (client.url.indexOf(self.location.origin) !== 0) {
          continue;
        }
        try {
          await client.focus();
          if ('navigate' in client) {
            await client.navigate(targetUrl);
          }
          return;
        } catch (error) {
          // Fall through to opening a new window.
        }
      }

      if (self.clients.openWindow) {
        await self.clients.openWindow(targetUrl);
      }
    })()
  );
});

self.addEventListener('pushsubscriptionchange', function (event) {
  // Browsers may rotate a subscription. Re-subscribe with the same options,
  // then ask any open DearMe tab to upload the new endpoint and schedule. If no
  // tab is open, the app performs the upload on its next launch. No letter
  // content is involved in this handshake.
  event.waitUntil(
    (async function () {
      try {
        if (!event.newSubscription && event.oldSubscription) {
          await self.registration.pushManager.subscribe(
            event.oldSubscription.options
          );
        }
      } catch (error) {
        // Some browsers do not allow re-subscription from this event.
      }

      try {
        var windowClients = await self.clients.matchAll({
          type: 'window',
          includeUncontrolled: true
        });
        for (var i = 0; i < windowClients.length; i++) {
          windowClients[i].postMessage({
            type: 'dearme-push-subscription-changed'
          });
        }
      } catch (error) {
        // No clients available; next launch will resync.
      }
    })()
  );
});
