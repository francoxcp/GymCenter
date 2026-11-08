import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

@JS('gcBridge')
external _GcBridge? get _bridge;

extension type _GcBridge._(JSObject _) implements JSObject {
  external bool isIOS();
  external bool isStandalone();
  external String timeZone();
  external bool canPromptInstall();
  external JSPromise<JSBoolean> promptInstall();
  external void setNavigateHandler(JSFunction handler);
  external String consumeLaunchPath();
  external String notificationSupport();
  external String notificationPermission();
  external JSPromise<JSString> requestNotificationPermission();
  external JSPromise<JSBoolean> showNotification(
      String title, String body, String tag, String url);
  external JSPromise<JSString> pushSubscribe(String vapidPublicKey);
  external JSPromise<JSString> pushUnsubscribe();
  external JSPromise<JSBoolean> passkeyAvailable();
  external JSPromise<JSString> passkeyRegister(
      String userId, String userName, String displayName);
  external JSPromise<JSBoolean> passkeyVerify(String credentialId);
  external void download(String fileName, String base64Data, String mimeType);
}

/// Implementación web: delega en `window.gcBridge` (web/gc_bridge.js).
class WebBridge {
  WebBridge._();

  static bool get isAvailable => _bridge != null;
  static bool get isIOS => _bridge?.isIOS() ?? false;
  static bool get isStandalone => _bridge?.isStandalone() ?? false;
  static String get timeZone => _bridge?.timeZone() ?? 'UTC';

  static bool get canPromptInstall => _bridge?.canPromptInstall() ?? false;
  static Future<bool> promptInstall() async {
    final b = _bridge;
    if (b == null) return false;
    try {
      return (await b.promptInstall().toDart).toDart;
    } catch (_) {
      return false;
    }
  }

  static void setNavigateHandler(void Function(String path) handler) {
    _bridge?.setNavigateHandler(((JSString path) {
      handler(path.toDart);
    }).toJS);
  }

  static String consumeLaunchPath() => _bridge?.consumeLaunchPath() ?? '';

  static String get notificationSupport =>
      _bridge?.notificationSupport() ?? 'unsupported';

  static String get notificationPermission =>
      _bridge?.notificationPermission() ?? 'unsupported';

  static Future<String> requestNotificationPermission() async {
    final b = _bridge;
    if (b == null) return 'unsupported';
    try {
      return (await b.requestNotificationPermission().toDart).toDart;
    } catch (_) {
      return 'denied';
    }
  }

  static Future<bool> showNotification({
    required String title,
    required String body,
    String tag = '',
    String url = '/',
  }) async {
    final b = _bridge;
    if (b == null) return false;
    try {
      return (await b.showNotification(title, body, tag, url).toDart).toDart;
    } catch (_) {
      return false;
    }
  }

  static Future<String> pushSubscribe(String vapidPublicKey) async {
    final b = _bridge;
    if (b == null || vapidPublicKey.isEmpty) return '';
    try {
      return (await b.pushSubscribe(vapidPublicKey).toDart).toDart;
    } catch (_) {
      return '';
    }
  }

  static Future<String> pushUnsubscribe() async {
    final b = _bridge;
    if (b == null) return '';
    try {
      return (await b.pushUnsubscribe().toDart).toDart;
    } catch (_) {
      return '';
    }
  }

  static Future<bool> passkeyAvailable() async {
    final b = _bridge;
    if (b == null) return false;
    try {
      return (await b.passkeyAvailable().toDart).toDart;
    } catch (_) {
      return false;
    }
  }

  static Future<String> passkeyRegister({
    required String userId,
    required String userName,
    required String displayName,
  }) async {
    final b = _bridge;
    if (b == null) return '';
    try {
      return (await b.passkeyRegister(userId, userName, displayName).toDart)
          .toDart;
    } catch (_) {
      return '';
    }
  }

  static Future<bool> passkeyVerify(String credentialId) async {
    final b = _bridge;
    if (b == null || credentialId.isEmpty) return false;
    try {
      return (await b.passkeyVerify(credentialId).toDart).toDart;
    } catch (_) {
      return false;
    }
  }

  static void download({
    required String fileName,
    required Uint8List bytes,
    String mimeType = 'application/octet-stream',
  }) {
    _bridge?.download(fileName, base64Encode(bytes), mimeType);
  }
}
