import 'package:carbon/core/utils/model_parsers.dart';

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
    final claimsTotal = ModelParsers.readInt(
      map,
      primaryKeys: const <String>['total_claims_count'],
      compatibilityKeys: const <String>['claims_this_month', 'claims'],
    );
    final approved = ModelParsers.readInt(
      map,
      primaryKeys: const <String>['approved_claims'],
      compatibilityKeys: const <String>['approved', 'active_policies'],
    );
    final pending = ModelParsers.readInt(
      map,
      primaryKeys: const <String>['pending_claims'],
      compatibilityKeys: const <String>['pending'],
    );

    return AnalyticsSummary(
      totalProtectedEarnings: ModelParsers.readDouble(
        map,
        primaryKeys: const <String>['total_protected_earnings'],
        compatibilityKeys: const <String>[
          'total_payout_amount',
          'total_earnings',
          'earnings',
          'weeklyEarnings',
        ],
      ),
      claimsThisMonth: claimsTotal > 0 ? claimsTotal : approved + pending,
      approvedClaims: approved,
      pendingClaims: pending,
      avgPayoutHours: ModelParsers.readDouble(
        map,
        primaryKeys: const <String>['avg_payout_hours'],
        compatibilityKeys: const <String>[
          'average_payout_hours',
          'avgPayoutHours',
        ],
      ),
      approvalRate: ModelParsers.readDouble(
        map,
        primaryKeys: const <String>['approval_rate'],
        compatibilityKeys: const <String>['claim_approval_rate'],
      ),
    );
  }

  static AnalyticsSummary fallback() {
    if (const bool.fromEnvironment('dart.vm.product')) {
      return const AnalyticsSummary(
        totalProtectedEarnings: 0,
        claimsThisMonth: 0,
        approvedClaims: 0,
        pendingClaims: 0,
        avgPayoutHours: 0,
        approvalRate: 0,
      );
    }

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
    final labelRaw =
        map['date'] ?? map['label'] ?? map['period'] ?? map['month'];
    return AnalyticsTrendPoint(
      label: ModelParsers.normalizeDate(labelRaw, fallback: 'N/A'),
      earnings: ModelParsers.readDouble(
        map,
        primaryKeys: const <String>['earnings'],
        compatibilityKeys: const <String>['revenue', 'payouts'],
      ),
      claims: ModelParsers.readInt(
        map,
        primaryKeys: const <String>['claims'],
        compatibilityKeys: const <String>['claims_count'],
      ),
      payouts: ModelParsers.readDouble(
        map,
        primaryKeys: const <String>['payouts'],
        compatibilityKeys: const <String>['payout_amount', 'earnings'],
      ),
    );
  }

  static List<AnalyticsTrendPoint> fallbackList() {
    if (const bool.fromEnvironment('dart.vm.product')) {
      return const <AnalyticsTrendPoint>[];
    }

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
    final impact = ModelParsers.readString(
      map,
      primaryKeys: const <String>['impact_level'],
      compatibilityKeys: const <String>['impact', 'severity'],
      fallback: 'Medium',
    );

    final rawAnomaly = map['is_anomaly'] ?? map['anomaly'];
    final isAnomaly = rawAnomaly is bool
        ? rawAnomaly
        : rawAnomaly is String
        ? rawAnomaly.toLowerCase() == 'true'
        : false;

    return AnalyticsInsight(
      title: ModelParsers.readString(
        map,
        primaryKeys: const <String>['title'],
        compatibilityKeys: const <String>['name'],
        fallback: 'Insight',
      ),
      description: ModelParsers.readString(
        map,
        primaryKeys: const <String>['description'],
        compatibilityKeys: const <String>['details', 'summary'],
        fallback: 'No detailed insight available.',
      ),
      category: ModelParsers.readString(
        map,
        primaryKeys: const <String>['category'],
        compatibilityKeys: const <String>['type'],
        fallback: 'General',
      ),
      impactLevel: impact,
      isAnomaly: isAnomaly,
    );
  }

  static List<AnalyticsInsight> fallbackList() {
    if (const bool.fromEnvironment('dart.vm.product')) {
      return const <AnalyticsInsight>[];
    }

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

  factory AnalyticsData.empty() {
    return const AnalyticsData(
      summary: AnalyticsSummary(
        totalProtectedEarnings: 0,
        claimsThisMonth: 0,
        approvedClaims: 0,
        pendingClaims: 0,
        avgPayoutHours: 0,
        approvalRate: 0,
      ),
      trends: <AnalyticsTrendPoint>[],
      insights: <AnalyticsInsight>[],
    );
  }

  factory AnalyticsData.fallback() {
    return AnalyticsData(
      summary: AnalyticsSummary.fallback(),
      trends: AnalyticsTrendPoint.fallbackList(),
      insights: AnalyticsInsight.fallbackList(),
    );
  }
}
