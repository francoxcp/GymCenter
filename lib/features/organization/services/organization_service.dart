import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/supabase_config.dart';
import '../models/organization.dart';

/// Acceso a Supabase para organizaciones, invitaciones y cobro.
/// La seguridad la imponen RLS y las funciones SQL
/// (database/multitenant_migration.sql).
class OrganizationService {
  OrganizationService._();

  static SupabaseClient get _db => SupabaseConfig.client;

  /// Dominio público de la app para armar los enlaces de invitación.
  static String get appOrigin {
    final base = Uri.base;
    if (base.scheme.startsWith('http') && base.host.isNotEmpty) {
      return base.origin;
    }
    return 'https://gym-nine-sand.vercel.app';
  }

  static String inviteUrl(String token) => '$appOrigin/invitacion/$token';

  // ── Mi organización ─────────────────────────────────────────────────────
  /// Datos públicos de la organización; el cobro solo si soy el dueño.
  static Future<Organization?> loadMine(String orgId, {bool withBilling = false}) async {
    final row = await _db
        .from('organizations')
        .select('id, name, kind, logo_url, status, max_members')
        .eq('id', orgId)
        .maybeSingle();
    if (row == null) return null;
    final data = Map<String, dynamic>.from(row);
    if (withBilling) {
      try {
        final b = await _db.rpc('get_my_org_billing');
        if (b is List && b.isNotEmpty) data.addAll(Map<String, dynamic>.from(b.first as Map));
      } catch (_) {}
    }
    return Organization.fromJson(data);
  }

  static Future<bool> isPlatformAdmin() async {
    try {
      final r = await _db.rpc('is_platform_admin');
      return r == true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> updateMine({String? name, String? logoUrl}) async {
    await _db.rpc('update_my_org', params: {'p_name': name, 'p_logo_url': logoUrl});
  }

  static Future<String> uploadLogo({
    required String orgId,
    required Uint8List bytes,
    required String extension,
  }) async {
    final ext = _cleanExt(extension, const ['png', 'jpg', 'jpeg', 'webp'], 'png');
    final path = '$orgId/logo-${DateTime.now().millisecondsSinceEpoch}.$ext';
    // Borrar logos anteriores (ahorra espacio del plan gratuito)
    try {
      final old = await _db.storage.from('org-logos').list(path: orgId);
      final paths = old.map((f) => '$orgId/${f.name}').toList();
      if (paths.isNotEmpty) await _db.storage.from('org-logos').remove(paths);
    } catch (_) {}
    await _db.storage.from('org-logos').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: _mime(ext), upsert: true),
        );
    return _db.storage.from('org-logos').getPublicUrl(path);
  }

