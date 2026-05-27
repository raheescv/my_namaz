# Flutter Namaz Tracker App — Build Prompt

Build a Flutter mobile app called **"My Namaz"** for tracking the five daily Islamic prayers (Salah), with mobile-number-only login, profile management, prayer tracking, comprehensive reports, and a Qibla compass. The app must be **offline-first** using local storage, with a clean, modern Material 3 UI and support for both light and dark themes.

---

## TECH STACK
- Flutter (latest stable, null-safe Dart)
- State management: **Riverpod** (preferred) or Provider
- Local DB: **sqflite** or **Isar**
- Routing: **go_router**
- Charts: **fl_chart** or syncfusion_flutter_charts
- Calendar: **table_calendar**
- Date utilities: **intl** package

### Packages to include
```yaml
flutter_riverpod: ^2.x
go_router: ^14.x
sqflite: ^2.x          # or isar / isar_flutter_libs
path_provider: ^2.x
shared_preferences: ^2.x
intl: ^0.19.x
intl_phone_field: ^3.x
image_picker: ^1.x
table_calendar: ^3.x
fl_chart: ^0.68.x
flutter_qiblah: ^2.x
geolocator: ^11.x
flutter_compass: ^0.8.x
permission_handler: ^11.x
geocoding: ^3.x
flutter_local_notifications: ^17.x
hijri: ^3.x
pdf: ^3.x
csv: ^6.x
share_plus: ^9.x
```

---

## CORE PRAYERS
- Fajr
- Dhuhr (Zuhr)
- Asr
- Maghrib
- Isha

---

## DATA MODELS

### UserProfile (single row, id always 1)
```
UserProfile {
  id            int    PK
  mobile        String required
  countryCode   String e.g. "+91"
  name          String required
  email         String optional, must be valid email if provided
  avatarPath    String optional — local file path
  city          String optional — used for prayer times later
  createdAt, updatedAt
}
```

### PrayerRecord
```
PrayerRecord {
  id        int PK
  date      DateTime — unique per day, stored as yyyy-MM-dd
  fajr      bool default false
  dhuhr     bool default false
  asr       bool default false
  maghrib   bool default false
  isha      bool default false
  notes     String optional
  createdAt, updatedAt
}
```

Each prayer conceptually has 3 states: **Completed / Missed / Qaza (made up later)**. Start with a `bool` (completed vs not), but design the model so a status enum can replace it later without a painful migration.

---

## ROUTES
```
/login         → Login screen (initial if not logged in)
/home          → Daily Tracker (initial if logged in)
/calendar      → Calendar view
/reports       → Charts and stats
/table-report  → Date × prayer matrix
/qibla         → Qibla compass
/profile       → User profile edit
/settings      → App settings
```

Bottom navigation tabs (5):
1. **Today** (Daily Tracker)
2. **Calendar**
3. **Reports**
4. **Qibla**
5. **Settings**

---

## SCREENS

### 0. Login Screen (first launch only)
Mobile-number-only authentication — **no OTP, no password, no backend**. Purely to identify and personalize the local user.

**Fields (in order):**
1. Mobile number — required, with country code dropdown (default +91, searchable list with flags via `intl_phone_field`)
2. Name — required (2–50 chars)
3. Email — optional, validate format only if entered

**Layout:**
- App logo and name "My Namaz" at the top with tagline "Track your daily Salah"
- Each field has a clear label and leading icon (phone / person / email)
- Large "Continue" button at the bottom — disabled until mobile + name are valid
- Disclaimer text: *"Your data is stored only on this device. No OTP, no SMS, nothing leaves your phone."*

**Behavior:**
- On Continue: save `UserProfile` row, set `isLoggedIn = true` in SharedPreferences, replace-navigate to Home
- On app launch, check `isLoggedIn` — go to Home if true, else Login
- Login is only shown once unless the user explicitly logs out

---

### 1. Home / Daily Tracker Screen (default after login)
- **Header:** small tappable avatar + "Assalamu Alaikum, {name}" greeting + today's Gregorian + Hijri date
- **Date picker bar** below the header: previous/next arrow buttons + tappable date label that opens a date picker + a "Today" button (visible only when not on today)
- **5 prayer cards**, each with:
  - Prayer name (English) + Arabic name
  - Large checkbox / toggle
  - Status icon: ✓ completed, ✗ missed, — pending
  - Subtle tap animation, **auto-save on toggle** (upsert: create if no record for the date, update if exists)
- **Summary chip at top:** "Today: 3 / 5 completed"
- **Streak indicator:** "🔥 7-day streak" — based on consecutive days where all 5 were prayed
- **Optional notes field** at the bottom of the day's card

