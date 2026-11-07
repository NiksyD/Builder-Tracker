import 'package:clash_builder/data/export_parser.dart';
import 'package:clash_builder/data/game_data.dart';
import 'package:clash_builder/models/upgrade.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  labTest();
  test('parser converts remaining seconds to end times', () {
    final t = DateTime(2026, 1, 1);
    final r = ExportParser.parse(
      '{"buildings":[{"data":1000008,"lvl":20,"timer":3600},'
      '{"data":1000015,"cnt":5}],"buildings2":[{"data":1000099,"timer":60}]}',
      exportedAt: t,
      data: const GameData({
        1000008: (name: 'Cannon', times: [10, 20, 3600])
      }),
    );
    expect(r.upgrades.length, 2);
    expect(r.upgrades.first.name, 'Cannon  ›  Level 21');
    expect(r.upgrades.first.endsAt, t.add(const Duration(hours: 1)));
    expect(r.upgrades.last.village, Village.builderBase);
    expect(r.homeBuilders, 5);
  });

  test('formatDuration', () {
    expect(formatDuration(Duration.zero), 'Ready!');
    expect(formatDuration(const Duration(minutes: 9, seconds: 5)), '9m 5s');
  });
}

void labTest() {
  test('lab research is parsed separately from builders', () {
    final r = ExportParser.parse(
      '{"timestamp":1000,"buildings":[{"data":1000015,"lvl":1,"cnt":5}],'
      '"units":[{"data":4000000,"lvl":4,"timer":3600}],'
      '"units2":[{"data":4000037,"lvl":7,"timer":600}]}',
      exportedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
    expect(r.upgrades.where((u) => u.lab).length, 2);
    expect(r.upgrades.where((u) => !u.lab), isEmpty);
    expect(r.homeBuilders, 5);
  });
}
