// Service worker for ELO PWA
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (e) => e.waitUntil(clients.claim()));

// Fetch handler required for PWA installability — passes HTTP requests through.
// Non-HTTP requests (WebSocket upgrades, chrome-extension URIs, etc.) must not
// be intercepted — handing them to fetch() causes a network error.
self.addEventListener('fetch', (e) => {
  if (!e.request.url.startsWith('http')) return;
  e.respondWith(fetch(e.request));
});

// ── Push notification batching ────────────────────────────────────────────
// Rapid messages for the same channel are debounced (200ms) into a single
// notification, then merged with any existing notification for that tag.
// Each push event's waitUntil promise is kept pending until the notification
// is actually shown, so the SW stays alive through the debounce window.
const _batches = new Map(); // tag → { timer, msgs, meta, resolvers }

function formatBody(messages, isDM) {
  if (isDM) {
    // DM: title = sender name, just stack the messages
    return messages.map((m) => m.text).join('\n');
  }
  // Group channel: group consecutive messages from the same author
  const lines = [];
  let lastAuthor = null;
  for (const msg of messages) {
    if (msg.author !== lastAuthor) {
      if (msg.author) lines.push(`${msg.author}:`);
      lastAuthor = msg.author;
    }
    lines.push(msg.text);
  }
  return lines.join('\n');
}

self.addEventListener('push', (e) => {
  let data = {};
  try { data = e.data ? e.data.json() : {}; } catch (_) {}

  const tag     = data.tag || 'mngt-chat';
  const isDM    = data.ch_type === 'messaging';
  const author  = data.author || '';
  const msgText = data.text || data.body || '';

  // Each push event gets a promise that resolves only after the notification
  // is shown, keeping the SW alive across the debounce window.
  const p = new Promise((resolve) => {
    if (!_batches.has(tag)) {
      _batches.set(tag, {
        msgs:      [],
        resolvers: [],
        timer:     null,
        meta: {
          title:       data.title || 'Nova mensagem',
          icon:        data.icon,
          reply_token: data.reply_token,
          isDM,
          url:         data.url || '/',
        },
      });
    }

    const batch = _batches.get(tag);
    batch.msgs.push({ author, text: msgText });
    batch.msgs = batch.msgs.slice(-5);
    // Always keep the latest reply token and title
    if (data.reply_token) batch.meta.reply_token = data.reply_token;
    if (data.title)       batch.meta.title        = data.title;
    batch.resolvers.push(resolve);

    // Reset the debounce window
    clearTimeout(batch.timer);
    batch.timer = setTimeout(async () => {
      const b = _batches.get(tag);
      _batches.delete(tag);

      try {
        // Suppress notification when the user already has the app visible —
        // the in-app badge/sound covers this case.
        const windowClients = await clients.matchAll({ type: 'window', includeUncontrolled: true });
        const appVisible = windowClients.some((c) => c.visibilityState === 'visible');

        if (!appVisible) {
          // Merge with any notification already visible for this channel
          const existing  = await self.registration.getNotifications({ tag });
          const prevMsgs  = existing.length > 0
            ? (existing[0].data?.messages ?? [])
            : [];
          const allMsgs   = [...prevMsgs, ...b.msgs].slice(-5);

          const icon = b.meta.icon && b.meta.icon.startsWith('http')
            ? b.meta.icon
            : (self.location.origin + '/favicon.ico');

          await self.registration.showNotification(b.meta.title, {
            body:     formatBody(allMsgs, b.meta.isDM),
            icon,
            badge:    self.location.origin + '/favicon.ico',
            tag,
            renotify: true,
            data:     { url: b.meta.url, messages: allMsgs, reply_token: b.meta.reply_token, isDM: b.meta.isDM },
            actions:  [{ action: 'reply', type: 'text', title: 'Responder', placeholder: 'Digite uma resposta...' }],
          });
        }
      } catch (err) {
        console.warn('[mngt:sw] showNotification error', err);
      }

      // Release all pending push events
      b.resolvers.forEach((r) => r());
    }, 200);
  });

  e.waitUntil(p);
});

// ── Notification click / inline reply ────────────────────────────────────
self.addEventListener('notificationclick', (e) => {
  const notif = e.notification;
  notif.close();

  if (e.action === 'reply') {
    const token = notif.data?.reply_token;
    const text  = (e.reply || '').trim();

    if (token && text) {
      // Inline reply supported (Android Chrome) — send directly
      e.waitUntil(
        fetch('/mngt/chat/reply', {
          method:  'POST',
          headers: { 'Content-Type': 'application/json' },
          body:    JSON.stringify({ token, text }),
        }).catch(() => {})
      );
    } else {
      // Browser doesn't support inline reply (desktop) — open the chat
      const target = notif.data?.url || '/';
      e.waitUntil(
        clients.matchAll({ type: 'window', includeUncontrolled: true }).then((list) => {
          const existing = list.find((c) => c.url.startsWith(self.location.origin) && 'focus' in c);
          if (existing) return existing.focus();
          return clients.openWindow(target);
        })
      );
    }
    return;
  }

  // Default click: focus or open the app at the notification URL
  const target = notif.data?.url || '/';
  e.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((list) => {
      const existing = list.find((c) => c.url.startsWith(self.location.origin) && 'focus' in c);
      if (existing) return existing.focus();
      return clients.openWindow(target);
    })
  );
});
