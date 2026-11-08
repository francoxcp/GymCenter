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

  const OrgPayment({
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

  const OrgSummary({
    this.inTrial = false,
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
