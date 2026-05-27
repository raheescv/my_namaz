// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'نمازي';

  @override
  String get tagline => 'تتبع صلاتك اليومية';

  @override
  String get continueLabel => 'متابعة';

  @override
  String get mobileNumber => 'رقم الجوال';

  @override
  String get yourName => 'اسمك';

  @override
  String get emailOptional => 'البريد الإلكتروني (اختياري)';

  @override
  String get loginDisclaimer =>
      'تُحفظ بياناتك على هذا الجهاز فقط. لا يوجد OTP ولا رسائل نصية، ولا يغادر شيء هاتفك.';

  @override
  String get greeting => 'السلام عليكم';

  @override
  String get today => 'اليوم';

  @override
  String get fajr => 'الفجر';

  @override
  String get dhuhr => 'الظهر';

  @override
  String get asr => 'العصر';

  @override
  String get maghrib => 'المغرب';

  @override
  String get isha => 'العشاء';

  @override
  String completedOf(int done, int total) {
    return '$done / $total مكتملة';
  }

  @override
  String streakDays(int n) {
    return 'سلسلة $n يوم';
  }

  @override
  String get notes => 'ملاحظات';

  @override
  String get calendar => 'التقويم';

  @override
  String get reports => 'التقارير';

  @override
  String get qibla => 'القبلة';

  @override
  String get settings => 'الإعدادات';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get tableReport => 'تقرير الجدول';

  @override
  String get save => 'حفظ';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get deleteAll => 'حذف جميع بياناتي';
}
