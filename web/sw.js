// Service worker de GYMLAB (PWA).
// - Modo sin conexión: guarda la app (HTML, JS, motor gráfico, íconos y
//   fuentes) para que abra aunque no haya internet en el gimnasio.
//   Estrategia "red primero": con conexión siempre carga la última versión
//   publicada; sin conexión usa la copia guardada.
// - Recibe notificaciones Web Push enviadas por la Edge Function de Supabase.
// - Al tocar una notificación, enfoca la app y navega a la ruta indicada.

const CACHE = 'gymlab-app-v3';
const FONT_CACHE = 'gymlab-fonts-v1';
const NETWORK_TIMEOUT_MS = 4000;

// Núcleo mínimo para abrir la app sin conexión (el resto se guarda al usarse)
const CORE = [
  './',
  'index.html',
  'flutter_bootstrap.js',
  'main.dart.js',
  'gc_bridge.js',
  'manifest.json',
  'favicon.png',
  'icons/Icon-192.png',
  'icons/Icon-512.png',
  'icons/apple-touch-icon.png',
  'assets/FontManifest.json',
  'assets/AssetManifest.bin.json',
  'assets/fonts/MaterialIcons-Regular.otf',
  'assets/packages/cupertino_icons/assets/CupertinoIcons.ttf',
  // Motor gráfico de Flutter (servido desde el propio sitio: --no-web-resources-cdn)
  'canvaskit/canvaskit.js',
  'canvaskit/canvaskit.wasm',
  'canvaskit/chromium/canvaskit.js',
  'canvaskit/chromium/canvaskit.wasm',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    (async () => {
      const cache = await caches.open(CACHE);
      // Uno a uno: si alguno falla no se cancela toda la instalación
      await Promise.all(
        CORE.map((url) =>
          fetch(url, { cache: 'no-cache' })
            .then((res) => (res.ok ? cache.put(url, res) : undefined))
            .catch(() => undefined)
        )
      );
      await self.skipWaiting();
    })()
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      const keys = await caches.keys();
      await Promise.all(
        keys
          .filter((k) => k !== CACHE && k !== FONT_CACHE)
          .map((k) => caches.delete(k))
      );
      await self.clients.claim();
    })()
  );
});

function timeout(ms) {
  return new Promise((_, reject) => setTimeout(() => reject(new Error('timeout')), ms));
}

async function networkFirst(request, cacheKey) {
  const cache = await caches.open(CACHE);
  try {
    const response = await Promise.race([fetch(request), timeout(NETWORK_TIMEOUT_MS)]);
    if (response && response.ok) {
      cache.put(cacheKey || request, response.clone());
    }
    return response;
  } catch (_) {
    const cached = await cache.match(cacheKey || request, { ignoreSearch: true });
    if (cached) return cached;
    throw _;
  }
}

async function cacheFirst(request, cacheName) {
  const cache = await caches.open(cacheName);
  const cached = await cache.match(request);
  if (cached) return cached;
  const response = await fetch(request);
  if (response && (response.ok || response.type === 'opaque')) {
    cache.put(request, response.clone());
  }
  return response;
}

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;
  // Los videos usan peticiones parciales (Range): no se cachean
  if (req.headers.has('range')) return;

  const url = new URL(req.url);

  // Fuentes de respaldo que Flutter web baja de Google: caché primero
  if (url.hostname === 'fonts.gstatic.com' || url.hostname === 'fonts.googleapis.com') {
    event.respondWith(cacheFirst(req, FONT_CACHE));
    return;
  }

  // Solo archivos de la propia app (nunca la API de Supabase)
  if (url.origin !== self.location.origin) return;

  // Navegación (/, /today-workout, ...): app de una sola página → index.html
  if (req.mode === 'navigate') {
    event.respondWith(
      networkFirst(req, 'index.html').catch(
        () => new Response('Sin conexión', { status: 503, headers: { 'Content-Type': 'text/plain; charset=utf-8' } })
      )
    );
    return;
  }

  event.respondWith(networkFirst(req));
});

self.addEventListener('push', (event) => {
  let payload = {};
  try {
    payload = event.data ? event.data.json() : {};
  } catch (_) {
    payload = { body: event.data ? event.data.text() : '' };
  }
  const title = payload.title || 'GYMLAB';
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
