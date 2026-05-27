enum Prayer {
  fajr('Fajr', 'الفجر'),
  dhuhr('Dhuhr', 'الظهر'),
  asr('Asr', 'العصر'),
  maghrib('Maghrib', 'المغرب'),
  isha('Isha', 'العشاء');

  final String name;
  final String arabic;
  const Prayer(this.name, this.arabic);

  static const all = Prayer.values;
}

enum PrayerStatus { pending, completed, missed }
