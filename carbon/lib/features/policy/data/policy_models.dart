import 'package:carbon/core/utils/model_parsers.dart';

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
    final isOptedIn = ModelParsers.readBool(
      map,
      primaryKeys: const <String>['is_opted_in'],
      compatibilityKeys: const <String>['opted_in'],
      fallback: false,
    );

    final statusText = ModelParsers.readString(
      map,
      primaryKeys: const <String>['status'],
      compatibilityKeys: const <String>['policy_status'],
      fallback: isOptedIn ? 'active' : 'inactive',
    );

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
            title: ModelParsers.readString(
              item,
              primaryKeys: const <String>['title'],
              compatibilityKeys: const <String>['name', 'heading'],
              fallback: 'Policy Section',
            ),
            description: ModelParsers.readString(
              item,
              primaryKeys: const <String>['description'],
              compatibilityKeys: const <String>['content', 'text'],
              fallback: 'Details are currently unavailable for this section.',
            ),
            bullets: bullets,
          ),
        );
      }
    }

    return PolicyDetails(
      planName: ModelParsers.readString(
        map,
        primaryKeys: const <String>['plan_name'],
        compatibilityKeys: const <String>['plan', 'product_name'],
        fallback: 'Income Shield',
      ),
      productType: ModelParsers.readString(
        map,
        primaryKeys: const <String>['product_type'],
        compatibilityKeys: const <String>['type'],
        fallback: 'Parametric Microinsurance',
      ),
      coverage: ModelParsers.readString(
        map,
        primaryKeys: const <String>['coverage'],
        compatibilityKeys: const <String>['coverage_scope'],
        fallback: 'Up to 15,000 per disruption event',
      ),
      premium: ModelParsers.readString(
        map,
        primaryKeys: const <String>['premium_amount'],
        compatibilityKeys: const <String>['premium'],
        fallback: '0',
      ),
      premiumCycle: ModelParsers.readString(
        map,
        primaryKeys: const <String>['premium_cycle'],
        compatibilityKeys: const <String>['cycle'],
        fallback: 'month',
      ),
      waitingPeriod: ModelParsers.readString(
        map,
        primaryKeys: const <String>['waiting_period'],
        compatibilityKeys: const <String>['waitingPeriod'],
        fallback: '-',
      ),
      payoutMechanism: ModelParsers.readString(
        map,
        primaryKeys: const <String>['payout_mechanism'],
        compatibilityKeys: const <String>['payout_logic', 'payout'],
        fallback:
            'Automatically triggered based on verified disruption events.',
      ),
      status: statusText,
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

  static PolicyDetails empty() {
    return const PolicyDetails(
      planName: 'No Active Policy',
      productType: 'Not Enrolled',
      coverage: 'No active coverage yet',
      premium: '0',
      premiumCycle: 'month',
      waitingPeriod: '-',
      payoutMechanism:
          'Activate a policy to enable automatic disruption protection.',
      status: 'inactive',
      sections: <PolicySection>[
        PolicySection(
          title: 'No Active Policy',
          description:
              'You are currently not enrolled in an active policy. Accept policy terms to activate protection.',
        ),
      ],
    );
  }
}
