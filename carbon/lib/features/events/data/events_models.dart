import 'package:carbon/core/utils/model_parsers.dart';

class EventRecord {
  const EventRecord({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.status,
    required this.date,
    required this.location,
    required this.impactSummary,
    required this.relatedClaimId,
  });

  final String id;
  final String title;
  final String description;
  final String severity;
  final String status;
  final String date;
  final String location;
  final String impactSummary;
  final String relatedClaimId;

  EventStatus get normalizedStatus => EventStatusX.parse(status);
  EventSeverity get normalizedSeverity => EventSeverityX.parse(severity);

  factory EventRecord.fromMap(Map<String, dynamic> map) {
    final isActive = ModelParsers.readBool(
      map,
      primaryKeys: const <String>['active'],
      compatibilityKeys: const <String>['is_active'],
      fallback: true,
    );

    return EventRecord(
      id: ModelParsers.readIdentifier(
        map,
        primaryKeys: const <String>['event_id'],
        compatibilityKeys: const <String>['id'],
        fallback: 'EVT-0000',
      ),
      title: ModelParsers.readString(
        map,
        primaryKeys: const <String>['title'],
        compatibilityKeys: const <String>['type', 'name', 'event_title'],
        fallback: 'Disruption Event',
      ),
      description: ModelParsers.readString(
        map,
        primaryKeys: const <String>['description'],
        compatibilityKeys: const <String>['details', 'summary', 'type'],
        fallback: 'Event details are currently unavailable.',
      ),
      severity: ModelParsers.readString(
        map,
        primaryKeys: const <String>['severity'],
        compatibilityKeys: const <String>['level', 'risk_level'],
        fallback: 'Medium',
      ),
      status: ModelParsers.readString(
        map,
        primaryKeys: const <String>['status'],
        compatibilityKeys: const <String>['event_status'],
        fallback: isActive ? 'Active' : 'Resolved',
      ),
      date: ModelParsers.normalizeDate(
        map['timestamp'] ??
            map['created_at'] ??
            map['event_time'] ??
            map['date'],
        fallback: 'Unknown date',
      ),
      location: ModelParsers.readString(
        map,
        primaryKeys: const <String>['zone', 'location'],
        compatibilityKeys: const <String>['area', 'city', 'region'],
        fallback: 'Location unavailable',
      ),
      impactSummary: ModelParsers.readString(
        map,
        primaryKeys: const <String>['impact_summary'],
        compatibilityKeys: const <String>['impact', 'impact_note'],
        fallback: 'Operational impact being assessed.',
      ),
      relatedClaimId: ModelParsers.readIdentifier(
        map,
        primaryKeys: const <String>['related_claim_id'],
        compatibilityKeys: const <String>['claim_id'],
        fallback: 'N/A',
      ),
    );
  }

  static List<EventRecord> fallbackList() {
    if (const bool.fromEnvironment('dart.vm.product')) {
      return const <EventRecord>[];
    }

    return const <EventRecord>[
      EventRecord(
        id: 'EVT-4501',
        title: 'Heavy Rainfall Alert',
        description:
            'Severe rainfall was detected in your active delivery zone for 4 hours.',
        severity: 'High',
        status: 'Active',
        date: '2026-04-03T08:20:00Z',
        location: 'Mumbai Central',
        impactSummary:
            'High disruption to route availability and delivery time.',
        relatedClaimId: 'CLM-1088',
      ),
      EventRecord(
        id: 'EVT-4478',
        title: 'Public Transport Strike',
        description:
            'A scheduled local transport strike affected rider movement in key sectors.',
        severity: 'Medium',
        status: 'Resolved',
        date: '2026-04-01T06:00:00Z',
        location: 'Pune West',
        impactSummary: 'Moderate drop in completed trips for 6-hour window.',
        relatedClaimId: 'CLM-1024',
      ),
      EventRecord(
        id: 'EVT-4520',
        title: 'Platform Outage',
        description:
            'An upstream platform outage caused temporary order assignment failures.',
        severity: 'Critical',
        status: 'Critical',
        date: '2026-04-04T10:45:00Z',
        location: 'Bengaluru South',
        impactSummary:
            'Critical disruption with immediate payout review trigger.',
        relatedClaimId: 'CLM-1099',
      ),
    ];
  }
}

enum EventStatus { active, resolved, critical, unknown }

extension EventStatusX on EventStatus {
  static EventStatus parse(String raw) {
    final value = raw.trim().toLowerCase();
    if (value == 'active' || value == 'ongoing' || value == 'open') {
      return EventStatus.active;
    }
    if (value == 'resolved' || value == 'closed') {
      return EventStatus.resolved;
    }
    if (value == 'critical' || value == 'alert') {
      return EventStatus.critical;
    }
    return EventStatus.unknown;
  }
}

enum EventSeverity { low, medium, high, critical, unknown }

extension EventSeverityX on EventSeverity {
  static EventSeverity parse(String raw) {
    final value = raw.trim().toLowerCase();
    if (value == 'low') {
      return EventSeverity.low;
    }
    if (value == 'medium' || value == 'moderate') {
      return EventSeverity.medium;
    }
    if (value == 'high') {
      return EventSeverity.high;
    }
    if (value == 'critical' || value == 'severe') {
      return EventSeverity.critical;
    }
    return EventSeverity.unknown;
  }
}

class EventsSummary {
  const EventsSummary({
    required this.total,
    required this.active,
    required this.resolved,
    required this.highSeverity,
  });

  final int total;
  final int active;
  final int resolved;
  final int highSeverity;

  factory EventsSummary.fromRecords(List<EventRecord> records) {
    var activeCount = 0;
    var resolvedCount = 0;
    var highSeverityCount = 0;

    for (final record in records) {
      final status = record.normalizedStatus;
      final severity = record.normalizedSeverity;

      if (status == EventStatus.active || status == EventStatus.critical) {
        activeCount++;
      }
      if (status == EventStatus.resolved) {
        resolvedCount++;
      }
      if (severity == EventSeverity.high ||
          severity == EventSeverity.critical) {
        highSeverityCount++;
      }
    }

    return EventsSummary(
      total: records.length,
      active: activeCount,
      resolved: resolvedCount,
      highSeverity: highSeverityCount,
    );
  }
}
