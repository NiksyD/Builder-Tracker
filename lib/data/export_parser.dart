import 'dart:convert';
import '../models/upgrade.dart';
import 'game_data.dart';

class ImportResult {
  final List<Upgrade> upgrades;
  final int homeBuilders;
  final int baseBuilders;
  const ImportResult(this.upgrades, this.homeBuilders, this.baseBuilders);
}

/// Parses the JSON from Clash of Clans' in-game
/// Settings > More Settings > Help and Support > Data Export.
///
/// Timers in the export are *seconds remaining at export time*, so we convert
/// them to absolute end times using [exportedAt] (defaults to now).
class ExportParser {
  static const _builderHutId = 1000015;

  static ImportResult parse(String raw,
      {DateTime? exportedAt, GameData data = GameData.empty}) {
    final json = jsonDecode(raw);
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Export must be a JSON object');
    }
    // Timers are "seconds left at export time", so anchor to the export's own
    // timestamp when present (the user may import it hours later).
    final ts = json['timestamp'];
    final now = exportedAt ??
        (ts is int ? DateTime.fromMillisecondsSinceEpoch(ts * 1000) : DateTime.now());
    final out = <Upgrade>[];
    var homeBuilders = 0;

    void scan(String key, Village v, {bool lab = false}) {
      final list = json[key];
      if (list is! List) return;
      for (final e in list) {
        if (e is! Map) continue;
        final id = e['data'] as int?;
        final timer = e['timer'] as int?;
        if (id == null) continue;
        if (!lab && v == Village.home && id == _builderHutId) {
          homeBuilders += (e['cnt'] as int?) ?? 1;
        }
        if (timer != null && timer > 0) {
          final name = data.name(id) ?? 'Item #$id';
          final lvl = e['lvl'];
          final target = lvl is int ? lvl + 1 : null;
          final total = target == null ? null : data.buildTime(id, target);
          final end = now.add(Duration(seconds: timer));
          out.add(Upgrade(
            id: '${lab ? 'lab' : v.name}-$id-${out.length}',
            lab: lab,
            village: v,
            name: target != null ? '$name  ›  Level $target' : name,
            // Real total when known, so the progress bar is accurate.
            startedAt: total != null && total.inSeconds >= timer ? end.subtract(total) : now,
            endsAt: end,
          ));
        }
      }
    }

    scan('buildings', Village.home);
    scan('traps', Village.home);
    scan('heroes', Village.home);
    for (final k in const ['units', 'spells', 'siege_machines']) {
      scan(k, Village.home, lab: true);
    }
    scan('units2', Village.builderBase, lab: true);
    scan('buildings2', Village.builderBase);
    scan('traps2', Village.builderBase);
    scan('heroes2', Village.builderBase);
    // The game counts the Builder's Apprentice (helper 93000000) as an extra
    // builder slot (e.g. "1/6" with 5 huts). Inferred from one real export.
    final helpers = json['helpers'];
    final hasApprentice =
        helpers is List && helpers.any((h) => h is Map && h['data'] == 93000000);
    if (homeBuilders > 0 && hasApprentice) homeBuilders += 1;
    return ImportResult(
      out,
      homeBuilders == 0 ? 5 : homeBuilders,
      2,
    );
  }
}
