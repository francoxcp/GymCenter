import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Operación de escritura pendiente de enviar a Supabase.
class PendingOp {
  final String id;
  final String userId;
  final String type; // insert | upsert | delete
  final String table;
  final dynamic values; // Map o List<Map> (insert/upsert)
  final String? onConflict;
  final Map<String, dynamic>? match; // filtros eq() para delete
  final DateTime createdAt;

  PendingOp({
    required this.id,
    required this.userId,
    required this.type,
    required this.table,
    this.values,
    this.onConflict,
    this.match,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'type': type,
        'table': table,
        'values': values,
        'onConflict': onConflict,
        'match': match,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PendingOp.fromJson(Map<String, dynamic> j) => PendingOp(
        id: j['id'] as String,
        userId: j['userId'] as String,
        type: j['type'] as String,
        table: j['table'] as String,
        values: j['values'],
        onConflict: j['onConflict'] as String?,
        match: (j['match'] as Map?)?.cast<String, dynamic>(),
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? ''),
      );
}

/// Cola de escrituras sin conexión.
///
/// Las pantallas de entrenamiento escriben a través de esta cola: si hay
/// internet la operación se ejecuta al instante; si falla por red, se guarda
/// en el dispositivo y se reintenta automáticamente (cada 30 s, al volver a
/// la app y al abrirla). Así se puede entrenar en el gimnasio sin señal y no
/// se pierde ninguna serie.
///
/// Solo encola fallos de **red**. Si Supabase rechaza la operación
/// (permisos, datos inválidos) el error se propaga normalmente.
class OfflineSyncQueue extends ChangeNotifier with WidgetsBindingObserver {
  OfflineSyncQueue._();
  static final OfflineSyncQueue instance = OfflineSyncQueue._();

  static const _storageKey = 'offline_sync_queue_v1';
  static const _maxAge = Duration(days: 30);

  final List<PendingOp> _ops = [];
  bool _initialized = false;
  bool _flushing = false;
  Timer? _timer;
  int _counter = 0;

  SupabaseClient get _client => Supabase.instance.client;

  /// Operaciones pendientes del usuario actual.
  int get pendingCount {
    final uid = _client.auth.currentUser?.id;
    return _ops.where((o) => o.userId == uid).length;
  }

  bool get hasPending => pendingCount > 0;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await _load();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_ops.isNotEmpty) flush();
    });
    flush();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _ops.isNotEmpty) flush();
  }

  /// ¿El error se debe a falta de conexión (y no a un rechazo del servidor)?
  static bool isNetworkError(Object e) {
    if (e is PostgrestException) {
      final msg = e.message.toLowerCase();
      return e.code == null &&
          (msg.contains('fetch') ||
              msg.contains('network') ||
              msg.contains('socket') ||
              msg.contains('connection'));
    }
    if (e is AuthRetryableFetchException) return true;
    if (e is AuthException) return false;
    if (e is StorageException) return false;
    // ClientException (http), SocketException, TimeoutException, etc.
    return true;
  }

  // ── API pública ─────────────────────────────────────────────────────────

  Future<void> insert(String table, dynamic values) => _run(PendingOp(
        id: _newId(),
        userId: _uid(),
        type: 'insert',
        table: table,
        values: values,
      ));

  Future<void> upsert(String table, Map<String, dynamic> values,
          {String? onConflict}) =>
      _run(PendingOp(
        id: _newId(),
        userId: _uid(),
        type: 'upsert',
        table: table,
        values: values,
        onConflict: onConflict,
      ));

  Future<void> delete(String table, Map<String, dynamic> match) =>
      _run(PendingOp(
        id: _newId(),
        userId: _uid(),
        type: 'delete',
        table: table,
        match: match,
      ));

  /// Reintenta las operaciones pendientes del usuario actual, en orden.
  Future<void> flush() async {
    if (_flushing) return;
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    _flushing = true;
    var changed = false;
    try {
      final now = DateTime.now();
      for (final op in List<PendingOp>.from(_ops)) {
        if (op.userId != uid) continue;
        if (now.difference(op.createdAt) > _maxAge) {
          _ops.remove(op);
          changed = true;
          continue;
        }
        try {
          await _execute(op);
          _ops.remove(op);
          changed = true;
        } catch (e) {
          if (isNetworkError(e)) break; // sigue sin red: reintentar luego
          // Rechazada por el servidor: descartar para no bloquear la cola.
          debugPrint('OfflineSyncQueue: operación descartada ($e)');
          _ops.remove(op);
          changed = true;
        }
      }
    } finally {
      _flushing = false;
      if (changed) {
        await _save();
        notifyListeners();
      }
    }
  }

  // ── Internos ────────────────────────────────────────────────────────────

  String _uid() => _client.auth.currentUser?.id ?? '';

  String _newId() =>
      '${DateTime.now().microsecondsSinceEpoch}_${_counter++}';

  Future<void> _run(PendingOp op) async {
    // Si ya hay pendientes, encolar detrás para respetar el orden.
    if (_ops.any((o) => o.userId == op.userId)) {
      await _enqueue(op);
      unawaited(flush());
      return;
    }
    try {
      await _execute(op);
    } catch (e) {
      if (!isNetworkError(e)) rethrow;
      await _enqueue(op);
    }
  }

  Future<void> _execute(PendingOp op) async {
    switch (op.type) {
      case 'insert':
        await _client.from(op.table).insert(op.values);
        break;
      case 'upsert':
        await _client
            .from(op.table)
            .upsert(op.values as Map<String, dynamic>,
                onConflict: op.onConflict);
        break;
      case 'delete':
        var q = _client.from(op.table).delete();
        op.match?.forEach((k, v) => q = q.eq(k, v as Object));
        await q;
        break;
    }
  }

  Future<void> _enqueue(PendingOp op) async {
    _ops.add(op);
    await _save();
    notifyListeners();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null) return;
      final list = jsonDecode(raw) as List;
      _ops
        ..clear()
        ..addAll(list.map(
            (e) => PendingOp.fromJson((e as Map).cast<String, dynamic>())));
    } catch (e) {
      debugPrint('OfflineSyncQueue: no se pudo leer la cola: $e');
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _storageKey, jsonEncode(_ops.map((o) => o.toJson()).toList()));
    } catch (e) {
      debugPrint('OfflineSyncQueue: no se pudo guardar la cola: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