  // ── Cobro ───────────────────────────────────────────────────────────────
  static Future<void> submitPayment({
    required String orgId,
    required int months,
    double? amount,
    required Uint8List bytes,
    required String extension,
  }) async {
    final ext = _cleanExt(extension, const ['png', 'jpg', 'jpeg', 'webp', 'pdf'], 'jpg');
    final path = '$orgId/${DateTime.now().millisecondsSinceEpoch}.$ext';
    await _db.storage.from('payment-receipts').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: _mime(ext)),
        );
    await _db.rpc('submit_org_payment', params: {
      'p_months': months,
      'p_amount': amount,
      'p_receipt_path': path,
    });
  }

  static Future<List<OrgPayment>> payments(String orgId) async {
    final rows = await _db
        .from('org_payments')
        .select()
        .eq('org_id', orgId)
        .order('submitted_at', ascending: false)
        .limit(24);
    return (rows as List)
        .map((r) => OrgPayment.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Enlace temporal (10 min) para ver un comprobante privado.
  static Future<String> receiptUrl(String path) =>
      _db.storage.from('payment-receipts').createSignedUrl(path, 600);

  // ── Invitaciones ────────────────────────────────────────────────────────
  /// role: 'trainer' (dueño de gimnasio) o 'user' (dueño o entrenador).
  static Future<String> createInvitation(String role) async {
    final token = await _db.rpc('create_invitation', params: {'p_role': role});
    return token as String;
  }

  /// Invitaciones vigentes de mi organización (RLS: dueño ve todas, el
  /// entrenador las suyas).
  static Future<List<InvitationRow>> activeInvitations() async {
    final rows = await _db
        .from('invitations')
        .select('token, role, uses, max_uses, views, expires_at')
        .eq('revoked', false)
        .gt('expires_at', DateTime.now().toUtc().toIso8601String())
        .order('created_at', ascending: false)
        .limit(30);
    return (rows as List)
        .map((r) => InvitationRow.fromJson(r as Map<String, dynamic>))
        .where((i) => i.uses < i.maxUses)
        .toList();
  }

  static Future<void> revokeInvitation(String token) =>
      _db.rpc('revoke_invitation', params: {'p_token': token});

  /// Cuenta una apertura del enlace (no falla si no hay conexión).
  static Future<void> trackInvitationView(String token) async {
    try {
      await _db.rpc('track_invitation_view', params: {'p_token': token});
    } catch (_) {}
  }

  /// Cuántos socios tiene la organización (para "18 de 30").
  static Future<int> memberCount(String orgId) async {
    final r = await _db
        .from('users')
        .select('id')
        .eq('org_id', orgId)
        .eq('role', 'user')
        .count(CountOption.exact);
    return r.count;
  }

  static Future<InvitationInfo?> invitationInfo(String token) async {
    final rows = await _db.rpc('invitation_info', params: {'p_token': token});
    if (rows is List && rows.isNotEmpty) {
      return InvitationInfo.fromJson(rows.first as Map<String, dynamic>);
    }
    return null;
  }

  /// Devuelve el nombre de la organización a la que se unió.
  static Future<String> acceptInvitation(String token) async {
    final r = await _db.rpc('accept_invitation', params: {'p_token': token});
    return r as String;
  }

  static const _kPendingInvite = 'pending_invitation_token';

  /// Guarda el código mientras la persona crea su cuenta o inicia sesión.
  static const _kPendingInviteOrg = 'pending_invitation_org';

  static Future<void> savePendingInvite(String token, {String? orgName}) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kPendingInvite, token.toUpperCase());
    if (orgName != null) await p.setString(_kPendingInviteOrg, orgName);
  }

  /// Nombre del gimnasio de la invitación pendiente (para el registro).
  static Future<String?> pendingInviteOrgName() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kPendingInvite) == null ? null : p.getString(_kPendingInviteOrg);
  }

  static Future<String?> takePendingInvite() async {
    final p = await SharedPreferences.getInstance();
    final t = p.getString(_kPendingInvite);
    if (t != null) await p.remove(_kPendingInvite);
    await p.remove(_kPendingInviteOrg);
    return t;
  }

  // ── Plataforma (súper admin) ────────────────────────────────────────────
  static Future<List<OrgSummary>> platformList() async {
    final rows = await _db.rpc('platform_list_orgs');
    return (rows as List)
        .map((r) => OrgSummary.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Crea el cliente y devuelve el código de invitación para su dueño.
  static Future<String> platformCreateOrg({
    required String name,
    required String kind,
    double? monthlyFee,
    int trialDays = 14,
    String plan = 'Mensual',
    int? maxMembers,
  }) async {
    final rows = await _db.rpc('platform_create_org', params: {
      'p_name': name,
      'p_kind': kind,
      'p_monthly_fee': monthlyFee,
      'p_trial_days': trialDays,
      'p_plan': plan,
      'p_max_members': maxMembers,
    });
    return ((rows as List).first as Map<String, dynamic>)['token'] as String;
  }

  static Future<PlatformStats?> platformStats() async {
    final rows = await _db.rpc('platform_stats');
    if (rows is List && rows.isNotEmpty) {
      return PlatformStats.fromJson(rows.first as Map<String, dynamic>);
    }
    return null;
  }

  static Future<void> platformUpdateOrg(String orgId,
          {required String plan, double? monthlyFee, int? maxMembers}) =>
      _db.rpc('platform_update_org', params: {
        'p_org': orgId,
        'p_plan': plan,
        'p_monthly_fee': monthlyFee,
        'p_max_members': maxMembers,
      });

  static Future<String> platformOwnerInvite(String orgId) async {
    final token = await _db.rpc('create_invitation',
        params: {'p_role': 'admin', 'p_org': orgId});
    return token as String;
  }

  static Future<void> platformSetStatus(String orgId, String status) =>
      _db.rpc('platform_set_org_status', params: {'p_org': orgId, 'p_status': status});

  static Future<void> reviewPayment(String paymentId,
          {required bool approve, String? comment}) =>
      _db.rpc('review_org_payment', params: {
        'p_payment': paymentId,
        'p_approve': approve,
        'p_comment': comment,
      });

  // ── Utilidades ──────────────────────────────────────────────────────────
  static String _cleanExt(String ext, List<String> allowed, String fallback) {
    final e = ext.toLowerCase().replaceAll('.', '');
    return allowed.contains(e) ? (e == 'jpeg' ? 'jpg' : e) : fallback;
  }

  static String _mime(String ext) => switch (ext) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        'pdf' => 'application/pdf',
        _ => 'image/jpeg',
      };

  /// Mensaje legible para los errores de las funciones SQL.
  static String friendlyError(Object e) {
    final m = e.toString();
    if (m.contains('already_in_other_org')) {
      return 'Tu cuenta ya pertenece a otro gimnasio o entrenador.';
    }
    if (m.contains('invalid_invitation')) {
      return 'La invitación no es válida o ya venció. Pide un enlace nuevo.';
    }
    if (m.contains('comment_required')) return 'Escribe el motivo del rechazo.';
    if (m.contains('member_limit')) {
      return 'Este gimnasio alcanzó el máximo de socios de su plan. Avisa al dueño.';
    }
    if (m.contains('not_allowed')) return 'No tienes permiso para esta acción.';
    if (m.contains('payment_already_in_review')) {
      return 'Ya tienes un comprobante en revisión.';
    }
    if (m.contains('receipt')) return 'No se pudo subir el comprobante.';
    return 'Algo salió mal. Inténtalo de nuevo.';
  }
}