UX rules: minimal taps to mark a prayer, **no confirmation dialogs**, large tap targets, instant load.

---

### 2. Calendar View Screen
- Month calendar via `table_calendar`, each day shows a small colored dot:
  - **Green** = all 5 prayed
  - **Yellow** = some prayed (1–4)
  - **Red** = none prayed
  - **Grey** = no data
- Show Hijri date alongside Gregorian for each day cell
- Tapping a date navigates to the Daily Tracker for that date
- Month/year switcher at the top
- Toggle to switch between month view and 2-week view

---

### 3. Reports / Statistics Screen
Segmented control at the top: **Daily | Weekly | Monthly | Yearly | Custom**

For each period show:
- Total prayed vs missed (number + percentage)
- Per-prayer breakdown bars (Fajr 80%, Dhuhr 95%, …) — surface Fajr if it's the lowest
- Best & worst prayer
- Current streak & longest streak
- **Bar chart:** completed vs missed per day/week/month
- **Pie chart:** distribution of which prayers are missed most
- **Line chart:** completion percentage trend over time
- **Heatmap** (GitHub-style) for the yearly view showing each day's completion

Custom range opens a date-range picker.

---

### 4. Table Report Screen
A scrollable, sticky-header table:

| Date | Fajr | Dhuhr | Asr | Maghrib | Isha | Total |
|------|------|-------|-----|---------|------|-------|
| 27 May 2026 | ✓ | ✓ | ✓ | ✓ | ✓ | 5/5 |
| 26 May 2026 | ✗ | ✓ | ✓ | ✓ | ✓ | 4/5 |

- Filterable by date range (this week / this month / custom)
- Color-code rows: green if 5/5, yellow if 3–4, red if 0–2
- Each cell tappable to jump to that day's tracker
- **Export buttons:** CSV and PDF (use `csv`, `pdf`, `share_plus`)
- Export filename: `namaz-{mobile}-{yyyy-MM-dd}-to-{yyyy-MM-dd}.csv`

---

### 5. Qibla Tracker Screen
Live compass that points toward the Kaaba in Mecca (21.4225°N, 39.8262°E).

**Implementation:**
- Use `flutter_qiblah` (handles sensor fusion internally) OR build manually with:
  - `geolocator` for current latitude/longitude
  - `flutter_compass` for magnetometer heading
  - Compute Qibla bearing using the great-circle formula:
    ```
    bearing = atan2(sin(Δλ)·cos(φ₂),
                    cos(φ₁)·sin(φ₂) − sin(φ₁)·cos(φ₂)·cos(Δλ))
    ```

**UI:**
- Full-screen circular compass dial with N, E, S, W cardinal markings
- Rotating outer ring showing current device heading
- Fixed Kaaba icon / green arrow pointing to Qibla direction
- **Haptic feedback** when device is within ±5° of Qibla
- Numeric readout below the dial:
  - Current heading (e.g., 142°)
  - Qibla direction (e.g., 287°)
  - Distance to Mecca (e.g., 4,832 km)
  - User location: lat, lon + city name (via reverse geocoding)
- Smooth rotation animation (~200ms, `AnimatedRotation`)
- Dark-mode-friendly compass face

**Permissions & edge cases:**
- Request location permission on first open — clear empty state with "Open Settings" button if denied
- Detect magnetic interference via `CompassEvent.accuracy` and overlay a "Calibrate — move device in a figure-8" hint when accuracy is low
- Cache last known location so compass still works without a fresh GPS fix
- Magnetometer requires a **physical device** (will not work in iOS simulator)

---

### 6. Profile Screen
Accessible from Settings → "My Profile" or by tapping the avatar/name on Home.

**Layout (scrollable):**
- Top: circular avatar (tap to pick from gallery/camera via `image_picker`; fallback to colored circle with initials)
- Below avatar: large name, email and mobile underneath
- **Editable form fields:**
  - Name (required, 2–50 chars)
  - Email (optional, validated)
  - Mobile + country code (editable with `intl_phone_field` validation)
  - City (optional — free text or autocomplete via `geocoding`)
- "Save" button — only enabled when something changed (dirty-state tracking)
- On save: update `user_profile` row, show SnackBar "Profile updated", pop back

**Avatar handling:**
- Pick from gallery or camera
- Copy selected image to app documents directory via `path_provider`, store local path
- Bottom sheet with "Remove photo" if avatar is set
- Initials avatar uses a deterministic color (hash of name → palette index)

---

