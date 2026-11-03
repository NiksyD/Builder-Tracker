<div align="center">

<img src="assets/icon/icon.png" width="120" alt="Builder Tracker icon" />

# ⚒️ Builder Tracker

**Never leave a builder idle again.**
A Clash of Clans upgrade tracker for Home Village and Builder Base, with alerts and a home-screen widget.

*Carved in stone · framed in wood · written on parchment*

</div>

---

## 📜 The Scroll of Features

| | |
|---|---|
| 🏰 **Two villages** | Home Village and Builder Base, one tab each |
| 🔨 **Every builder, one glance** | A card per builder: what it's upgrading, time left, progress, or **Free!** |
| ⏳ **Live countdowns** | Ticks every second, and stays correct while the app is closed |
| 🔔 **Builder alerts** | A heads-up 10 minutes before an upgrade finishes, and another when the builder is free |
| 🧩 **Home-screen widget** | Village tabs, a scrollable list, and live countdowns without opening the app |
| 📥 **Data Export import** | Paste the game's own export and everything fills in, with real names and accurate progress |

> **Platform:** Android. Notifications and the widget are Android-only.

---

## 🪵 How to Fill Your Ledger

The game doesn't let other apps read your live builder timers, so the app reads the official **Data Export** instead.

1. In Clash of Clans open **Settings → More Settings → Help and Support → Data Export**.
2. Copy the JSON.
3. In Builder Tracker tap the **⬇ import** icon, paste, and tap **Import**.

Export right before you import. Timers are measured from the moment of the export, and the app uses the export's own timestamp, so a short delay is fine.

### What's tracked

- Building, trap and hero upgrades in **Home Village** and **Builder Base**
- The builder count (Builder's Huts, plus the Builder's Apprentice if you have one). Tap the "x of y builders free" pill to correct it.

### What's not tracked

- Lab research and pet timers (they don't use builders)
- Anything that changes in-game after you export. Gem-finishing an upgrade or starting a new one means a fresh export and import.

---

## 🧩 The Widget

Long-press your home screen → **Widgets** → **Builder Tracker**.

- Tap **Home Village** or **Builder Base** to switch lists.
- Each builder is a row. Idle builders read **Free**, finished ones read **Ready!**
- It's resizable, and the list scrolls if the widget is short.
- Tap the widget to open the app.

---

## 🗺️ Under the Hood

```
lib/
├── main.dart                     app entry
├── theme/app_theme.dart          palette & type
├── widgets/                      stone background, wood panel, parchment card, groove bar
├── screens/                      home (tabs + builder cards), import
├── data/
│   ├── export_parser.dart        Data Export JSON → upgrades
│   ├── game_data.dart            building names & build times
│   └── tracker_store.dart        saved state
├── models/upgrade.dart           upgrade + end-time maths
└── services/
    ├── notification_service.dart scheduled alerts
    └── widget_service.dart       feeds the home-screen widget

android/…/BuilderWidgetProvider.kt   widget (tabs, countdowns)
android/…/BuilderWidgetService.kt    widget list rows
assets/game_data.json                names + per-level build times
```

Upgrades are stored as **absolute end times**, which is why countdowns, alerts and the widget all stay correct without the app running.

---

## 🛠️ Raise the Keep (Development)

**Requirements:** Flutter (Dart `^3.13`), Android SDK, a device or emulator.

```bash
flutter pub get
flutter run                 # run on a connected Android device
flutter test                # parser & formatting tests
flutter analyze
flutter build apk --debug
```

Regenerate the launcher icon after changing the art in `assets/icon/`:

```bash
dart run flutter_launcher_icons
```

### Notes

- Android 13+ asks for notification permission. For on-time alerts, allow **exact alarms** when prompted.
- After changing the widget's layout, remove the widget from your home screen and add it again. Android keeps the old layout on a placed widget.
- Gradle memory is set to 3 GB in `android/gradle.properties`. Raise it if you have the RAM to spare.

---

## ⚖️ Fine Print

This is an unofficial fan project and is not affiliated with or endorsed by Supercell. *Clash of Clans* and its artwork, including the Builder's Hut used in the icon, belong to Supercell. Building names and build times in `assets/game_data.json` come from publicly available game data. It only reads the export **you** paste in and never touches your account.

Replace the icon art with your own before publishing anywhere public.
