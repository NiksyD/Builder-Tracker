import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/upgrade.dart';
import '../services/notification_service.dart';
import '../services/widget_service.dart';

class TrackerStore extends ChangeNotifier {
  static const _key = 'tracker_v1';
  List<Upgrade> upgrades = [];
  int homeBuilders = 5;
  int baseBuilders = 2;

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final s = p.getString(_key);
      if (s == null) return;
      final j = jsonDecode(s) as Map<String, dynamic>;
      homeBuilders = j['home'] as int? ?? 5;
      baseBuilders = j['base'] as int? ?? 2;
      upgrades = [
        for (final u in j['upgrades'] as List) Upgrade.fromJson(u as Map<String, dynamic>)
      ];
    } catch (_) {
      // Corrupt data: start clean rather than crash.
    }
    notifyListeners();
    NotificationService.instance.sync(upgrades);
    WidgetService.sync(upgrades, home: homeBuilders, base: baseBuilders);
  }

  Future<void> _save() async {
    NotificationService.instance.sync(upgrades);
    WidgetService.sync(upgrades, home: homeBuilders, base: baseBuilders);
    final p = await SharedPreferences.getInstance();
    await p.setString(
        _key,
        jsonEncode({
          'home': homeBuilders,
          'base': baseBuilders,
          'upgrades': [for (final u in upgrades) u.toJson()],
        }));
  }

  List<Upgrade> of(Village v) =>
      (upgrades.where((u) => u.village == v).toList()..sort((a, b) => a.endsAt.compareTo(b.endsAt)));

  int builders(Village v) => v == Village.home ? homeBuilders : baseBuilders;

  Future<void> replaceAll(List<Upgrade> list, {int? home, int? base}) async {
    upgrades = list;
    if (home != null) homeBuilders = home;
    if (base != null) baseBuilders = base;
    notifyListeners();
    await _save();
  }

  Future<void> add(Upgrade u) async {
    upgrades = [...upgrades, u];
    notifyListeners();
    await _save();
  }

  Future<void> remove(String id) async {
    upgrades = upgrades.where((u) => u.id != id).toList();
    notifyListeners();
    await _save();
  }

  Future<void> setBuilders(Village v, int n) async {
    if (v == Village.home) {
      homeBuilders = n;
    } else {
      baseBuilders = n;
    }
    notifyListeners();
    await _save();
  }
}
