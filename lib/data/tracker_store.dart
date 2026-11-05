import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/account.dart';
import '../models/upgrade.dart';
import '../services/notification_service.dart';
import '../services/widget_service.dart';

class TrackerStore extends ChangeNotifier {
  static const _key = 'tracker_v2';
  static const _legacyKey = 'tracker_v1';

  List<Account> accounts = [Account(id: 'main', name: 'Main')];
  String activeId = 'main';

  Account get active => accounts.firstWhere((a) => a.id == activeId, orElse: () => accounts.first);

  List<Upgrade> get upgrades => active.upgrades;
  int get homeBuilders => active.homeBuilders;
  int get baseBuilders => active.baseBuilders;

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final s = p.getString(_key);
      if (s != null) {
        final j = jsonDecode(s) as Map<String, dynamic>;
        final list = [
          for (final a in j['accounts'] as List) Account.fromJson(a as Map<String, dynamic>)
        ];
        if (list.isNotEmpty) {
          accounts = list;
          activeId = j['active'] as String? ?? list.first.id;
        }
      } else {
        // Migrate single-account data from v1.
        final old = p.getString(_legacyKey);
        if (old != null) {
          final j = jsonDecode(old) as Map<String, dynamic>;
          accounts = [Account.fromJson({...j, 'id': 'main', 'name': 'Main'})];
          activeId = 'main';
        }
      }
    } catch (_) {
      // Corrupt data: start clean rather than crash.
    }
    notifyListeners();
    _push();
  }

  void _push() {
    NotificationService.instance.sync(accounts);
    WidgetService.sync(accounts, activeId);
  }

  Future<void> _save() async {
    _push();
    final p = await SharedPreferences.getInstance();
    await p.setString(
        _key,
        jsonEncode({
          'active': activeId,
          'accounts': [for (final a in accounts) a.toJson()],
        }));
  }

  Future<void> _commit() async {
    notifyListeners();
    await _save();
  }

  List<Upgrade> of(Village v) =>
      (upgrades.where((u) => u.village == v).toList()..sort((a, b) => a.endsAt.compareTo(b.endsAt)));

  int builders(Village v) => v == Village.home ? homeBuilders : baseBuilders;

  // ---- accounts ----

  Future<void> addAccount(String name) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    accounts = [...accounts, Account(id: id, name: name.trim().isEmpty ? 'Account ${accounts.length + 1}' : name.trim())];
    activeId = id;
    await _commit();
  }

  Future<void> switchTo(String id) async {
    if (id == activeId || !accounts.any((a) => a.id == id)) return;
    activeId = id;
    await _commit();
  }

  Future<void> rename(String id, String name) async {
    final n = name.trim();
    if (n.isEmpty) return;
    accounts.firstWhere((a) => a.id == id).name = n;
    await _commit();
  }

  Future<void> removeAccount(String id) async {
    if (accounts.length <= 1) return;
    accounts = accounts.where((a) => a.id != id).toList();
    if (activeId == id) activeId = accounts.first.id;
    await _commit();
  }

  // ---- active account data ----

  Future<void> replaceAll(List<Upgrade> list, {int? home, int? base}) async {
    active.upgrades = list;
    if (home != null) active.homeBuilders = home;
    if (base != null) active.baseBuilders = base;
    await _commit();
  }

  Future<void> add(Upgrade u) async {
    active.upgrades = [...active.upgrades, u];
    await _commit();
  }

  Future<void> remove(String id) async {
    active.upgrades = active.upgrades.where((u) => u.id != id).toList();
    await _commit();
  }

  Future<void> setBuilders(Village v, int n) async {
    if (v == Village.home) {
      active.homeBuilders = n;
    } else {
      active.baseBuilders = n;
    }
    await _commit();
  }
}
