import 'dart:async';
import 'package:flutter/material.dart';
import '../data/tracker_store.dart';
import '../models/upgrade.dart';
import '../theme/app_theme.dart';
import '../widgets/glass.dart';
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
        builder: (ctx, set) => Dialog(
          backgroundColor: Colors.transparent,
          child: GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('Number of builders', style: headline(size: 20)),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _RoundBtn(Icons.remove, n > 1 ? () => set(() => n--) : null),
                SizedBox(width: 72, child: Center(child: Text('$n', style: timer(size: 40)))),
                _RoundBtn(Icons.add, n < 10 ? () => set(() => n++) : null),
              ]),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: G.blue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const StadiumBorder(),
                  ),
                  onPressed: () {
                    store.setBuilders(v, n);
                    Navigator.pop(ctx);
                  },
                  child: Text('Save', style: body(w: FontWeight.w700, color: G.bg0)),
                ),
              ),
            ]),
          ),
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
        final count = total > ups.length ? total : ups.length;
        final slots = List<Upgrade?>.generate(count, (i) => i < ups.length ? ups[i] : null);
        final free = slots.where((s) => s == null).length;

        return Scaffold(
          body: GlassBackground(
            child: SafeArea(
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 16, 12),
                  child: Row(children: [
                    Expanded(child: Text('Builders', style: largeTitle())),
                    _RoundBtn(
                      Icons.file_download_outlined,
                      () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => ImportScreen(store: store))),
                    ),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GlassSegmented(
                    labels: const ['Home Village', 'Builder Base'],
                    selected: _village.index,
                    onChanged: (i) => setState(() => _village = Village.values[i]),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(26, 14, 20, 6),
                  child: GestureDetector(
                    onTap: () => _editBuilders(store),
                    behavior: HitTestBehavior.opaque,
                    child: Row(children: [
                      Text('$free of ${slots.length} builders free', style: dim(size: 15)),
                      const SizedBox(width: 6),
                      Icon(Icons.tune_rounded, size: 16, color: G.textDim),
                    ]),
                  ),
                ),
                Expanded(
                  child: ShaderMask(
                    blendMode: BlendMode.dstIn,
                    shaderCallback: (r) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black, Colors.black, Colors.transparent],
                      stops: [0, 0.03, 0.95, 1],
                    ).createShader(r),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                      itemCount: slots.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (_, i) => _BuilderCard(index: i + 1, upgrade: slots[i], now: _now),
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

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _RoundBtn(this.icon, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity: onTap == null ? 0.4 : 1,
          child: GlassCard(
            radius: 24,
            padding: const EdgeInsets.all(12),
            child: Icon(icon, size: 22, color: G.text),
          ),
        ),
      );
}

class _BuilderCard extends StatelessWidget {
  final int index;
  final Upgrade? upgrade;
  final DateTime now;
  const _BuilderCard({required this.index, required this.upgrade, required this.now});

  @override
  Widget build(BuildContext context) {
    final u = upgrade;
    if (u == null) {
      return GlassCard(
        child: Row(children: [
          const _Dot(G.green),
          const SizedBox(width: 12),
          Expanded(child: Text('Builder $index', style: headline())),
          Text('Free', style: body(size: 17, color: G.green, w: FontWeight.w700)),
        ]),
      );
    }
    final rem = u.remaining(now);
    final done = rem == Duration.zero;
    final soon = !done && rem < const Duration(minutes: 15);
    final color = done ? G.green : soon ? G.orange : G.blue;

    return GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('Builder $index', style: dim(size: 13))),
          Text(formatDuration(rem), style: timer(size: 22, color: G.text)),
        ]),
        const SizedBox(height: 4),
        Text(u.name, style: headline(size: 19)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: GlassProgress(value: u.progress(now), color: color)),
          const SizedBox(width: 12),
          Text('${(u.progress(now) * 100).floor()}%', style: dim(size: 14)),
        ]),
      ]),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot(this.color);
  @override
  Widget build(BuildContext context) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.7), blurRadius: 8)],
        ),
      );
}
