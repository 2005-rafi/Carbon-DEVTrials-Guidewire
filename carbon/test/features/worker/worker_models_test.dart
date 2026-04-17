import 'package:carbon/core/network/api_exception.dart';
import 'package:carbon/features/worker/data/worker_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkerProfileUpdateRequest', () {
    test('normalizes name, phone, zone and email', () {
      final request = WorkerProfileUpdateRequest.fromRaw(
        userId: ' user-1 ',
        name: '  Meera   Singh ',
        phone: ' +91 98 765-43210 ',
        zone: ' mr 2 ',
        email: ' Meera@Mail.COM ',
      );

      expect(request.userId, 'user-1');
      expect(request.name, 'Meera Singh');
      expect(request.phone, '+919876543210');
      expect(request.zone, 'MR-2');
      expect(request.email, 'meera@mail.com');
    });

    test('builds compatibility payload variants', () {
      final request = WorkerProfileUpdateRequest.fromRaw(
        userId: 'user-2',
        name: 'Asha',
        phone: '9876543210',
        zone: 'mr1',
        email: 'asha@mail.com',
      );

      final variants = request.toPayloadVariants();

      expect(variants.length, 4);
      expect(variants.first['name'], 'Asha');
      expect(variants.first['phone'], '9876543210');
      expect(variants.first['zone'], 'MR1');
      expect(variants.last['full_name'], 'Asha');
      expect(variants.last['phone_number'], '9876543210');
    });

    test('throws when required fields are invalid', () {
      final request = WorkerProfileUpdateRequest.fromRaw(
        userId: 'user-3',
        name: '',
        phone: '12',
        zone: '',
      );

      expect(request.validate, throwsA(isA<ApiException>()));
    });
  });
}
