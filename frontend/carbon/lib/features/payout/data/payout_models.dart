class PayoutRecord {
  const PayoutRecord({
    required this.id,
    required this.amount,
    required this.status,
    required this.date,
    required this.paymentMethod,
  });

  final String id;
  final double amount;
  final String status;
  final String date;
  final String paymentMethod;

  PayoutStatus get normalizedStatus => PayoutStatusX.parse(status);

  factory PayoutRecord.fromMap(Map<String, dynamic> map) {
    return PayoutRecord(
      id: _readString(map, <String>['id', 'payout_id'], fallback: 'PAY-0000'),
      amount: _toDouble(map['amount'] ?? map['value'] ?? map['payout_amount']),
      status: _readString(map, <String>[
        'status',
        'payout_status',
      ], fallback: 'Pending'),
      date: _readString(map, <String>[
        'date',
        'created_at',
        'processed_at',
      ], fallback: 'Unknown date'),
      paymentMethod: _readString(map, <String>[
        'payment_method',
        'method',
        'channel',
      ], fallback: 'Bank Transfer'),
    );
  }

  static List<PayoutRecord> fallbackList() {
    return const <PayoutRecord>[
      PayoutRecord(
        id: 'PAY-2201',
        amount: 1200,
        status: 'Completed',
        date: '2026-03-20',
        paymentMethod: 'UPI',
      ),
      PayoutRecord(
        id: 'PAY-2207',
        amount: 650,
        status: 'Pending',
        date: '2026-03-27',
        paymentMethod: 'Bank Transfer',
      ),
      PayoutRecord(
        id: 'PAY-2218',
        amount: 0,
        status: 'Failed',
        date: '2026-04-02',
        paymentMethod: 'Wallet',
      ),
    ];
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
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
    }
    return fallback;
  }
}

enum PayoutStatus { completed, pending, failed, processing, unknown }

extension PayoutStatusX on PayoutStatus {
  static PayoutStatus parse(String raw) {
    final value = raw.trim().toLowerCase();
    if (value == 'completed' || value == 'paid' || value == 'success') {
      return PayoutStatus.completed;
    }
    if (value == 'pending') {
      return PayoutStatus.pending;
    }
    if (value == 'failed' || value == 'rejected') {
      return PayoutStatus.failed;
    }
    if (value == 'processing') {
      return PayoutStatus.processing;
    }
    return PayoutStatus.unknown;
  }
}

class PayoutSummary {
  const PayoutSummary({
    required this.totalEarnings,
    required this.totalPayouts,
    required this.pendingAmount,
  });

  final double totalEarnings;
  final int totalPayouts;
  final double pendingAmount;

  factory PayoutSummary.fromRecords(List<PayoutRecord> records) {
    var totalEarningsValue = 0.0;
    var completedCount = 0;
    var pendingValue = 0.0;

    for (final record in records) {
      totalEarningsValue += record.amount;
      final status = record.normalizedStatus;
      if (status == PayoutStatus.completed) {
        completedCount++;
      }
      if (status == PayoutStatus.pending || status == PayoutStatus.processing) {
        pendingValue += record.amount;
      }
    }

    return PayoutSummary(
      totalEarnings: totalEarningsValue,
      totalPayouts: completedCount,
      pendingAmount: pendingValue,
    );
  }
}
