enum PlanPeriod {
  annual('Annual', 'year'),
  monthly('Monthly', 'month'),
  weekly('Weekly', 'week');

  const PlanPeriod(this.label, this.unit);

  final String label;
  final String unit;
}

/// Un plan del paywall con su precio en la moneda de la tienda del usuario.
class PlanOption {
  const PlanOption({
    required this.id,
    required this.period,
    required this.price,
    required this.priceValue,
    this.pricePerMonth,
    this.trialDays,
  });

  /// Identificador del paquete en RevenueCat.
  final String id;
  final PlanPeriod period;

  /// Precio con formato de App Store («US$29.99», «29,99 €»).
  final String price;
  final double priceValue;
  final String? pricePerMonth;

  /// Días de prueba gratis si el usuario aún puede usarla; null si no.
  final int? trialDays;
}

/// Ahorro del anual frente a 12 meses del mensual, en %; null si no hay ambos.
int? annualSaving(List<PlanOption> plans) {
  final annual = plans.where((p) => p.period == PlanPeriod.annual).firstOrNull;
  final monthly = plans
      .where((p) => p.period == PlanPeriod.monthly)
      .firstOrNull;
  if (annual == null || monthly == null || monthly.priceValue <= 0) return null;
  final saving = ((1 - annual.priceValue / (monthly.priceValue * 12)) * 100)
      .floor();
  return saving > 0 ? saving : null;
}

/// Estado del entitlement travio_pro.
class Subscription {
  const Subscription({
    required this.active,
    this.period,
    this.trial = false,
    this.willRenew = false,
    this.expiresAt,
  });

  static const none = Subscription(active: false);

  final bool active;
  final PlanPeriod? period;
  final bool trial;
  final bool willRenew;
  final DateTime? expiresAt;

  /// Para soporte: «Annual», «Monthly · Trial», «Weekly · Cancelled» o «None».
  String get label {
    if (!active) return 'None';
    final plan = (period ?? PlanPeriod.annual).label;
    if (trial) return '$plan · Trial';
    return willRenew ? plan : '$plan · Cancelled';
  }
}
