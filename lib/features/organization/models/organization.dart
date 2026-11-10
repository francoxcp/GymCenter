/// Cliente de la plataforma: un gimnasio o un entrenador independiente.
class Organization {
  final String id;
  final String name;
  final String kind; // 'gym' | 'independent'
  final String? logoUrl;
  final String status; // 'active' | 'suspended'
  final String plan;
  final double? monthlyFee;
  final DateTime? paidUntil;
  final String billingStatus; // 'pending' | 'in_review' | 'approved'
  final String? billingNote;
  /// Máximo de socios del plan (null = sin límite).
  final int? maxMembers;

  const Organization({
    required this.id,
    required this.name,
    required this.kind,
    this.logoUrl,
    this.status = 'active',
    this.plan = 'Mensual',
    this.monthlyFee,
    this.paidUntil,
    this.billingStatus = 'pending',
    this.billingNote,
    this.maxMembers,
  });

  bool get isIndependent => kind == 'independent';
  bool get isGym => kind == 'gym';
  bool get isSuspended => status == 'suspended';

  /// Etiqueta del negocio según el tipo.
  String get kindLabel => isIndependent ? 'Entrenador independiente' : 'Gimnasio';

  factory Organization.fromJson(Map<String, dynamic> j) => Organization(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        kind: j['kind'] as String? ?? 'gym',
        logoUrl: j['logo_url'] as String?,
        status: j['status'] as String? ?? 'active',
        plan: j['plan'] as String? ?? 'Mensual',
        monthlyFee: (j['monthly_fee'] as num?)?.toDouble(),
        paidUntil: _date(j['paid_until']),
        billingStatus: j['billing_status'] as String? ?? 'pending',
        billingNote: j['billing_note'] as String?,
        maxMembers: (j['max_members'] as num?)?.toInt(),
      );

  static DateTime? _date(dynamic v) =>
      v is String && v.isNotEmpty ? DateTime.tryParse(v) : null;
}

/// Estado de cobro que se muestra al dueño y al súper admin.
enum BillingState { upToDate, inReview, pending }

class Billing {
  Billing._();

  static BillingState state(Organization o) => switch (o.billingStatus) {
        'approved' => BillingState.upToDate,
        'in_review' => BillingState.inReview,
        _ => BillingState.pending,
      };

  static String label(BillingState s) => switch (s) {
        BillingState.upToDate => 'Al día',
        BillingState.inReview => 'En revisión',
        BillingState.pending => 'Pago pendiente',
      };
}

/// Comprobante de pago subido por el dueño.
class OrgPayment {
  final String id;
  final String orgId;
  final int months;
  final double? amount;
  final String receiptPath;
  final String status; // 'in_review' | 'approved' | 'rejected'
  final String? reviewComment;
  final DateTime submittedAt;
  final DateTime? periodEnd;
  /// El archivo se borró por antigüedad (el registro del pago se conserva).
  final bool receiptDeleted;

  const OrgPayment({
    this.receiptDeleted = false,
    required this.id,
    required this.orgId,
    required this.months,
    required this.amount,
    required this.receiptPath,
    required this.status,
    required this.reviewComment,
    required this.submittedAt,
    required this.periodEnd,
  });

  /// Pago registrado a mano por la plataforma (efectivo, SINPE): sin archivo.
  bool get isManual => receiptPath.startsWith('manual/');

  String get statusLabel => switch (status) {
        'approved' => 'Aprobado',
        'rejected' => 'Rechazado',
        _ => 'En revisión',
      };

  factory OrgPayment.fromJson(Map<String, dynamic> j) => OrgPayment(
        id: j['id'] as String,
        orgId: j['org_id'] as String,
        months: (j['months'] as num?)?.toInt() ?? 1,
        amount: (j['amount'] as num?)?.toDouble(),
        receiptPath: j['receipt_path'] as String? ?? '',
        status: j['status'] as String? ?? 'in_review',
        reviewComment: j['review_comment'] as String?,
        submittedAt:
            DateTime.tryParse(j['submitted_at'] as String? ?? '')?.toLocal() ??
                DateTime.now(),
        periodEnd: Organization._date(j['period_end']),
        receiptDeleted: j['receipt_deleted_at'] != null,
      );
}

