import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/export_parser.dart';
import '../data/game_data.dart';
import '../data/tracker_store.dart';
import '../theme/app_theme.dart';
import '../widgets/parchment_card.dart';
import '../widgets/stone_background.dart';
import '../widgets/wood_panel.dart';

class ImportScreen extends StatefulWidget {
  final TrackerStore store;
  const ImportScreen({super.key, required this.store});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final _ctrl = TextEditingController();
  String? _error;

  Future<void> _paste() async {
    final d = await Clipboard.getData(Clipboard.kTextPlain);
    if (d?.text != null) setState(() => _ctrl.text = d!.text!);
  }

  Future<void> _import() async {
    try {
      final r = ExportParser.parse(_ctrl.text, data: await GameData.load());
      await widget.store.replaceAll(r.upgrades, home: r.homeBuilders, base: r.baseBuilders);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Imported ${r.upgrades.length} upgrades')));
      Navigator.pop(context);
    } catch (e) {
      setState(() => _error = 'Could not read export: $e');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: Pal.woodDark,
          title: Text('Import', style: titleStyle(size: 24)),
          iconTheme: const IconThemeData(color: Pal.gold),
        ),
        body: StoneBackground(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            WoodPanel(
              child: ParchmentCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('In Clash of Clans:', style: inkStyle(size: 19, w: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(
                    'Settings → More Settings → Help and Support → Data Export.\n'
                    'Copy the JSON, then paste it below.',
                    style: inkStyle(size: 16, w: FontWeight.w500),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _ctrl,
                    maxLines: 8,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: Pal.ink),
                    decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        hintText: '{"buildings": [...]}',
                        hintStyle: inkStyle(size: 15, w: FontWeight.w500)
                            .copyWith(color: Pal.ink.withValues(alpha: 0.6))),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_error!, style: inkStyle(size: 16, w: FontWeight.w700).copyWith(color: Pal.red)),
                    ),
                  const SizedBox(height: 10),
                  Row(children: [
                    OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                            foregroundColor: Pal.ink, side: const BorderSide(color: Pal.ink)),
                        onPressed: _paste,
                        icon: const Icon(Icons.paste),
                        label: Text('Paste', style: inkStyle(size: 17, w: FontWeight.w800))),
                    const Spacer(),
                    FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: Pal.wood),
                        onPressed: _import,
                        child: Text('Import',
                            style: inkStyle(size: 17, w: FontWeight.w800).copyWith(color: Pal.parchment))),
                  ]),
                ]),
              ),
            ),
          ]),
        ),
      );
}
