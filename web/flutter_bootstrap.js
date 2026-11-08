{{flutter_js}}
{{flutter_build_config}}

// Arranque personalizado: sin el service worker de Flutter (usamos sw.js
// propio para Web Push) y ocultando el splash cuando la app ya está lista.
_flutter.loader.load({
  onEntrypointLoaded: async function (engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();
    const splash = document.getElementById('gc-splash');
    if (splash) {
      splash.classList.add('hidden');
      setTimeout(() => splash.remove(), 400);
    }
  },
});