/// Fila del listado de clientes del súper admin.
class OrgSummary {
  final Organization org;
  final String? ownerName;
  final String? ownerEmail;
  final int trainers;
  final int members;
  final int pendingReviews;
  final bool inTrial;
  final DateTime? createdAt;
  final DateTime? lastActivity;
  final int sessions30d;
  /// Gimnasio propio de la plataforma (plan "Interno"): no es un cliente.
  final bool isInternal;
  final String? ownerPhone;
  /// Invitación de dueño todavía usable (solo si aún no hay dueño).
  final String? inviteToken;
  final DateTime? inviteExpiresAt;

  const OrgSummary({
    this.inTrial = false,
    this.isInternal = false,
    this.ownerPhone,
    this.inviteToken,
    this.inviteExpiresAt,
    this.createdAt,
    this.lastActivity,
    this.sessions30d = 0,
    required this.org,
    required this.ownerName,
    required this.ownerEmail,
    required this.trainers,
    required this.members,
    required this.pendingReviews,
  });

  factory OrgSummary.fromJson(Map<String, dynamic> j) => OrgSummary(
        org: Organization.fromJson(j),
        ownerName: j['owner_name'] as String?,
        ownerEmail: j['owner_email'] as String?,
        trainers: (j['trainers'] as num?)?.toInt() ?? 0,
        members: (j['members'] as num?)?.toInt() ?? 0,
        pendingReviews: (j['pending_reviews'] as num?)?.toInt() ?? 0,
        inTrial: j['in_trial'] as bool? ?? false,
        createdAt: DateTime.tryParse(j['created_at'] as String? ?? '')?.toLocal(),
        lastActivity:
            DateTime.tryParse(j['last_activity'] as String? ?? '')?.toLocal(),
        sessions30d: (j['sessions_30d'] as num?)?.toInt() ?? 0,
        isInternal: j['is_internal'] as bool? ??
            (j['plan'] as String?) == 'Interno',
        ownerPhone: j['owner_phone'] as String?,
        inviteToken: j['invite_token'] as String?,
        inviteExpiresAt:
            DateTime.tryParse(j['invite_expires_at'] as String? ?? '')?.toLocal(),
      );

  bool get hasOwner => ownerName != null;

  /// Sin dueño y con una invitación vigente (falta que la acepte).
  bool get invitePending => !hasOwner && inviteToken != null;

  /// Sin dueño y sin invitación vigente: hay que generar otra.
  bool get inviteExpired => !hasOwner && inviteToken == null;

  /// Días hasta que vence lo pagado (o la prueba). Negativo = vencido.
  int? daysLeft(DateTime now) => org.paidUntil == null
      ? null
      : DateTime(org.paidUntil!.year, org.paidUntil!.month, org.paidUntil!.day)
          .difference(DateTime(now.year, now.month, now.day))
          .inDays;

  /// Activo y vence en los próximos 7 días (incluye hoy).
  bool expiringSoon(DateTime now) {
    final d = daysLeft(now);
    return !org.isSuspended && !isInternal && d != null && d >= 0 && d <= 7;
  }

  /// Estado principal del cliente, con prioridad para lo que pide acción.
  ClientState state(DateTime now) {
    if (isInternal) return ClientState.internal;
    if (org.isSuspended) return ClientState.suspended;
    if (!hasOwner) return ClientState.noOwner;
    if (pendingReviews > 0) return ClientState.review;
    if (Billing.state(org) == BillingState.pending) return ClientState.pending;
    if (inTrial) return ClientState.trial;
    return ClientState.upToDate;
  }

  /// Días desde el último entreno de cualquier socio (null = nunca).
  int? daysSinceActivity(DateTime now) => lastActivity == null
      ? null
      : DateTime(now.year, now.month, now.day)
          .difference(DateTime(
              lastActivity!.year, lastActivity!.month, lastActivity!.day))
          .inDays;
}

/// Estado de un cliente en la lista de la plataforma.
enum ClientState { review, pending, noOwner, trial, upToDate, suspended, internal }

