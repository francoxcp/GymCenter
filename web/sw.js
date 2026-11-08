// Service worker de Chamos Fitness Center (PWA).
// - Recibe notificaciones Web Push enviadas por la Edge Function de Supabase.
// - Al tocar una notificación, enfoca la app y navega a la ruta indicada.
// No cachea el código de la app: cada apertura carga la última versión
// publicada (evita que los usuarios queden con versiones viejas).

self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (event) => event.waitUntil(self.clients.claim()));

self.addEventListener('push', (event) => {
  let payload = {};
  try {
    payload = event.data ? event.data.json() : {};
  } catch (_) {
    payload = { body: event.data ? event.data.text() : '' };
  }
  const title = payload.title || 'Chamos Fitness Center';
  const options = {
    body: payload.body || '',
    tag: payload.tag || undefined,
    icon: 'icons/Icon-192.png',
    badge: 'icons/Icon-maskable-192.png',
    data: { url: payload.url || '/' },
  };
  event.waitUntil(self.registration.showNotification(title, options));
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const target = (event.notification.data && event.notification.data.url) || '/';
  event.waitUntil(
    (async () => {
      const all = await self.clients.matchAll({ type: 'window', includeUncontrolled: true });
      for (const client of all) {
        if ('focus' in client) {
          await client.focus();
          client.postMessage({ type: 'gc-navigate', url: target });
          return;
        }
      }
      const scope = self.registration.scope;
      await self.clients.openWindow(scope + '?gc_nav=' + encodeURIComponent(target));
    })()
  );
});
