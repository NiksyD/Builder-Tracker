import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../models/account.dart';
import '../models/upgrade.dart';

/// Pushes every account to the Android home-screen widget as a vertical list
/// (one card per account). The widget draws live countdowns itself, so
/// this only runs on data changes.
class WidgetService {
  static bool get _supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<void> sync(List<Account> accounts, String activeId) async {
    if (!_supported) return;
    try {
      // Active account first so it is the page you see by default.
      final ordered = [
        ...accounts.where((a) => a.id == activeId),
        ...accounts.where((a) => a.id != activeId),
      ];
      final multi = accounts.length > 1;
      final data = [
        for (final a in ordered)
          {
            'name': multi ? a.name : '',
            'villages': [
              for (final v in Village.values)
                {
                  'title': v == Village.home ? 'Home Village' : 'Builder Base',
                  'total': v == Village.home ? a.homeBuilders : a.baseBuilders,
                  'items': [
                    for (final u in a.upgrades.where((u) => u.village == v && !u.lab))
                      {'name': u.name, 'endsAt': u.endsAt.millisecondsSinceEpoch}
                  ],
                  'lab': {
                    'label': v == Village.home ? 'Laboratory' : 'Star Laboratory',
                    'items': [
                      for (final u in a.upgrades.where((u) => u.village == v && u.lab))
                        {'name': u.name, 'endsAt': u.endsAt.millisecondsSinceEpoch}
                    ],
                  },
                }
            ],
          }
      ];
      await HomeWidget.saveWidgetData<String>('accounts_json', jsonEncode(data));
      await HomeWidget.updateWidget(qualifiedAndroidName: 'com.example.clash_builder.BuilderWidgetProvider');
    } catch (_) {
      // Widget is best-effort; never break the app over it.
    }
  }
}
