// Puente JS ⇄ Flutter para funciones exclusivas de la versión web (PWA):
// notificaciones/Web Push, passkeys (Face ID / huella vía WebAuthn),
// descargas de archivos, zona horaria e instalación en pantalla de inicio.
//
// Todas las funciones asíncronas devuelven Promises para usarse desde Dart
// con dart:js_interop (ver lib/shared/web/web_bridge_web.dart).
(function () {
  'use strict';

  // ── Utilidades ──────────────────────────────────────────────────────────
  function b64urlToBytes(b64url) {
    const pad = '='.repeat((4 - (b64url.length % 4)) % 4);
    const b64 = (b64url + pad).replace(/-/g, '+').replace(/_/g, '/');
    const raw = atob(b64);
    const out = new Uint8Array(raw.length);
    for (let i = 0; i < raw.length; i++) out[i] = raw.charCodeAt(i);
    return out;
  }

  function bytesToB64url(buf) {
    const bytes = new Uint8Array(buf);
    let s = '';
    for (let i = 0; i < bytes.length; i++) s += String.fromCharCode(bytes[i]);
    return btoa(s).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
  }

  function randomChallenge() {
    const c = new Uint8Array(32);
    crypto.getRandomValues(c);
    return c;
  }

  const ua = navigator.userAgent || '';
  const isIOS =
    /iPad|iPhone|iPod/.test(ua) ||
    (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);

  // Navegadores dentro de otras apps (Instagram, Facebook, TikTok…): desde
  // ahí no se puede instalar, hay que abrir el enlace en Safari/Chrome.
  const inAppBrowser = /FBAN|FBAV|Instagram|Line\/|TikTok|musical_ly|Snapchat|; wv\)/i.test(ua);

  function isStandalone() {
    return (
      window.matchMedia('(display-mode: standalone)').matches ||
      window.navigator.standalone === true
    );
  }

  // ── Service worker ──────────────────────────────────────────────────────
  let swRegistrationPromise = null;
  function getRegistration() {
    if (!('serviceWorker' in navigator)) return Promise.resolve(null);
    if (!swRegistrationPromise) {
      swRegistrationPromise = navigator.serviceWorker
        .register('sw.js', { scope: './' })
        .then(() => navigator.serviceWorker.ready)
        .catch((e) => {
          console.warn('[gcBridge] SW registration failed', e);
          return null;
        });
    }
    return swRegistrationPromise;
  }
  // Registrar cuanto antes para que la PWA sea instalable.
  getRegistration();

  // Navegación solicitada por el service worker al tocar una notificación.
  let navigateHandler = null;
  let pendingNavigate = null;
  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.addEventListener('message', (event) => {
      const data = event.data || {};
      if (data.type === 'gc-navigate' && typeof data.url === 'string') {
        if (navigateHandler) navigateHandler(data.url);
        else pendingNavigate = data.url;
      }
    });
  }

  // ── Instalación (Android/Chrome) ────────────────────────────────────────
  let deferredInstallPrompt = null;
  window.addEventListener('beforeinstallprompt', (e) => {
    e.preventDefault();
    deferredInstallPrompt = e;
  });
  window.addEventListener('appinstalled', () => {
    deferredInstallPrompt = null;
  });

  // ── API pública ─────────────────────────────────────────────────────────
  window.gcBridge = {
    // Plataforma
    isIOS: () => isIOS,
    isStandalone: () => isStandalone(),
    isInAppBrowser: () => inAppBrowser,
    timeZone: () => {
      try {
        return Intl.DateTimeFormat().resolvedOptions().timeZone || 'UTC';
      } catch (_) {
        return 'UTC';
      }
    },

    // Instalación
    canPromptInstall: () => deferredInstallPrompt !== null,
    promptInstall: async () => {
      if (!deferredInstallPrompt) return false;
      deferredInstallPrompt.prompt();
      const choice = await deferredInstallPrompt.userChoice;
      deferredInstallPrompt = null;
      return choice && choice.outcome === 'accepted';
    },

    // Navegación desde notificaciones
    setNavigateHandler: (fn) => {
      navigateHandler = fn;
      if (pendingNavigate) {
        const url = pendingNavigate;
        pendingNavigate = null;
        fn(url);
      }
    },
    consumeLaunchPath: () => {
      // Si la app se abrió desde una notificación con ?gc_nav=/ruta
      const params = new URLSearchParams(window.location.search);
      const nav = params.get('gc_nav');
      return nav || '';
    },

    // Notificaciones
    notificationSupport: () => {
      // En iOS, las notificaciones web solo existen si la app está
      // instalada en la pantalla de inicio (iOS 16.4+).
      if (!('Notification' in window)) {
        return isIOS && !isStandalone() ? 'ios-needs-install' : 'unsupported';
      }
      if (!('serviceWorker' in navigator)) return 'unsupported';
      return 'supported';
    },
    notificationPermission: () =>
      'Notification' in window ? Notification.permission : 'unsupported',
    requestNotificationPermission: async () => {
      if (!('Notification' in window)) return 'unsupported';
      try {
        return await Notification.requestPermission();
      } catch (_) {
        return 'denied';
      }
    },
    showNotification: async (title, body, tag, url) => {
      if (!('Notification' in window) || Notification.permission !== 'granted') {
        return false;
      }
      const reg = await getRegistration();
      if (!reg) return false;
      await reg.showNotification(title, {
        body: body,
        tag: tag || undefined,
        icon: 'icons/Icon-192.png',
        badge: 'icons/Icon-maskable-192.png',
        data: { url: url || '/' },
      });
      return true;
    },

    // Web Push: devuelve la suscripción como JSON (o '' si falla)
    pushSubscribe: async (vapidPublicKey) => {
      if (!('PushManager' in window)) return '';
      const reg = await getRegistration();
      if (!reg || !reg.pushManager) return '';
      try {
        let sub = await reg.pushManager.getSubscription();
        if (!sub) {
          sub = await reg.pushManager.subscribe({
            userVisibleOnly: true,
            applicationServerKey: b64urlToBytes(vapidPublicKey),
          });
        }
        return JSON.stringify(sub.toJSON());
      } catch (e) {
        console.warn('[gcBridge] push subscribe failed', e);
        return '';
      }
    },
    // Cancela la suscripción y devuelve el endpoint cancelado (o '')
    pushUnsubscribe: async () => {
      const reg = await getRegistration();
      if (!reg || !reg.pushManager) return '';
      try {
        const sub = await reg.pushManager.getSubscription();
        if (!sub) return '';
        const endpoint = sub.endpoint;
        await sub.unsubscribe();
        return endpoint;
      } catch (_) {
        return '';
      }
    },

    // Passkeys (Face ID / huella / PIN del dispositivo)
    passkeyAvailable: async () => {
      try {
        if (!window.PublicKeyCredential) return false;
        return await PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable();
      } catch (_) {
        return false;
      }
    },
    passkeyRegister: async (userId, userName, displayName) => {
      try {
        const cred = await navigator.credentials.create({
          publicKey: {
            challenge: randomChallenge(),
            rp: { name: 'GYMLAB', id: window.location.hostname },
            user: {
              id: new TextEncoder().encode(userId).slice(0, 64),
              name: userName || 'usuario',
              displayName: displayName || userName || 'Usuario',
            },
            pubKeyCredParams: [
              { type: 'public-key', alg: -7 },
              { type: 'public-key', alg: -257 },
            ],
            authenticatorSelection: {
              authenticatorAttachment: 'platform',
              userVerification: 'required',
              residentKey: 'preferred',
            },
            timeout: 60000,
            attestation: 'none',
          },
        });
        return cred ? bytesToB64url(cred.rawId) : '';
      } catch (e) {
        console.warn('[gcBridge] passkey register failed', e);
        return '';
      }
    },
    passkeyVerify: async (credentialId) => {
      try {
        const assertion = await navigator.credentials.get({
          publicKey: {
            challenge: randomChallenge(),
            rpId: window.location.hostname,
            allowCredentials: [
              {
                type: 'public-key',
                id: b64urlToBytes(credentialId),
                transports: ['internal', 'hybrid'],
              },
            ],
            userVerification: 'required',
            timeout: 60000,
          },
        });
        if (!assertion) return false;
        // Byte 32 de authenticatorData = flags. Bit 0x04 = User Verified.
        const authData = new Uint8Array(assertion.response.authenticatorData);
        return authData.length > 32 && (authData[32] & 0x04) !== 0;
      } catch (e) {
        console.warn('[gcBridge] passkey verify failed', e);
        return false;
      }
    },

    // Descarga de archivos generados en la app
    download: (fileName, base64Data, mimeType) => {
      const raw = atob(base64Data);
      const bytes = new Uint8Array(raw.length);
      for (let i = 0; i < raw.length; i++) bytes[i] = raw.charCodeAt(i);
      const blob = new Blob([bytes], { type: mimeType || 'application/octet-stream' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = fileName;
      document.body.appendChild(a);
      a.click();
      a.remove();
      setTimeout(() => URL.revokeObjectURL(url), 10000);
    },

    // Copiar texto. Debe llamarse dentro del toque del usuario.
    // 1º execCommand (síncrono: funciona en iPhone y aunque el permiso de
    // portapapeles esté bloqueado); 2º Clipboard API.
    // Devuelve true si se copió.
    copyText: async (text) => {
      let ok = false;
      try {
        const ta = document.createElement('textarea');
        ta.value = text;
        ta.setAttribute('readonly', '');
        ta.style.cssText = 'position:fixed;top:0;left:0;opacity:0;font-size:16px';
        document.body.appendChild(ta);
        ta.focus();
        ta.select();
        ta.setSelectionRange(0, text.length);
        ok = document.execCommand('copy');
        ta.remove();
      } catch (_) { ok = false; }
      if (ok) return true;
      try {
        await navigator.clipboard.writeText(text);
        return true;
      } catch (_) {
        return false;
      }
    },

    // Hoja de compartir del teléfono; si no existe, abre WhatsApp.
    // Devuelve 'shared', 'cancelled' o 'whatsapp'.
    shareText: async (text) => {
      if (navigator.share) {
        try {
          await navigator.share({ text });
          return 'shared';
        } catch (e) {
          if (e && e.name === 'AbortError') return 'cancelled';
        }
      }
      window.open('https://wa.me/?text=' + encodeURIComponent(text), '_blank', 'noopener');
      return 'whatsapp';
    },

    // Abrir un enlace (p. ej. comprobante firmado) en otra pestaña
    openUrl: (url) => {
      if (typeof url === 'string' && url.startsWith('https://')) {
        // En la PWA instalada del iPhone, window.open con noopener puede
        // fallar en silencio: se usa un enlace real como respaldo.
        const w = window.open(url, '_blank');
        if (!w) {
          const a = document.createElement('a');
          a.href = url;
          a.target = '_blank';
          a.rel = 'noopener';
          document.body.appendChild(a);
          a.click();
          a.remove();
        } else {
          try { w.opener = null; } catch (_) {}
        }
      }
    },

    // Compartir un archivo (p. ej. imagen del resumen) con la hoja nativa
    // del teléfono. Si el navegador no soporta compartir archivos, lo
    // descarga. Devuelve 'shared', 'downloaded' o 'cancelled'.
    shareFile: async (fileName, base64Data, mimeType, text) => {
      const raw = atob(base64Data);
      const bytes = new Uint8Array(raw.length);
      for (let i = 0; i < raw.length; i++) bytes[i] = raw.charCodeAt(i);
      const type = mimeType || 'application/octet-stream';
      try {
        const file = new File([bytes], fileName, { type });
        if (navigator.canShare && navigator.canShare({ files: [file] })) {
          await navigator.share({ files: [file], text: text || undefined });
          return 'shared';
        }
      } catch (e) {
        if (e && e.name === 'AbortError') return 'cancelled';
        console.warn('[gcBridge] share failed', e);
      }
      window.gcBridge.download(fileName, base64Data, type);
      return 'downloaded';
    },
  };
})();
