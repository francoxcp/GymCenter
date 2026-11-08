// Prueba de humo de la build web: arranca la app en Chrome headless y
// verifica que carga sin errores, que el router lleva a /login, que el
// puente JS y el service worker están activos y que el splash desaparece.
// Uso: node tool/web_smoke_test.mjs http://localhost:8080
import puppeteer from 'puppeteer-core';

const base = process.argv[2] || 'http://localhost:8080';
const browser = await puppeteer.launch({
  executablePath: process.env.CHROME_PATH || '/usr/bin/google-chrome',
  args: ['--no-sandbox'],
});
const errors = [];
try {
  const page = await browser.newPage();
  await page.setViewport({ width: 390, height: 844, isMobile: true, hasTouch: true });
  page.on('pageerror', (e) => errors.push(`pageerror: ${e.message}`));
  page.on('console', (m) => {
    const t = m.text();
    console.log(`[console.${m.type()}] ${t}`);
    if (m.type() === 'error' && !/favicon|Failed to load resource|ERR_INTERNET_DISCONNECTED|net::/.test(t)) errors.push(t);
  });

  await page.goto(base + '/', { waitUntil: 'networkidle2', timeout: 60000 });
  await page.waitForFunction(() => !document.getElementById('gc-splash'), { timeout: 60000 });
  await page.waitForFunction(() => location.pathname === '/login', { timeout: 30000 });

  const info = await page.evaluate(async () => ({
    path: location.pathname,
    bridge: typeof window.gcBridge === 'object',
    sw: !!(await navigator.serviceWorker.getRegistration()),
    flutterView: !!document.querySelector('flutter-view, flt-glass-pane'),
    title: document.title,
  }));
  console.log('Resultado:', JSON.stringify(info));
  if (!info.bridge) errors.push('gcBridge no está definido');
  if (!info.sw) errors.push('service worker no registrado');
  if (!info.flutterView) errors.push('Flutter no se montó en la página');

  // Deep link a ruta protegida sin sesión → debe acabar en /login
  await page.goto(base + '/workouts', { waitUntil: 'networkidle2', timeout: 60000 });
  await page.waitForFunction(() => location.pathname === '/login', { timeout: 30000 });
  console.log('Deep link protegido redirige a /login ✓');

  // Modo sin conexión: tras una visita con red, la app debe abrir sin red
  await page.evaluate(async () => {
    const reg = await navigator.serviceWorker.ready;
    return !!reg.active;
  });
  await new Promise((r) => setTimeout(r, 3000)); // dejar terminar el precacheo
  await page.setOfflineMode(true);
  await page.goto(base + '/', { waitUntil: 'load', timeout: 60000 });
  await page.waitForFunction(() => !document.getElementById('gc-splash'), { timeout: 60000 });
  await page.waitForFunction(() => location.pathname === '/login', { timeout: 30000 });
  const offlineOk = await page.evaluate(() => !!document.querySelector('flutter-view, flt-glass-pane'));
  if (!offlineOk) errors.push('La app no abrió sin conexión');
  else console.log('Abre sin conexión ✓');
  await page.setOfflineMode(false);
} catch (e) {
  errors.push(`fallo: ${e.message}`);
} finally {
  await browser.close();
}
if (errors.length) {
  console.error('ERRORES:\n' + errors.join('\n'));
  process.exit(1);
}
console.log('Smoke test OK ✓');
