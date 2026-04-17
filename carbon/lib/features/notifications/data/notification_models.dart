import 'package:carbon/core/utils/model_parsers.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.message,
    required this.timestamp,
    required this.status,
    required this.type,
  });

  final String id;
  final String title;
  final String subtitle;
  final String message;
  final String timestamp;
  final String status;
  final String type;

  NotificationStatus get normalizedStatus => NotificationStatusX.parse(status);
  NotificationType get normalizedType => NotificationTypeX.parse(type);

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: ModelParsers.readIdentifier(
        map,
        primaryKeys: const <String>['notification_id'],
        compatibilityKeys: const <String>['id'],
        fallback: 'NTF-0000',
      ),
      title: ModelParsers.readString(
        map,
        primaryKeys: const <String>['title'],
        compatibilityKeys: const <String>['subject'],
        fallback: 'Notification',
      ),
      subtitle: ModelParsers.readString(
        map,
        primaryKeys: const <String>['subtitle'],
        compatibilityKeys: const <String>['summary', 'description'],
        fallback: 'No summary available.',
      ),
      message: ModelParsers.readString(
        map,
        primaryKeys: const <String>['message'],
        compatibilityKeys: const <String>['details', 'body'],
        fallback: 'No additional details available.',
      ),
      timestamp: ModelParsers.normalizeTimestamp(
        map['timestamp'] ?? map['created_at'] ?? map['date'] ?? map['time'],
        fallback: DateTime.now().toUtc().toIso8601String(),
      ),
      status: ModelParsers.readString(
        map,
        primaryKeys: const <String>['status'],
        compatibilityKeys: const <String>['read_status'],
        fallback: 'Unread',
      ),
      type: ModelParsers.readString(
        map,
        primaryKeys: const <String>['type'],
        compatibilityKeys: const <String>['category', 'notification_type'],
        fallback: 'System',
      ),
    );
  }

  AppNotification copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? message,
    String? timestamp,
    String? status,
    String? type,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      type: type ?? this.type,
    );
  }

  static List<AppNotification> fallbackList() {
    if (const bool.fromEnvironment('dart.vm.product')) {
      return const <AppNotification>[];
    }

    return const <AppNotification>[
      AppNotification(
        id: 'NTF-3011',
        title: 'Claim Approved',
        subtitle: 'Claim CLM-1024 has been approved.',
        message:
            'Your claim CLM-1024 was automatically approved after event verification.',
        timestamp: '2026-04-03T08:45:00Z',
        status: 'Unread',
        type: 'Claim',
      ),
      AppNotification(
        id: 'NTF-3012',
        title: 'Payout Processed',
        subtitle: 'Payout PAY-2201 has been processed.',
        message:
            'A payout of Rs 1,200 has been credited to your registered account.',
        timestamp: '2026-04-03T10:20:00Z',
        status: 'Unread',
        type: 'Payout',
      ),
      AppNotification(
        id: 'NTF-3008',
        title: 'Disruption Resolved',
        subtitle: 'Rainfall disruption event has been resolved.',
        message:
            'Operations are now normal. Related pending claims will be re-evaluated shortly.',
        timestamp: '2026-04-02T16:12:00Z',
        status: 'Read',
        type: 'Event',
      ),
    ];
  }
}

enum NotificationStatus { read, unread, unknown }

extension NotificationStatusX on NotificationStatus {
  static NotificationStatus parse(String raw) {
    final value = raw.trim().toLowerCase();
    if (value == 'read') {
      return NotificationStatus.read;
    }
    if (value == 'unread' || value == 'new') {
      return NotificationStatus.unread;
    }
    return NotificationStatus.unknown;
  }
}

enum NotificationType { claim, payout, event, analytics, system, unknown }

extension NotificationTypeX on NotificationType {
  static NotificationType parse(String raw) {
    final value = raw.trim().toLowerCase();
    if (value == 'claim' || value == 'claims') {
      return NotificationType.claim;
    }
    if (value == 'payout' || value == 'payment') {
      return NotificationType.payout;
    }
    if (value == 'event' || value == 'disruption') {
      return NotificationType.event;
    }
    if (value == 'analytics' || value == 'insight') {
      return NotificationType.analytics;
    }
    if (value == 'system') {
      return NotificationType.system;
    }
    return NotificationType.unknown;
  }
}

class NotificationSummary {
  const NotificationSummary({
    required this.total,
    required this.unread,
    required this.read,
  });

  final int total;
  final int unread;
  final int read;

  factory NotificationSummary.fromRecords(List<AppNotification> records) {
    var unreadCount = 0;
    var readCount = 0;

    for (final item in records) {
      final status = item.normalizedStatus;
      if (status == NotificationStatus.unread) {
        unreadCount++;
      } else if (status == NotificationStatus.read) {
        readCount++;
      }
    }

    return NotificationSummary(
      total: records.length,
      unread: unreadCount,
      read: readCount,
    );
  }
}
