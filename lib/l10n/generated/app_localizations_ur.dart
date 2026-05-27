// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Urdu (`ur`).
class AppLocalizationsUr extends AppLocalizations {
  AppLocalizationsUr([String locale = 'ur']) : super(locale);

  @override
  String get appName => 'میری نماز';

  @override
  String get tagline => 'اپنی روزانہ کی نماز ٹریک کریں';

  @override
  String get continueLabel => 'جاری رکھیں';

  @override
  String get mobileNumber => 'موبائل نمبر';

  @override
  String get yourName => 'آپ کا نام';

  @override
  String get emailOptional => 'ای میل (اختیاری)';

  @override
  String get loginDisclaimer =>
      'آپ کا ڈیٹا صرف اس ڈیوائس پر محفوظ ہے۔ کوئی OTP، کوئی SMS، کچھ بھی آپ کے فون سے باہر نہیں جاتا۔';

  @override
  String get greeting => 'السلام علیکم';

  @override
  String get today => 'آج';

  @override
  String get fajr => 'فجر';

  @override
  String get dhuhr => 'ظہر';

  @override
  String get asr => 'عصر';

  @override
  String get maghrib => 'مغرب';

  @override
  String get isha => 'عشاء';

  @override
  String completedOf(int done, int total) {
    return '$done / $total مکمل';
  }

  @override
  String streakDays(int n) {
    return '$n دن کا سلسلہ';
  }

  @override
  String get notes => 'نوٹس';

  @override
  String get calendar => 'کیلنڈر';

  @override
  String get reports => 'رپورٹس';

  @override
  String get qibla => 'قبلہ';

  @override
  String get settings => 'ترتیبات';

  @override
  String get profile => 'پروفائل';

  @override
  String get tableReport => 'ٹیبل رپورٹ';

  @override
  String get save => 'محفوظ کریں';

  @override
  String get logout => 'لاگ آؤٹ';

  @override
  String get deleteAll => 'میرا تمام ڈیٹا حذف کریں';
}
