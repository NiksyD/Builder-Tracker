import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'data/tracker_store.dart';
import 'services/notification_service.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  final store = TrackerStore();
  await store.load();
  runApp(BuilderTrackerApp(store: store));
}

class BuilderTrackerApp extends StatelessWidget {
  final TrackerStore store;
  const BuilderTrackerApp({super.key, required this.store});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Builder Tracker',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        builder: (context, child) => DefaultTextStyle.merge(
          style: GoogleFonts.inter(color: G.text),
          child: child!,
        ),
        home: HomeScreen(store: store),
      );
}
