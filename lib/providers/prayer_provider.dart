import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/prayer_dao.dart';
import '../models/prayer_enum.dart';
import '../models/prayer_record.dart';
import '../utils/date_utils.dart';
import 'auth_provider.dart';

final prayerDaoProvider = Provider<PrayerDao>((_) => PrayerDao());

/// Selected date for the daily tracker.
final selectedDateProvider =
    StateProvider<DateTime>((_) => DateX.dayOnly(DateTime.now()));

/// Prayer record for the currently-selected date and current user.
final selectedRecordProvider =
    FutureProvider.autoDispose<PrayerRecord>((ref) async {
  final dao = ref.watch(prayerDaoProvider);
  final date = ref.watch(selectedDateProvider);
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return PrayerRecord.empty(date);
  final existing = await dao.getByDate(userId, date);
  return existing ?? PrayerRecord.empty(date);
});

/// Toggles a prayer for the selected date and persists.
class PrayerController {
  final Ref ref;
  PrayerController(this.ref);

  Future<void> toggle(Prayer p) async {
    final dao = ref.read(prayerDaoProvider);
    final date = ref.read(selectedDateProvider);
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    final existing =
        await dao.getByDate(userId, date) ?? PrayerRecord.empty(date);
    final next = existing.toggle(p);
    await dao.upsert(userId, next);
    ref.invalidate(selectedRecordProvider);
    ref.invalidate(rangeRecordsProvider);
    ref.invalidate(allRecordsProvider);
  }

  Future<void> saveNotes(String? notes) async {
    final dao = ref.read(prayerDaoProvider);
    final date = ref.read(selectedDateProvider);
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    final existing =
        await dao.getByDate(userId, date) ?? PrayerRecord.empty(date);
    final next = existing.copyWith(notes: notes);
    await dao.upsert(userId, next);
    ref.invalidate(selectedRecordProvider);
  }
}

final prayerControllerProvider =
    Provider<PrayerController>((ref) => PrayerController(ref));

/// All records for the current user.
final allRecordsProvider = FutureProvider<List<PrayerRecord>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];
  return ref.watch(prayerDaoProvider).getAllForUser(userId);
});

/// Records within a given range, scoped to current user.
final rangeRecordsProvider = FutureProvider.family
    .autoDispose<List<PrayerRecord>, ({DateTime start, DateTime end})>(
        (ref, range) async {
  final dao = ref.watch(prayerDaoProvider);
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];
  return dao.getRange(userId, range.start, range.end);
});
