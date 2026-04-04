enum RecordStatus { active, pending, resolved }

class PlaceholderRecord {
  const PlaceholderRecord({
    required this.title,
    required this.subtitle,
    required this.status,
  });

  final String title;
  final String subtitle;
  final RecordStatus status;
}
