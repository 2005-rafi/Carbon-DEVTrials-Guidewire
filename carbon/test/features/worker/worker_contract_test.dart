import 'package:carbon/features/worker/data/worker_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Worker contract parser compatibility', () {
    test('parses canonical worker profile response payload', () {
      final payload = <String, dynamic>{
        'user_id': 'a8499a8c-f148-4e77-8c46-ee7f4fdfba81',
        'name': 'Suhaib',
        'zone': 'MR-1',
        'weekly_income': 500,
      };

      final profile = WorkerProfile.fromMap(payload);

      expect(profile.userId, 'a8499a8c-f148-4e77-8c46-ee7f4fdfba81');
      expect(profile.name, 'Suhaib');
      expect(profile.zone, 'MR-1');
      expect(profile.weeklyIncome, 500);
    });

    test('parses canonical worker status response payload', () {
      final payload = <String, dynamic>{
        'is_active': true,
        'eligible_for_claim': true,
      };

      final status = WorkerStatus.fromMap(payload);

      expect(status.isCoverageActive, isTrue);
      expect(status.canClaim, isTrue);
      expect(status.coverageLabel, 'Active');
      expect(status.claimEligibilityLabel, 'Eligible');
    });
  });
}
