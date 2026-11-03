import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// Name + per-level build times (seconds) for each game object id.
/// Generated from public static game data; see assets/game_data.json.
class GameData {
  final Map<int, ({String name, List<int> times})> _items;
  const GameData(this._items);
  static const empty = GameData({});

  static Future<GameData> load() async {
    final raw = jsonDecode(await rootBundle.loadString('assets/game_data.json'))
        as Map<String, dynamic>;
    return GameData({
      for (final e in raw.entries)
        int.parse(e.key): (
          name: (e.value['n'] as String),
          times: [for (final t in e.value['t'] as List) (t as num).toInt()],
        ),
    });
  }

  String? name(int id) => _items[id]?.name;

  /// Total build time to reach [level] (1-based), if known.
  Duration? buildTime(int id, int level) {
    final t = _items[id]?.times;
    if (t == null || level < 1 || level > t.length || t[level - 1] <= 0) return null;
    return Duration(seconds: t[level - 1]);
  }
}