extension ClientStateX on ClientState {
  String get label => switch (this) {
        ClientState.review => 'Comprobante por revisar',
        ClientState.pending => 'Pago pendiente',
        ClientState.noOwner => 'Invitación sin aceptar',
        ClientState.trial => 'En prueba',
        ClientState.upToDate => 'Al día',
        ClientState.suspended => 'Suspendido',
        ClientState.internal => 'Interno',
      };
}

/// Filtros de la lista de clientes de la plataforma (los internos no cuentan).
enum OrgFilter { all, review, pending, noOwner, expiring, trial, inactive, suspended }

extension OrgFilterX on OrgFilter {
  String get label => switch (this) {
        OrgFilter.all => 'Todos',
        OrgFilter.review => 'Por revisar',
        OrgFilter.pending => 'Pago pendiente',
        OrgFilter.noOwner => 'Sin dueño',
        OrgFilter.expiring => 'Vencen en 7 días',
        OrgFilter.trial => 'En prueba',
        OrgFilter.inactive => 'Sin uso 14 días',
        OrgFilter.suspended => 'Suspendidos',
      };

  bool matches(OrgSummary s, DateTime now) {
    if (s.isInternal) return false;
    final active = !s.org.isSuspended;
    return switch (this) {
      OrgFilter.all => true,
      OrgFilter.review => s.pendingReviews > 0,
      OrgFilter.pending =>
        active && Billing.state(s.org) == BillingState.pending,
      OrgFilter.noOwner => active && !s.hasOwner,
      OrgFilter.expiring => s.expiringSoon(now),
      OrgFilter.trial => active && s.inTrial,
      OrgFilter.inactive =>
        active && s.hasOwner && (s.daysSinceActivity(now) ?? 999) >= 14,
      OrgFilter.suspended => s.org.isSuspended,
    };
  }
}

/// Algo que la plataforma debería atender hoy.
enum TaskKind { review, noOwner, pending, expiring, inactive }

class PlatformTask {
  final TaskKind kind;
  final OrgSummary client;
  final String title;
  final String detail;
  const PlatformTask(this.kind, this.client, this.title, this.detail);
}

/// "Para atender hoy": una tarea por cliente (la más urgente), ordenadas
/// por urgencia. Los internos y suspendidos no generan tareas (salvo un
/// comprobante por revisar).
List<PlatformTask> platformTasks(List<OrgSummary> clients, DateTime now) {
  String fmt(DateTime d) {
    const m = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep',
      'oct', 'nov', 'dic'];
    return '${d.day} ${m[d.month - 1]}';
  }

  final tasks = <PlatformTask>[];
  for (final c in clients) {
    if (c.isInternal) continue;
    if (c.pendingReviews > 0) {
      tasks.add(PlatformTask(TaskKind.review, c, c.org.name,
          c.pendingReviews == 1
              ? 'Subió un comprobante de pago'
              : 'Subió ${c.pendingReviews} comprobantes de pago'));
      continue;
    }
    if (c.org.isSuspended) continue;
    if (!c.hasOwner) {
      tasks.add(PlatformTask(TaskKind.noOwner, c, c.org.name,
          c.invitePending
              ? 'No ha aceptado la invitación (vence el ${fmt(c.inviteExpiresAt!)})'
              : 'La invitación venció: envía una nueva'));
      continue;
    }
    if (Billing.state(c.org) == BillingState.pending) {
      tasks.add(PlatformTask(TaskKind.pending, c, c.org.name,
          'Pago pendiente${c.org.paidUntil != null ? ' desde el ${fmt(c.org.paidUntil!)}' : ''}'));
      continue;
    }
    if (c.expiringSoon(now)) {
      final d = c.daysLeft(now)!;
      final when = d == 0 ? 'hoy' : d == 1 ? 'mañana' : 'en $d días';
      tasks.add(PlatformTask(TaskKind.expiring, c, c.org.name,
          '${c.inTrial ? 'La prueba' : 'La suscripción'} vence $when'));
      continue;
    }
    if ((c.daysSinceActivity(now) ?? 999) >= 14) {
      final d = c.daysSinceActivity(now);
      tasks.add(PlatformTask(TaskKind.inactive, c, c.org.name,
          d == null ? 'Aún no hay entrenos' : 'Sin entrenos hace $d días'));
    }
  }
  tasks.sort((a, b) => a.kind.index.compareTo(b.kind.index));
  return tasks;
}

