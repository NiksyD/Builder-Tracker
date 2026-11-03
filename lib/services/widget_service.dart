import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../models/upgrade.dart';

/// Pushes the current upgrades to the Android home-screen widget.
/// The widget draws live countdowns itself, so this only runs on data changes.
class WidgetService {
  static bool get _supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<void> sync(List<Upgrade> upgrades, {required int home, required int base}) async {
    if (!_supported) return;
    try {
      await HomeWidget.saveWidgetData<String>(
        'upgrades_json',
        jsonEncode([
          for (final u in upgrades)
            {
              'name': u.name,
              'village': u.village.name,
              'endsAt': u.endsAt.millisecondsSinceEpoch,
            }
        ]),
      );
      await HomeWidget.saveWidgetData<int>('home_builders', home);
      await HomeWidget.saveWidgetData<int>('base_builders', base);
      await HomeWidget.updateWidget(qualifiedAndroidName: 'com.example.clash_builder.BuilderWidgetProvider');
    } catch (_) {
      // Widget is best-effort; never break the app over it.
    }
  }
}
