import 'package:intl/intl.dart';

class DateX {
  DateX._();

  static DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static String ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static String pretty(DateTime d) =>
      DateFormat('EEE, d MMM yyyy').format(d);

  static String prettyShort(DateTime d) =>
      DateFormat('d MMM').format(d);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool isToday(DateTime d) => isSameDay(d, DateTime.now());

  static List<DateTime> rangeInclusive(DateTime start, DateTime end) {
    final s = dayOnly(start);
    final e = dayOnly(end);
    final out = <DateTime>[];
    var cur = s;
    while (!cur.isAfter(e)) {
      out.add(cur);
      cur = cur.add(const Duration(days: 1));
    }
    return out;
  }

  static DateTime startOfWeek(DateTime d) {
    final day = dayOnly(d);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  static DateTime startOfMonth(DateTime d) => DateTime(d.year, d.month, 1);
  static DateTime endOfMonth(DateTime d) =>
      DateTime(d.year, d.month + 1, 0);

  static DateTime startOfYear(DateTime d) => DateTime(d.year, 1, 1);
  static DateTime endOfYear(DateTime d) => DateTime(d.year, 12, 31);
}
