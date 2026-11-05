import 'upgrade.dart';

/// One Clash of Clans account: its own builders and running upgrades.
class Account {
  final String id;
  String name;
  int homeBuilders;
  int baseBuilders;
  List<Upgrade> upgrades;

  Account({
    required this.id,
    required this.name,
    this.homeBuilders = 5,
    this.baseBuilders = 2,
    List<Upgrade>? upgrades,
  }) : upgrades = upgrades ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'home': homeBuilders,
        'base': baseBuilders,
        'upgrades': [for (final u in upgrades) u.toJson()],
      };

  factory Account.fromJson(Map<String, dynamic> j) => Account(
        id: j['id'] as String,
        name: j['name'] as String? ?? 'Account',
        homeBuilders: j['home'] as int? ?? 5,
        baseBuilders: j['base'] as int? ?? 2,
        upgrades: [
          for (final u in (j['upgrades'] as List? ?? const []))
            Upgrade.fromJson(u as Map<String, dynamic>)
        ],
      );
}
