import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../web/web_bridge.dart';
import '../../core/theme/app_theme.dart';

/// Service to export all user data as an AES-256 encrypted file for GDPR compliance.
/// The exported file is not human-readable without the password set at export time.
class DataExportService {
  final _supabase = Supabase.instance.client;

  Future<void> exportUserData(BuildContext context) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    // Pedir contraseña antes de tocar los datos
    if (!context.mounted) return;
    final password = await _askEncryptionPassword(context);
    if (password == null) return; // Usuario canceló

    // Recopilar todos los datos del usuario en paralelo
    final queries = <Future<dynamic>>[
      _supabase.from('users').select().eq('id', userId).maybeSingle(),
      _supabase
          .from('workout_sessions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false),
      _supabase
          .from('body_measurements')
          .select()
          .eq('user_id', userId)
          .order('measurement_date', ascending: false),
      _supabase
          .from('exercise_set_logs')
          .select()
          .eq('user_id', userId)
          .order('logged_at', ascending: false),
      _supabase
          .from('user_achievements')
          .select()
          .eq('user_id', userId)
          .order('unlocked_at', ascending: false),
      _supabase.from('workout_progress').select().eq('user_id', userId),
      _supabase
          .from('user_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle(),
    ];

    final results = await Future.wait(
      queries.map((q) => q.catchError((_) => null)),
    );

    final exportData = {
      'exported_at': DateTime.now().toIso8601String(),
      'profile': results[0],
      'workout_sessions': results[1],
      'body_measurements': results[2],
      'exercise_set_logs': results[3],
      'achievements': results[4],
      'workout_progress': results[5],
      'preferences': results[6],
    };

    // Cifrar el JSON con AES-256 antes de escribir al disco
    final jsonStr = const JsonEncoder.withIndent('  ').convert(exportData);
    final encryptedBytes = encryptJson(jsonStr, password);

    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // Web: descargar el archivo directamente desde el navegador
    if (kIsWeb) {
      WebBridge.download(
        fileName: 'chamos_fitness_$timestamp.enc',
        bytes: encryptedBytes,
      );
      return;
    }

    // Guardar el archivo cifrado en el directorio temporal
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/chamos_fitness_$timestamp.enc');
    await file.writeAsBytes(encryptedBytes);

    // Compartir el archivo cifrado
    if (context.mounted) {
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/octet-stream')],
        subject: 'Mis datos - GYMLAB (cifrados)',
      );
    }

    // Eliminar el archivo temporal
    try {
      await file.delete();
    } catch (_) {}
  }

