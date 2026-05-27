import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/prayer_dao.dart';
import '../models/prayer_enum.dart';
import '../models/prayer_record.dart';
import '../utils/date_utils.dart';

final prayerDaoProvider = Provider<PrayerDao>((_) => PrayerDao());

/// Selected date for the daily tracker.
final selectedDateProvider =
    StateProvider<DateTime>((_) => DateX.dayOnly(DateTime.now()));

/// Prayer record for the currently-selected date (auto-creates empty if missing).
final selectedRecordProvider =
    FutureProvider.autoDispose<PrayerRecord>((ref) async {
  final dao = ref.watch(prayerDaoProvider);
  final date = ref.watch(selectedDateProvider);
  final existing = await dao.getByDate(date);
  return existing ?? PrayerRecord.empty(date);
});

/// Toggles a prayer for the selected date and persists.
class PrayerController {
  final Ref ref;
  PrayerController(this.ref);

  Future<void> toggle(Prayer p) async {
    final dao = ref.read(prayerDaoProvider);
    final date = ref.read(selectedDateProvider);
    final existing = await dao.getByDate(date) ?? PrayerRecord.empty(date);
    final next = existing.toggle(p);
    await dao.upsert(next);
    ref.invalidate(selectedRecordProvider);
    ref.invalidate(rangeRecordsProvider);
    ref.invalidate(allRecordsProvider);
  }

  Future<void> saveNotes(String? notes) async {
    final dao = ref.read(prayerDaoProvider);
    final date = ref.read(selectedDateProvider);
    final existing = await dao.getByDate(date) ?? PrayerRecord.empty(date);
    final next = existing.copyWith(notes: notes);
    await dao.upsert(next);
    ref.invalidate(selectedRecordProvider);
  }
}

final prayerControllerProvider =
    Provider<PrayerController>((ref) => PrayerController(ref));

/// All records (DESC by date).
final allRecordsProvider = FutureProvider<List<PrayerRecord>>((ref) async {
  return ref.watch(prayerDaoProvider).getAll();
});

/// Records within a given range.
final rangeRecordsProvider = FutureProvider.family
    .autoDispose<List<PrayerRecord>, ({DateTime start, DateTime end})>(
        (ref, range) async {
  final dao = ref.watch(prayerDaoProvider);
  return dao.getRange(range.start, range.end);
});
