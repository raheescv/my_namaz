import 'prayer_enum.dart';

class PrayerRecord {
  final int? id;
  final DateTime date;
  final bool fajr;
  final bool dhuhr;
  final bool asr;
  final bool maghrib;
  final bool isha;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  PrayerRecord({
    this.id,
    required this.date,
    this.fajr = false,
    this.dhuhr = false,
    this.asr = false,
    this.maghrib = false,
    this.isha = false,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PrayerRecord.empty(DateTime date) {
    final now = DateTime.now();
    return PrayerRecord(
      date: DateTime(date.year, date.month, date.day),
      createdAt: now,
      updatedAt: now,
    );
  }

  bool isCompleted(Prayer p) {
    switch (p) {
      case Prayer.fajr:
        return fajr;
      case Prayer.dhuhr:
        return dhuhr;
      case Prayer.asr:
        return asr;
      case Prayer.maghrib:
        return maghrib;
      case Prayer.isha:
        return isha;
    }
  }

  int get completedCount =>
      (fajr ? 1 : 0) +
      (dhuhr ? 1 : 0) +
      (asr ? 1 : 0) +
      (maghrib ? 1 : 0) +
      (isha ? 1 : 0);

  bool get isPerfect => completedCount == 5;
  bool get hasAny => completedCount > 0;

  PrayerRecord toggle(Prayer p) {
    return PrayerRecord(
      id: id,
      date: date,
      fajr: p == Prayer.fajr ? !fajr : fajr,
      dhuhr: p == Prayer.dhuhr ? !dhuhr : dhuhr,
      asr: p == Prayer.asr ? !asr : asr,
      maghrib: p == Prayer.maghrib ? !maghrib : maghrib,
      isha: p == Prayer.isha ? !isha : isha,
      notes: notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  PrayerRecord copyWith({String? notes}) => PrayerRecord(
        id: id,
        date: date,
        fajr: fajr,
        dhuhr: dhuhr,
        asr: asr,
        maghrib: maghrib,
        isha: isha,
        notes: notes ?? this.notes,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'date': _ymd(date),
        'fajr': fajr ? 1 : 0,
        'dhuhr': dhuhr ? 1 : 0,
        'asr': asr ? 1 : 0,
        'maghrib': maghrib ? 1 : 0,
        'isha': isha ? 1 : 0,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory PrayerRecord.fromMap(Map<String, dynamic> m) => PrayerRecord(
        id: m['id'] as int?,
        date: DateTime.parse(m['date'] as String),
        fajr: (m['fajr'] as int) == 1,
        dhuhr: (m['dhuhr'] as int) == 1,
        asr: (m['asr'] as int) == 1,
        maghrib: (m['maghrib'] as int) == 1,
        isha: (m['isha'] as int) == 1,
        notes: m['notes'] as String?,
        createdAt: DateTime.parse(m['createdAt'] as String),
        updatedAt: DateTime.parse(m['updatedAt'] as String),
      );

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
