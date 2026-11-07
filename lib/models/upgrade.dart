enum Village { home, builderBase }

/// A running upgrade. Stored as an absolute end time so it stays correct
/// while the app is closed.
class Upgrade {
  final String id;
  final Village village;
  final String name;
  final DateTime startedAt;
  final DateTime endsAt;

  /// True for laboratory research (uses the lab, not a builder).
  final bool lab;

  const Upgrade({
    required this.id,
    required this.village,
    required this.name,
    required this.startedAt,
    required this.endsAt,
    this.lab = false,
  });

  Duration remaining([DateTime? now]) {
    final d = endsAt.difference(now ?? DateTime.now());
    return d.isNegative ? Duration.zero : d;
  }

  bool isDone([DateTime? now]) => remaining(now) == Duration.zero;

  double progress([DateTime? now]) {
    final total = endsAt.difference(startedAt).inSeconds;
    if (total <= 0) return 1;
    return (1 - remaining(now).inSeconds / total).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'village': village.name,
        'name': name,
        'startedAt': startedAt.toIso8601String(),
        'endsAt': endsAt.toIso8601String(),
        'lab': lab,
      };

  factory Upgrade.fromJson(Map<String, dynamic> j) => Upgrade(
        id: j['id'] as String,
        village: Village.values.byName(j['village'] as String),
        name: j['name'] as String,
        startedAt: DateTime.parse(j['startedAt'] as String),
        endsAt: DateTime.parse(j['endsAt'] as String),
        lab: j['lab'] as bool? ?? false,
      );
}

String formatDuration(Duration d) {
  if (d == Duration.zero) return 'Ready!';
  final days = d.inDays;
  final h = d.inHours % 24, m = d.inMinutes % 60, s = d.inSeconds % 60;
  if (days > 0) return '${days}d ${h}h ${m}m';
  if (d.inHours > 0) return '${d.inHours}h ${m}m ${s}s';
  return '${m}m ${s}s';
}
