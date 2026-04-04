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
    return EventRecord(
      id: _readString(map, <String>['id', 'event_id'], fallback: 'EVT-0000'),
      title: _readString(map, <String>[
        'title',
        'name',
        'event_title',
      ], fallback: 'Disruption Event'),
      description: _readString(map, <String>[
        'description',
        'details',
        'summary',
      ], fallback: 'Event details are currently unavailable.'),
      severity: _readString(map, <String>[
        'severity',
        'level',
        'risk_level',
      ], fallback: 'Medium'),
      status: _readString(map, <String>[
        'status',
        'event_status',
      ], fallback: 'Active'),
      date: _readString(map, <String>[
        'date',
        'timestamp',
        'created_at',
        'event_time',
      ], fallback: 'Unknown date'),
      location: _readString(map, <String>[
        'location',
        'area',
        'city',
        'region',
      ], fallback: 'Location unavailable'),
      impactSummary: _readString(map, <String>[
        'impact',
        'impact_summary',
        'impact_note',
      ], fallback: 'Operational impact being assessed.'),
      relatedClaimId: _readString(map, <String>[
        'related_claim_id',
        'claim_id',
      ], fallback: 'N/A'),
    );
  }

  static List<EventRecord> fallbackList() {
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
