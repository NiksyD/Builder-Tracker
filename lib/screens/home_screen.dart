import 'dart:async';
import 'package:flutter/material.dart';
import '../data/tracker_store.dart';
import '../models/upgrade.dart';
import '../theme/app_theme.dart';
import '../widgets/groove_progress.dart';
import '../widgets/parchment_card.dart';
import '../widgets/stone_background.dart';
import '../widgets/wood_panel.dart';
import 'import_screen.dart';

class HomeScreen extends StatefulWidget {
  final TrackerStore store;
  const HomeScreen({super.key, required this.store});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Village _village = Village.home;
  late final Timer _tick;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  Future<void> _editBuilders(TrackerStore store) async {
    var n = store.builders(_village);
    final v = _village;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          backgroundColor: Pal.parchment,
          title: Text('Number of builders', style: inkStyle(size: 24, w: FontWeight.w800)),
          content: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(
                onPressed: n > 1 ? () => set(() => n--) : null,
                icon: const Icon(Icons.remove_circle, color: Pal.ink, size: 32)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('$n', style: inkStyle(size: 30, w: FontWeight.w800)),
            ),
            IconButton(
                onPressed: n < 10 ? () => set(() => n++) : null,
                icon: const Icon(Icons.add_circle, color: Pal.ink, size: 32)),
          ]),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Pal.wood),
              onPressed: () {
                store.setBuilders(v, n);
                Navigator.pop(ctx);
              },
              child: Text('Save',
                  style: inkStyle(size: 17, w: FontWeight.w800).copyWith(color: Pal.parchment)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final store = widget.store;
        final ups = store.of(_village);
        final total = store.builders(_village);
        final slots = List<Upgrade?>.generate(
            total > ups.length ? total : ups.length, (i) => i < ups.length ? ups[i] : null);
        final free = slots.where((s) => s == null).length;

        return Scaffold(
          body: StoneBackground(
            child: SafeArea(
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                  child: Row(children: [
                    Expanded(child: Text('Builder Tracker', style: titleStyle(size: 26))),
                    IconButton(
                      tooltip: 'Import game export',
                      icon: const Icon(Icons.file_download, color: Pal.gold),
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => ImportScreen(store: store))),
                    ),
                  ]),
                ),
                _VillageTabs(
                  selected: _village,
                  onChanged: (v) => setState(() => _village = v),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: GestureDetector(
                    onTap: () => _editBuilders(store),
                    child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Pal.goldDark),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Text('$free of ${slots.length} builders free', style: GoogleSafe.sub),
                    ),
                  )),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                    itemCount: slots.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (_, i) => _BuilderCard(
                      index: i + 1,
                      upgrade: slots[i],
                      now: _now,
                    ),
                  ),
                ),
              ]),
            ),
          ),
        );
      },
    );
  }
}

class GoogleSafe {
  static final sub = inkStyle(size: 17, w: FontWeight.w700).copyWith(color: Pal.parchment);
}

class _VillageTabs extends StatelessWidget {
  final Village selected;
  final ValueChanged<Village> onChanged;
  const _VillageTabs({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: WoodPanel(
          padding: const EdgeInsets.all(8),
          child: Row(children: [
            for (final v in Village.values)
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(v),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: v == selected ? Pal.woodDark : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: v == selected ? Border.all(color: Pal.gold, width: 1.5) : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      v == Village.home ? 'Home Village' : 'Builder Base',
                      style: inkStyle(size: 18, w: FontWeight.w800).copyWith(
                        color: v == selected ? Pal.gold : Pal.parchment,
                      ),
                    ),
                  ),
                ),
              ),
          ]),
        ),
      );
}

class _BuilderCard extends StatelessWidget {
  final int index;
  final Upgrade? upgrade;
  final DateTime now;
  const _BuilderCard(
      {required this.index, required this.upgrade, required this.now});

  @override
  Widget build(BuildContext context) {
    final u = upgrade;
    final rem = u?.remaining(now);
    final soon = rem != null && rem > Duration.zero && rem < const Duration(minutes: 15);
    final done = u != null && rem == Duration.zero;
    final color = done ? Pal.gold : soon ? Pal.red : Pal.green;

    return WoodPanel(
      padding: const EdgeInsets.all(10),
      child: ParchmentCard(
        padding: const EdgeInsets.all(14),
        child: u == null
            ? Row(children: [
                const Icon(Icons.hardware, color: Pal.goldDark),
                const SizedBox(width: 10),
                Expanded(child: Text('Builder $index — Idle', style: inkStyle(size: 18))),
                Text('Free!', style: inkStyle(size: 18).copyWith(color: Pal.green)),
              ])
            : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Builder $index', style: inkStyle(size: 15, w: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(u.name, style: inkStyle(size: 21, w: FontWeight.w800)),
                const SizedBox(height: 8),
                GrooveProgress(value: u.progress(now), color: color),
                const SizedBox(height: 6),
                Row(children: [
                  Text(
                    formatDuration(rem!),
                    style: inkStyle(size: 22, w: FontWeight.w800)
                        .copyWith(color: done ? Pal.goldDark : soon ? Pal.red : Pal.ink),
                  ),
                  const Spacer(),
                  Text('${(u.progress(now) * 100).floor()}%',
                      style: inkStyle(size: 16, w: FontWeight.w700)),
                ]),
              ]),
      ),
    );
  }
}
