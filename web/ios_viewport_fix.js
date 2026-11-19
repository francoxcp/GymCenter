// Corrige los toques desplazados en iPhone/iPad después de usar el teclado.
//
// Bug de WebKit (iOS 26/27, sobre todo en la app instalada): al cerrar el
// teclado, la página queda desplazada (window.scrollY o
// visualViewport.offsetTop distintos de 0). Flutter dibuja en su sitio,
// pero los toques llegan corridos: se toca "Editar" y se activa
// "Duplicar", o el botón de play no responde.
// https://bugs.webkit.org/show_bug.cgi?id=254861
//
// Solución: la página nunca debe desplazarse (Flutter maneja su propio
// scroll), así que al cerrar el teclado la devolvemos a 0.
(function () {
  'use strict';

  var ua = navigator.userAgent || '';
  var isIOS = /iP(hone|ad|od)/.test(ua) ||
    (ua.indexOf('Macintosh') !== -1 && navigator.maxTouchPoints > 1);
  if (!isIOS) return;

  var vv = window.visualViewport;
  var timer = null;

  function isShifted() {
    return window.scrollY !== 0 || window.scrollX !== 0 ||
      document.documentElement.scrollTop !== 0 ||
      document.body.scrollTop !== 0 ||
      (vv && Math.abs(vv.offsetTop) > 0.5);
  }

  function keyboardOpen() {
    // Con el teclado abierto el viewport visible es bastante más bajo
    return !!vv && window.innerHeight - vv.height > 120;
  }

  function reset() {
    if (keyboardOpen() || !isShifted()) return;
    window.scrollTo(0, 0);
    document.documentElement.scrollTop = 0;
    document.body.scrollTop = 0;
  }

  // Varios intentos: iOS anima el cierre del teclado (~300 ms)
  function schedule() {
    clearTimeout(timer);
    reset();
    timer = setTimeout(function () {
      reset();
      setTimeout(reset, 250);
    }, 120);
  }

  document.addEventListener('focusout', schedule, true);
  window.addEventListener('orientationchange', schedule);
  window.addEventListener('pageshow', schedule);
  document.addEventListener('visibilitychange', function () {
    if (!document.hidden) schedule();
  });
  if (vv) {
    vv.addEventListener('resize', schedule);
    vv.addEventListener('scroll', function () {
      if (!keyboardOpen()) schedule();
    });
  }
  // Último recurso: antes de procesar un toque, si la página quedó
  // corrida sin teclado, se corrige (el toque siguiente ya acierta).
  window.addEventListener('touchstart', function () {
    if (!keyboardOpen() && isShifted()) reset();
  }, { capture: true, passive: true });
})();
