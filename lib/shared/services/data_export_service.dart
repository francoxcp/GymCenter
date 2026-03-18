import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service to export all user data as a JSON file for GDPR compliance.
class DataExportService {
  final _supabase = Supabase.instance.client;

  Future<void> exportUserData(BuildContext context) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    // Recopilar todos los datos del usuario en paralelo
    final results = await Future.wait([
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
    ]);

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

    // Guardar como archivo JSON temporal
    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/chamos_fitness_data_$timestamp.json');
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(exportData),
    );

    // Compartir el archivo
    if (context.mounted) {
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Mis datos - Chamos Fitness',
      );
    }
  }
}