/// Persona del equipo de un cliente (dueño o entrenador).
class TeamMember {
  final String name;
  final String role; // 'admin' | 'trainer'
  final String? email;
  final String? phone;
  final int members;

  const TeamMember({
    required this.name,
    required this.role,
    this.email,
    this.phone,
    this.members = 0,
  });

  factory TeamMember.fromJson(Map<String, dynamic> j) => TeamMember(
        name: j['name'] as String? ?? '',
        role: j['role'] as String? ?? 'trainer',
        email: j['email'] as String?,
        phone: j['phone'] as String?,
        members: (j['members'] as num?)?.toInt() ?? 0,
      );
}

/// Datos públicos de una invitación (antes de iniciar sesión).
class InvitationInfo {
  final String orgName;
  final String? orgLogo;
  final String orgKind;
  final String role;
  final bool valid;

  const InvitationInfo({
    required this.orgName,
    required this.orgLogo,
    required this.orgKind,
    required this.role,
    required this.valid,
  });

  String get roleLabel => switch (role) {
        'admin' => orgKind == 'independent' ? 'entrenador' : 'dueño',
        'trainer' => 'entrenador',
        _ => 'socio',
      };

  factory InvitationInfo.fromJson(Map<String, dynamic> j) => InvitationInfo(
        orgName: j['org_name'] as String? ?? '',
        orgLogo: j['org_logo'] as String?,
        orgKind: j['org_kind'] as String? ?? 'gym',
        role: j['role'] as String? ?? 'user',
        valid: j['valid'] as bool? ?? false,
      );
}

/// Invitación generada por el dueño o un entrenador.
class InvitationRow {
  final String token;
  final String role;
  final int uses;
  final int maxUses;
  final int views;
  final DateTime expiresAt;

  const InvitationRow({
    required this.token,
    required this.role,
    required this.uses,
    required this.maxUses,
    required this.views,
    required this.expiresAt,
  });

  String get roleLabel => switch (role) {
        'trainer' => 'Entrenador',
        'admin' => 'Dueño',
        _ => 'Socios',
      };

  /// Personas que abrieron el enlace y todavía no crearon su cuenta
  /// (aproximado: aperturas menos registros).
  int get pendingSignups => (views - uses).clamp(0, 9999);

  factory InvitationRow.fromJson(Map<String, dynamic> j) => InvitationRow(
        token: j['token'] as String,
        role: j['role'] as String? ?? 'user',
        uses: (j['uses'] as num?)?.toInt() ?? 0,
        maxUses: (j['max_uses'] as num?)?.toInt() ?? 1,
        views: (j['views'] as num?)?.toInt() ?? 0,
        expiresAt: DateTime.tryParse(j['expires_at'] as String? ?? '')?.toLocal() ??
            DateTime.now(),
      );
}

/// Resumen de ingresos de la plataforma.
class PlatformStats {
  final double collectedThisMonth;
  final double collectedLastMonth;
  final double expectedMonthly;
  final int activeOrgs;
  final int inTrial;
  final int expiring7d;
  final int pending;
  final int suspended;
  final int totalMembers;

  const PlatformStats({
    required this.collectedThisMonth,
    required this.collectedLastMonth,
    required this.expectedMonthly,
    required this.activeOrgs,
    required this.inTrial,
    required this.expiring7d,
    required this.pending,
    required this.suspended,
    required this.totalMembers,
  });

  factory PlatformStats.fromJson(Map<String, dynamic> j) {
    double d(String k) => (j[k] as num?)?.toDouble() ?? 0;
    int i(String k) => (j[k] as num?)?.toInt() ?? 0;
    return PlatformStats(
      collectedThisMonth: d('collected_this_month'),
      collectedLastMonth: d('collected_last_month'),
      expectedMonthly: d('expected_monthly'),
      activeOrgs: i('active_orgs'),
      inTrial: i('in_trial'),
      expiring7d: i('expiring_7d'),
      pending: i('pending'),
      suspended: i('suspended'),
      totalMembers: i('total_members'),
    );
  }
}