  /// Muestra un diálogo para crear la contraseña de cifrado.
  /// Devuelve la contraseña o null si el usuario canceló.
  Future<String?> _askEncryptionPassword(BuildContext context) async {
    final controller = TextEditingController();
    try {
      return await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setState) {
            String? errorText;
            return AlertDialog(
              backgroundColor: AppColors.cardBackground,
              title: Text(
                'Proteger exportación',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Crea una contraseña para cifrar tu archivo de datos. '
                    'La necesitarás para abrirlo después.',
                    style: TextStyle(color: AppColors.textPrimary.withValues(alpha: 0.7), fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  StatefulBuilder(
                    builder: (ctx2, setFieldState) => TextField(
                      controller: controller,
                      obscureText: true,
                      style: TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Contraseña de cifrado',
                        labelStyle: TextStyle(color: AppColors.textPrimary.withValues(alpha: 0.54)),
                        errorText: errorText,
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.textPrimary.withValues(alpha: 0.24)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.orange),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red),
                        ),
                      ),
                      onChanged: (_) {
                        if (errorText != null) {
                          setFieldState(() => errorText = null);
                        }
                      },
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancelar',
                      style: TextStyle(color: AppColors.textPrimary.withValues(alpha: 0.54))),
                ),
                TextButton(
                  onPressed: () {
                    if (controller.text.length < 8) {
                      setState(() => errorText = 'Mínimo 8 caracteres');
                      return;
                    }
                    Navigator.pop(ctx, controller.text);
                  },
                  child: Text('Exportar',
                      style: TextStyle(color: Colors.orange)),
                ),
              ],
            );
          },
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  // Formato v2 del archivo exportado:
  //   "GCX2" (4 bytes) + salt (16) + IV (16) + ciphertext AES-256-CBC + HMAC-SHA256 (32)
  // Claves: PBKDF2-HMAC-SHA256(contraseña, salt, 60 000 iteraciones) → 64 bytes
  //   (32 para cifrar + 32 para el HMAC). El HMAC cubre todo lo anterior
  //   (encrypt-then-MAC), así se detecta cualquier modificación del archivo.
  // Antes la clave era un único SHA-256 de la contraseña (fácil de atacar por
  // fuerza bruta) y no había verificación de integridad.
  static const _magic = [0x47, 0x43, 0x58, 0x32]; // "GCX2"
  static const pbkdf2Iterations = 60000;

  /// Cifra [jsonStr] protegido con [password] (formato v2, ver arriba).
  static Uint8List encryptJson(String jsonStr, String password,
      {int iterations = pbkdf2Iterations}) {
    final random = Random.secure();
    final salt = Uint8List.fromList(List.generate(16, (_) => random.nextInt(256)));
    final keys = pbkdf2(utf8.encode(password), salt, iterations, 64);
    final encKey = enc.Key(Uint8List.fromList(keys.sublist(0, 32)));
    final macKey = keys.sublist(32, 64);
    final iv = enc.IV.fromSecureRandom(16);

    final encrypter = enc.Encrypter(enc.AES(encKey, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(jsonStr, iv: iv);

    final body = <int>[..._magic, ...salt, ...iv.bytes, ...encrypted.bytes];
    final mac = Hmac(sha256, macKey).convert(body).bytes;
    return Uint8List.fromList([...body, ...mac]);
  }

  /// Descifra un archivo v2. Lanza [FormatException] si la contraseña es
  /// incorrecta o el archivo fue modificado.
  static String decryptJson(Uint8List data, String password,
      {int iterations = pbkdf2Iterations}) {
    if (data.length < 4 + 16 + 16 + 16 + 32 ||
        !_listEquals(data.sublist(0, 4), _magic)) {
      throw const FormatException('Archivo no reconocido');
    }
    final salt = data.sublist(4, 20);
    final ivBytes = data.sublist(20, 36);
    final body = data.sublist(0, data.length - 32);
    final mac = data.sublist(data.length - 32);
    final keys = pbkdf2(utf8.encode(password), salt, iterations, 64);
    final expected = Hmac(sha256, keys.sublist(32, 64)).convert(body).bytes;
    if (!_listEquals(mac, expected)) {
      throw const FormatException('Contraseña incorrecta o archivo dañado');
    }
    final encrypter = enc.Encrypter(
        enc.AES(enc.Key(Uint8List.fromList(keys.sublist(0, 32))),
            mode: enc.AESMode.cbc));
    return encrypter.decrypt(
        enc.Encrypted(Uint8List.fromList(data.sublist(36, data.length - 32))),
        iv: enc.IV(Uint8List.fromList(ivBytes)));
  }

  /// PBKDF2 con HMAC-SHA256 (RFC 8018).
  static List<int> pbkdf2(
      List<int> password, List<int> salt, int iterations, int length) {
    final hmac = Hmac(sha256, password);
    final out = <int>[];
    var block = 1;
    while (out.length < length) {
      final blockBytes = [
        (block >> 24) & 0xff,
        (block >> 16) & 0xff,
        (block >> 8) & 0xff,
        block & 0xff,
      ];
      var u = hmac.convert([...salt, ...blockBytes]).bytes;
      final t = List<int>.from(u);
      for (var i = 1; i < iterations; i++) {
        u = hmac.convert(u).bytes;
        for (var k = 0; k < t.length; k++) {
          t[k] ^= u[k];
        }
      }
      out.addAll(t);
      block++;
    }
    return out.sublist(0, length);
  }

  // Comparación en tiempo constante
  static bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
