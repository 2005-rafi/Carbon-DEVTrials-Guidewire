class AnalyticsMetric {
  const AnalyticsMetric({required this.label, required this.value});

  final String label;
  final String value;
}

class AnalyticsSummary {
  const AnalyticsSummary({
    required this.totalProtectedEarnings,
    required this.claimsThisMonth,
    required this.approvedClaims,
    required this.pendingClaims,
    required this.avgPayoutHours,
    required this.approvalRate,
  });

  final double totalProtectedEarnings;
  final int claimsThisMonth;
  final int approvedClaims;
  final int pendingClaims;
  final double avgPayoutHours;
  final double approvalRate;

  factory AnalyticsSummary.fromMap(Map<String, dynamic> map) {
    final claimsTotal = _readInt(map, <String>['claims_this_month', 'claims']);
    final approved = _readInt(map, <String>['approved_claims', 'approved']);
    final pending = _readInt(map, <String>['pending_claims', 'pending']);

    return AnalyticsSummary(
      totalProtectedEarnings: _readDouble(map, <String>[
        'total_protected_earnings',
        'weeklyEarnings',
        'earnings',
        'total_earnings',
      ]),
      claimsThisMonth: claimsTotal > 0 ? claimsTotal : approved + pending,
      approvedClaims: approved,
      pendingClaims: pending,
      avgPayoutHours: _readDouble(map, <String>[
        'avg_payout_hours',
        'average_payout_hours',
        'avgPayoutHours',
      ]),
      approvalRate: _readDouble(map, <String>[
        'approval_rate',
        'claim_approval_rate',
      ]),
    );
  }

  static AnalyticsSummary fallback() {
    return const AnalyticsSummary(
      totalProtectedEarnings: 5200,
      claimsThisMonth: 7,
      approvedClaims: 5,
      pendingClaims: 2,
      avgPayoutHours: 4.2,
      approvalRate: 0.71,
    );
  }
}

class AnalyticsTrendPoint {
  const AnalyticsTrendPoint({
    required this.label,
    required this.earnings,
    required this.claims,
    required this.payouts,
  });

  final String label;
  final double earnings;
  final int claims;
  final double payouts;

  factory AnalyticsTrendPoint.fromMap(Map<String, dynamic> map) {
    return AnalyticsTrendPoint(
      label: _readString(map, <String>[
        'label',
        'period',
        'date',
        'month',
      ], fallback: 'N/A'),
      earnings: _readDouble(map, <String>['earnings', 'revenue']),
      claims: _readInt(map, <String>['claims', 'claims_count']),
      payouts: _readDouble(map, <String>['payouts', 'payout_amount']),
    );
  }

  static List<AnalyticsTrendPoint> fallbackList() {
    return const <AnalyticsTrendPoint>[
      AnalyticsTrendPoint(
        label: 'Jan',
        earnings: 3800,
        claims: 3,
        payouts: 2800,
      ),
      AnalyticsTrendPoint(
        label: 'Feb',
        earnings: 4100,
        claims: 4,
        payouts: 3050,
      ),
      AnalyticsTrendPoint(
        label: 'Mar',
        earnings: 4600,
        claims: 5,
        payouts: 3490,
      ),
      AnalyticsTrendPoint(
        label: 'Apr',
        earnings: 5200,
        claims: 7,
        payouts: 4020,
      ),
      AnalyticsTrendPoint(
        label: 'May',
        earnings: 4800,
        claims: 6,
        payouts: 3675,
      ),
      AnalyticsTrendPoint(
        label: 'Jun',
        earnings: 5500,
        claims: 8,
        payouts: 4340,
      ),
    ];
  }
}

class AnalyticsInsight {
  const AnalyticsInsight({
    required this.title,
    required this.description,
    required this.category,
    required this.impactLevel,
    required this.isAnomaly,
  });

  final String title;
  final String description;
  final String category;
  final String impactLevel;
  final bool isAnomaly;

  factory AnalyticsInsight.fromMap(Map<String, dynamic> map) {
    final impact = _readString(map, <String>[
      'impact',
      'impact_level',
      'severity',
    ], fallback: 'Medium');

    final rawAnomaly = map['is_anomaly'] ?? map['anomaly'];
    final isAnomaly = rawAnomaly is bool
        ? rawAnomaly
        : rawAnomaly is String
        ? rawAnomaly.toLowerCase() == 'true'
        : false;

    return AnalyticsInsight(
      title: _readString(map, <String>['title', 'name'], fallback: 'Insight'),
      description: _readString(map, <String>[
        'description',
        'details',
        'summary',
      ], fallback: 'No detailed insight available.'),
      category: _readString(map, <String>[
        'category',
        'type',
      ], fallback: 'General'),
      impactLevel: impact,
      isAnomaly: isAnomaly,
    );
  }

  static List<AnalyticsInsight> fallbackList() {
    return const <AnalyticsInsight>[
      AnalyticsInsight(
        title: 'Payout Efficiency Improved',
        description:
            'Average payout processing time improved by 18% compared to last month.',
        category: 'Payout',
        impactLevel: 'High',
        isAnomaly: false,
      ),
      AnalyticsInsight(
        title: 'High Disruption Cluster',
        description:
            'Rainfall-related disruptions increased in two active delivery zones.',
        category: 'Events',
        impactLevel: 'Critical',
        isAnomaly: true,
      ),
      AnalyticsInsight(
        title: 'Claim Approval Stability',
        description:
            'Claim approval rate has remained above 70% for the last 3 periods.',
        category: 'Claims',
        impactLevel: 'Medium',
        isAnomaly: false,
      ),
    ];
  }
}

class AnalyticsData {
  const AnalyticsData({
    required this.summary,
    required this.trends,
    required this.insights,
  });

  final AnalyticsSummary summary;
  final List<AnalyticsTrendPoint> trends;
  final List<AnalyticsInsight> insights;

  factory AnalyticsData.fallback() {
    return AnalyticsData(
      summary: AnalyticsSummary.fallback(),
      trends: AnalyticsTrendPoint.fallbackList(),
      insights: AnalyticsInsight.fallbackList(),
    );
  }
}

double _readDouble(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = source[key];
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
      final parsed = double.tryParse(cleaned);
      if (parsed != null) {
        return parsed;
      }
    }
  }
  return 0;
}

int _readInt(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = source[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    if (value is String) {
      final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
      final parsed = int.tryParse(cleaned);
      if (parsed != null) {
        return parsed;
      }
    }
  }
  return 0;
}

String _readString(
  Map<String, dynamic> source,
  List<String> keys, {
  required String fallback,
}) {
  for (final key in keys) {
    final value = source[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return fallback;
}
