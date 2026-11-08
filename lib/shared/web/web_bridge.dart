/// Acceso a funciones del navegador (PWA) desde Dart.
///
/// En web delega en `window.gcBridge` (web/gc_bridge.js) mediante
/// dart:js_interop. En Android/iOS se usa una implementación vacía, por lo
/// que es seguro importar este archivo desde cualquier plataforma.
library;

export 'web_bridge_stub.dart'
    if (dart.library.js_interop) 'web_bridge_web.dart';
