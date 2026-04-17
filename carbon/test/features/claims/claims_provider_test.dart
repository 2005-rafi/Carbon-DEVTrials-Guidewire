import 'package:carbon/core/network/api_exception.dart';
import 'package:carbon/features/claims/data/claims_api.dart';
import 'package:carbon/features/claims/data/claims_models.dart';
import 'package:carbon/features/claims/provider/claims_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _SequencedClaimsApi extends ClaimsApi {
  _SequencedClaimsApi(this._steps) : super(Dio());

  final List<Object> _steps;
  int _index = 0;

  @override
  Future<List<ClaimRecord>> fetchClaims() async {
    final step = _steps[_index < _steps.length ? _index : _steps.length - 1];
    _index++;

    if (step is ApiException) {
      throw step;
    }

    return step as List<ClaimRecord>;
  }

  @override
  Future<void> createAutoClaim({required String eventId}) async {
    return;
  }
}

void main() {
  group('claimsAsyncProvider', () {
    test('stores fresh claims in cache on successful fetch', () async {
      final records = <ClaimRecord>[
        const ClaimRecord(
          id: 'CLM-1001',
          status: 'Approved',
          date: '2026-04-17',
          amount: 1200,
          description: 'Auto-approved claim',
        ),
      ];

      final container = ProviderContainer(
        overrides: <Override>[
          claimsApiProvider.overrideWithValue(
            _SequencedClaimsApi(<Object>[records]),
          ),
        ],
      );
      addTearDown(container.dispose);

      final loaded = await container.read(claimsAsyncProvider.future);

      expect(loaded, hasLength(1));
      expect(container.read(claimsIsStaleProvider), isFalse);
      expect(container.read(claimsLastSyncedAtProvider), isNotNull);
      expect(container.read(claimsErrorProvider), isNull);
    });

    test('returns stale cached claims when subsequent fetch fails', () async {
      final records = <ClaimRecord>[
        const ClaimRecord(
          id: 'CLM-2001',
          status: 'Pending',
          date: '2026-04-17',
          amount: 450,
          description: 'Pending claim',
        ),
      ];

      final api = _SequencedClaimsApi(<Object>[
        records,
        const ApiException('Claims service unavailable', statusCode: 500),
      ]);

      final container = ProviderContainer(
        overrides: <Override>[claimsApiProvider.overrideWithValue(api)],
      );
      addTearDown(container.dispose);

      final first = await container.read(claimsAsyncProvider.future);
      expect(first, hasLength(1));

      container.invalidate(claimsAsyncProvider);
      final fallback = await container.read(claimsAsyncProvider.future);

      expect(fallback, hasLength(1));
      expect(fallback.first.id, 'CLM-2001');
      expect(container.read(claimsIsStaleProvider), isTrue);
      expect(
        container.read(claimsErrorProvider),
        contains('Showing last synced claims.'),
      );
    });
  });
}
