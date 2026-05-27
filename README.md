# My Namaz

Track your daily Salah — an offline-first Flutter app for the five daily Islamic prayers.

## Features

- **Mobile-only login** — no OTP, no SMS, no backend. Just enter your number, name, and (optionally) email.
- **Daily tracker** for any date — tap to mark Fajr, Dhuhr, Asr, Maghrib, Isha as completed.
- **Hijri + Gregorian** dates side by side.
- **Calendar view** with green/yellow/red dots per day.
- **Reports** — week/month/year/all-time with bar, line, pie charts and a 6-month heatmap.
- **Table report** — date × prayer matrix, exportable to CSV and PDF.
- **Qibla compass** — live magnetometer-driven needle pointing to Mecca, with haptic feedback at ±5°.
- **Profile** with name, email, mobile, city, and avatar (gallery or camera).
- **Settings** — light/dark/system theme, English/Arabic/Urdu, prayer-time reminders, Hijri toggle, JSON backup export, logout, delete-all.
- **Privacy** — everything is stored locally on the device. Nothing is sent to any server.

## Run

```bash
flutter pub get
flutter gen-l10n
flutter run
```

### iOS

```bash
cd ios
LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 pod install
cd ..
flutter run -d iphone        # or "flutter run -d <simulator-id>"
```

The Qibla compass requires a **physical iPhone** — the iOS simulator has no magnetometer.

### Android

```bash
flutter run -d android
```

### macOS

```bash
flutter run -d macos
```

The macOS build supports the full app **except live compass rotation** — there's no magnetometer on a Mac. The Qibla screen still shows the bearing from north and distance to Mecca based on your location, just without a needle that rotates with the device.

On first run you'll be prompted for Location and Camera permissions. macOS uses SQLite via the FFI backend (auto-selected at runtime).

## Build

```bash
flutter build ios --release            # requires signing
flutter build ios --no-codesign        # ad-hoc build
flutter build apk --release
flutter build macos --release
```

## Install on a real device

See [INSTALL.md](INSTALL.md) for full step-by-step instructions for both:
- 📱 **iPhone** — sideload via Xcode (free, 7 days) or TestFlight (paid developer account)
- 🤖 **Android** — build APK and copy to phone (no developer account needed)

## Tech

- **Flutter** + **Material 3** themed in deep green and gold.
- **Riverpod** for state, **go_router** for navigation.
- **sqflite** for prayer records and user profile.
- **fl_chart** for visualizations, **table_calendar** for the calendar view.
- **flutter_qiblah** + **flutter_compass** + **geolocator** for the Qibla screen.
- **flutter_local_notifications** for daily reminders.
- **pdf** + **csv** + **share_plus** for export.
- **hijri** for Islamic dates.

## Project structure

```
lib/
  main.dart                application entry, seeds sample data
  app.dart                 MaterialApp.router with theme + i18n
  router.dart              go_router with auth gate
  models/                  UserProfile, PrayerRecord, Prayer enum
  data/                    sqflite database + DAOs
  providers/               Riverpod providers
  screens/                 8 screens: login, home, calendar, reports,
                           table_report, qibla, profile, settings
  widgets/                 PrayerCard, InitialsAvatar, CompassDial, StatCard
  services/                stats, qibla, export, backup, notifications
  utils/                   dates, validators, constants
  theme/                   Material 3 light + dark
  l10n/                    en/ar/ur ARB files
```

## Privacy

All your data — profile, photo, and prayer records — is stored only on this device.
No analytics. No telemetry. No backend.

The only network calls in the app are optional and explicit: the `geocoding` package
resolves your coordinates to a city name on the Qibla screen using the OS-provided
geocoder (no third-party server).
# my_namaz
