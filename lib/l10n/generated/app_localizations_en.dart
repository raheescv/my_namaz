// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'My Namaz';

  @override
  String get tagline => 'Track your daily Salah';

  @override
  String get continueLabel => 'Continue';

  @override
  String get mobileNumber => 'Mobile number';

  @override
  String get yourName => 'Your name';

  @override
  String get emailOptional => 'Email (optional)';

  @override
  String get loginDisclaimer =>
      'Your data is stored only on this device. No OTP, no SMS, nothing leaves your phone.';

  @override
  String get greeting => 'Assalamu Alaikum';

  @override
  String get today => 'Today';

  @override
  String get fajr => 'Fajr';

  @override
  String get dhuhr => 'Dhuhr';

  @override
  String get asr => 'Asr';

  @override
  String get maghrib => 'Maghrib';

  @override
  String get isha => 'Isha';

  @override
  String completedOf(int done, int total) {
    return '$done / $total completed';
  }

  @override
  String streakDays(int n) {
    return '$n-day streak';
  }

  @override
  String get notes => 'Notes';

  @override
  String get calendar => 'Calendar';

  @override
  String get reports => 'Reports';

  @override
  String get qibla => 'Qibla';

  @override
  String get settings => 'Settings';

  @override
  String get profile => 'Profile';

  @override
  String get tableReport => 'Table Report';

  @override
  String get save => 'Save';

  @override
  String get logout => 'Logout';

  @override
  String get deleteAll => 'Delete all my data';
}
