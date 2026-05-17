import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    final encryptedBytes = _encryptJson(jsonStr, password);

    // Guardar el archivo cifrado en el directorio temporal
    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/chamos_fitness_$timestamp.enc');
    await file.writeAsBytes(encryptedBytes);

    // Compartir el archivo cifrado
    if (context.mounted) {
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/octet-stream')],
        subject: 'Mis datos - Chamos Fitness (cifrados)',
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
              backgroundColor: const Color(0xFF1E1E1E),
              title: const Text(
                'Proteger exportación',
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Crea una contraseña para cifrar tu archivo de datos. '
                    'La necesitarás para abrirlo después.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  StatefulBuilder(
                    builder: (ctx2, setFieldState) => TextField(
                      controller: controller,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Contraseña de cifrado',
                        labelStyle: const TextStyle(color: Colors.white54),
                        errorText: errorText,
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.orange),
                        ),
                        errorBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        focusedErrorBorder: const OutlineInputBorder(
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
                  child: const Text('Cancelar',
                      style: TextStyle(color: Colors.white54)),
                ),
                TextButton(
                  onPressed: () {
                    if (controller.text.length < 8) {
                      setState(() => errorText = 'Mínimo 8 caracteres');
                      return;
                    }
                    Navigator.pop(ctx, controller.text);
                  },
                  child: const Text('Exportar',
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

  /// Cifra [jsonStr] con AES-256-CBC usando una clave derivada de [password].
  ///
  /// Formato del archivo resultante:
  ///   [16 bytes: salt] + [16 bytes: IV] + [N bytes: ciphertext]
  ///
  /// La clave se deriva como SHA-256(UTF-8(password) + salt).
  static Uint8List _encryptJson(String jsonStr, String password) {
    final random = Random.secure();
    final salt = Uint8List.fromList(
      List.generate(16, (_) => random.nextInt(256)),
    );

    // Derivar clave de 256 bits: SHA-256(password bytes ++ salt)
    final keyBytes = sha256.convert([...utf8.encode(password), ...salt]).bytes;
    final key = enc.Key(Uint8List.fromList(keyBytes));
    final iv = enc.IV.fromSecureRandom(16);

    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(jsonStr, iv: iv);

    // Concatenar: salt (16) + IV (16) + ciphertext
    return Uint8List.fromList([...salt, ...iv.bytes, ...encrypted.bytes]);
  }
}