### 7. Settings Screen
- **Profile card** at the top (avatar + name + email + mobile, tappable → Profile)
- Theme: light / dark / system
- Reminder notifications for each prayer time (`flutter_local_notifications`)
- Optional: fetch local prayer times by city (Aladhan API — keep optional)
- Hijri date toggle on/off
- Language: English / Arabic / Urdu (RTL respected for Arabic/Urdu)
- Backup & restore (export JSON / import JSON)
- Export all data as PDF report
- **Logout** (red) — confirmation: *"This clears your login but keeps your prayer data. Continue?"* → clears `isLoggedIn`, navigates to Login. **Prayer records survive logout.**
- **Delete all data** (destructive, separate) — wipes everything including prayer records

---

## REPORTS TO INCLUDE (full list)
1. Daily summary — today's 5/5 status
2. Weekly summary — last 7 days
3. Monthly summary — current month
4. Yearly summary — current year
5. Custom date range report
6. Per-prayer completion rate (which prayer do I miss most?)
7. Streak report — current and longest streaks (any-prayer streak and 5/5-day streak)
8. Day-of-week analysis (do I miss Fajr more on weekends?)
9. Consistency score — single 0–100 number based on last 30 days
10. Comparison report — this month vs last month, this year vs last year
11. **Missed prayers list** — chronological list of all missed prayers, useful as a Qaza tracker
12. **Heatmap calendar** — yearly visual of consistency
13. **Table report** — the date × prayer matrix described above
14. Export reports as **PDF** and **CSV**

---

## UX REQUIREMENTS
- Minimal taps to mark a prayer — tap-to-toggle, no confirmation dialogs
- Works fully **offline**
- Fast: home screen loads instantly with today's record
- Accessible: large tap targets, semantic labels
- Localization-ready (English + Arabic + Urdu, ARB files via `intl`)
- Respect RTL layout for Arabic/Urdu
- Islamic-themed but not gaudy color palette — greens, gold accents, deep teal in dark mode

---

## PRIVACY
Show on the Login screen and Settings:
> *"All your data — profile, photo, and prayer records — is stored only on this device. We do not send anything to any server."*

No analytics, no telemetry, no backend calls (the only network call is the optional Aladhan API for prayer times, which is opt-in).

---

## PLATFORM SETUP

### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.VIBRATE"/>
```
`minSdkVersion 21+`

### iOS (`ios/Runner/Info.plist`)
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Used to determine the Qibla direction and your local prayer times.</string>
<key>NSCameraUsageDescription</key>
<string>To set your profile photo.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>To choose a profile photo.</string>
```

---

## FOLDER STRUCTURE
```
lib/
  main.dart
  app.dart
  router.dart
  models/
    user_profile.dart
    prayer_record.dart
    prayer_enum.dart
  data/
    database.dart
    user_dao.dart
    prayer_dao.dart
  providers/
    auth_provider.dart
    profile_provider.dart
    prayer_provider.dart
    settings_provider.dart
  screens/
    login_screen.dart
    home_screen.dart
    calendar_screen.dart
    reports_screen.dart
    table_report_screen.dart
    qibla_screen.dart
    profile_screen.dart
    settings_screen.dart
  widgets/
    prayer_card.dart
    date_picker_bar.dart
    streak_chip.dart
    compass_dial.dart
    initials_avatar.dart
    stat_card.dart
  services/
    notification_service.dart
    location_service.dart
    export_service.dart
    qibla_service.dart
  utils/
    date_utils.dart
    hijri_utils.dart
    validators.dart
    constants.dart
  theme/
    app_theme.dart
    colors.dart
```

---

## DELIVERABLES
- Complete Flutter project with the folder structure above
- Working local persistence with sample seed data (last 30 days for testing reports)
- All 8 screens fully navigable
- At least 3 chart types rendering real data (bar, pie, line — plus heatmap)
- Functional Qibla compass on physical device
- CSV and PDF export working
- README with setup, run, and build instructions for both Android and iOS

---

## BUILD ORDER
1. Scaffold the project, set up theme, routing, and the bottom nav shell
2. Define models, database schema, DAO layer
3. Build the **Login screen** and auth flow (SharedPreferences `isLoggedIn` gate)
4. Build the **Daily Tracker** end-to-end (the single most important screen)
5. Build the **Profile** screen
6. Build the **Calendar** view
7. Build the **Reports** screen with charts
8. Build the **Table Report** with CSV/PDF export
9. Build the **Qibla** compass
10. Build the **Settings** screen, notifications, backup/restore
11. Localization (English first, then Arabic and Urdu)
12. Polish, animations, dark mode pass, README

Keep the code modular: each report type should be addable without touching existing ones, and the data layer should be swappable (sqflite ↔ Isar) behind the DAO interface.
