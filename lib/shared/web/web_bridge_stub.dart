import 'dart:typed_data';

/// Implementación vacía para plataformas no web (Android, iOS, tests).
class WebBridge {
  WebBridge._();

  static bool get isAvailable => false;
  static bool get isIOS => false;
  static bool get isStandalone => false;
  static bool get isInAppBrowser => false;
  static String get timeZone => 'UTC';

  static bool get canPromptInstall => false;
  static Future<bool> promptInstall() async => false;

  static void setNavigateHandler(void Function(String path) handler) {}
  static String consumeLaunchPath() => '';

  /// 'supported' | 'unsupported' | 'ios-needs-install'
  static String get notificationSupport => 'unsupported';

  /// 'granted' | 'denied' | 'default' | 'unsupported'
  static String get notificationPermission => 'unsupported';
  static Future<String> requestNotificationPermission() async =>
      'unsupported';
  static Future<bool> showNotification({
    required String title,
    required String body,
    String tag = '',
    String url = '/',
  }) async =>
      false;

  static Future<String> pushSubscribe(String vapidPublicKey) async => '';
  static Future<String> pushUnsubscribe() async => '';

  static Future<bool> passkeyAvailable() async => false;
  static Future<String> passkeyRegister({
    required String userId,
    required String userName,
    required String displayName,
  }) async =>
      '';
  static Future<bool> passkeyVerify(String credentialId) async => false;

  static void download({
    required String fileName,
    required Uint8List bytes,
    String mimeType = 'application/octet-stream',
  }) {}

  static Future<String> shareFile({
    required String fileName,
    required Uint8List bytes,
    String mimeType = 'application/octet-stream',
    String text = '',
  }) async =>
      '';

  static void openUrl(String url) {}

  static Future<bool> copyText(String text) async => false;
  static Future<String> shareText(String text) async => '';
}
