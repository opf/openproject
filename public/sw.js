// Service worker for ELO PWA
// Handles install lifecycle — push notification support will be added here
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (e) => e.waitUntil(clients.claim()));

// Fetch handler required for PWA installability — passes all requests through
self.addEventListener('fetch', (e) => e.respondWith(fetch(e.request)));
