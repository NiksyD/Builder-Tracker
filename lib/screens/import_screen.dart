import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/export_parser.dart';
import '../data/game_data.dart';
import '../data/tracker_store.dart';
import '../theme/app_theme.dart';
import '../widgets/glass.dart';

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
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: const IconThemeData(color: G.text),
          title: Text('Import · ${widget.store.active.name}', style: headline(size: 20)),
        ),
        body: GlassBackground(
          child: SafeArea(
            child: ListView(padding: const EdgeInsets.all(20), children: [
              GlassCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('From Clash of Clans', style: headline(size: 20)),
                  const SizedBox(height: 8),
                  Text(
                    'Settings → More Settings → Help and Support → Data Export. '
                    'Copy the JSON, then paste it below.',
                    style: dim(size: 15),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _ctrl,
                    maxLines: 8,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: G.text),
                    cursorColor: G.blue,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.35),
                      hintText: '{"buildings": [...]}',
                      hintStyle: dim(size: 14),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(_error!, style: body(size: 14, color: G.red)),
                    ),
                  const SizedBox(height: 16),
                  Row(children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: G.text,
                        side: BorderSide(color: G.hairline),
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                      onPressed: _paste,
                      icon: const Icon(Icons.content_paste_rounded, size: 18),
                      label: Text('Paste', style: body(size: 15, w: FontWeight.w600)),
                    ),
                    const Spacer(),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: G.blue,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                      ),
                      onPressed: _import,
                      child: Text('Import', style: body(size: 15, w: FontWeight.w700, color: G.bg0)),
                    ),
                  ]),
                ]),
              ),
            ]),
          ),
        ),
      );
}
