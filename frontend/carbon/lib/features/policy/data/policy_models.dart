class PolicySummary {
  const PolicySummary({
    required this.coverage,
    required this.premium,
    required this.waitingPeriod,
  });

  final String coverage;
  final String premium;
  final String waitingPeriod;
}

class PolicySection {
  const PolicySection({
    required this.title,
    required this.description,
    this.bullets = const <String>[],
  });

  final String title;
  final String description;
  final List<String> bullets;
}

class PolicyDetails {
  const PolicyDetails({
    required this.planName,
    required this.productType,
    required this.coverage,
    required this.premium,
    required this.premiumCycle,
    required this.waitingPeriod,
    required this.payoutMechanism,
    required this.status,
    required this.sections,
  });

  final String planName;
  final String productType;
  final String coverage;
  final String premium;
  final String premiumCycle;
  final String waitingPeriod;
  final String payoutMechanism;
  final String status;
  final List<PolicySection> sections;

  PolicySummary get summary => PolicySummary(
    coverage: coverage,
    premium: '$premium / $premiumCycle',
    waitingPeriod: waitingPeriod,
  );

  factory PolicyDetails.fromMap(Map<String, dynamic> map) {
    final sectionsRaw = map['sections'];
    final sections = <PolicySection>[];

    if (sectionsRaw is List) {
      for (final item in sectionsRaw) {
        if (item is! Map<String, dynamic>) {
          continue;
        }

        final bulletRaw = item['bullets'];
        final bullets = bulletRaw is List
            ? bulletRaw
                  .whereType<String>()
                  .map((entry) => entry.trim())
                  .where((entry) => entry.isNotEmpty)
                  .toList()
            : <String>[];

        sections.add(
          PolicySection(
            title: _readString(item, <String>[
              'title',
              'name',
              'heading',
            ], fallback: 'Policy Section'),
            description: _readString(
              item,
              <String>['description', 'content', 'text'],
              fallback: 'Details are currently unavailable for this section.',
            ),
            bullets: bullets,
          ),
        );
      }
    }

    return PolicyDetails(
      planName: _readString(map, <String>[
        'plan',
        'plan_name',
        'product_name',
      ], fallback: 'Income Shield'),
      productType: _readString(map, <String>[
        'product_type',
        'type',
      ], fallback: 'Parametric Microinsurance'),
      coverage: _readString(map, <String>[
        'coverage',
        'coverage_scope',
      ], fallback: 'Up to 15,000 per disruption event'),
      premium: _readString(map, <String>[
        'premium',
        'premium_amount',
      ], fallback: '199'),
      premiumCycle: _readString(map, <String>[
        'premium_cycle',
        'cycle',
      ], fallback: 'month'),
      waitingPeriod: _readString(map, <String>[
        'waiting_period',
        'waitingPeriod',
      ], fallback: '24 hours'),
      payoutMechanism: _readString(
        map,
        <String>['payout_logic', 'payout_mechanism', 'payout'],
        fallback:
            'Automatically triggered based on verified disruption events.',
      ),
      status: _readString(map, <String>[
        'status',
        'policy_status',
      ], fallback: 'active'),
      sections: sections.isEmpty ? fallback().sections : sections,
    );
  }

  static PolicyDetails fallback() {
    return const PolicyDetails(
      planName: 'Income Shield',
      productType: 'Parametric Microinsurance',
      coverage: 'Up to 15,000 per disruption event',
      premium: '199',
      premiumCycle: 'month',
      waitingPeriod: '24 hours',
      payoutMechanism:
          'Claims are auto-triggered by event signals and paid without manual filing.',
      status: 'active',
      sections: <PolicySection>[
        PolicySection(
          title: 'Coverage Scope & Insured Perils',
          description:
              'Coverage applies to validated disruptions such as severe weather, strikes, and platform outages.',
          bullets: <String>[
            'Applies only to enrolled workers in active regions.',
            'Event severity and duration define compensation eligibility.',
          ],
        ),
        PolicySection(
          title: 'Premium Mechanics',
          description:
              'Premiums are billed in fixed cycles and activation requires successful payment confirmation.',
          bullets: <String>[
            'Grace period: 48 hours from due date.',
            'Coverage pauses automatically when premium is overdue.',
          ],
        ),
        PolicySection(
          title: 'Payout Calculation',
          description:
              'Payout amount is calculated using disruption severity, duration, and verified worker activity window.',
          bullets: <String>[
            'No manual claim filing required.',
            'Payouts are processed to linked payout account.',
          ],
        ),
        PolicySection(
          title: 'Exclusions',
          description:
              'Fraudulent events, non-verified disruptions, and inactive policies are excluded from compensation.',
          bullets: <String>[
            'Invalid account activity is excluded.',
            'Manual override can be applied for fraud investigations.',
          ],
        ),
      ],
    );
  }

  static String _readString(
    Map<String, dynamic> source,
    List<String> keys, {
    required String fallback,
  }) {
    for (final key in keys) {
      final value = source[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
      if (value is num) {
        return value.toString();
      }
    }

    return fallback;
  }
}
