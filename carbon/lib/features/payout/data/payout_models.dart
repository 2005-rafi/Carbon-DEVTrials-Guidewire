import 'package:carbon/core/utils/model_parsers.dart';

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
      id: ModelParsers.readIdentifier(
        map,
        primaryKeys: const <String>['payout_id'],
        compatibilityKeys: const <String>['id'],
        fallback: 'PAY-0000',
      ),
      amount: ModelParsers.readDouble(
        map,
        primaryKeys: const <String>['amount'],
        compatibilityKeys: const <String>['payout_amount', 'value'],
      ),
      status: ModelParsers.readString(
        map,
        primaryKeys: const <String>['status'],
        compatibilityKeys: const <String>['payout_status'],
        fallback: 'Pending',
      ),
      date: ModelParsers.normalizeDate(
        map['created_at'] ?? map['processed_at'] ?? map['date'],
        fallback: 'Unknown date',
      ),
      paymentMethod: ModelParsers.readString(
        map,
        primaryKeys: const <String>['payment_method'],
        compatibilityKeys: const <String>['method', 'channel'],
        fallback: 'Bank Transfer',
      ),
    );
  }

  static List<PayoutRecord> fallbackList() {
    if (const bool.fromEnvironment('dart.vm.product')) {
      return const <PayoutRecord>[];
    }

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
