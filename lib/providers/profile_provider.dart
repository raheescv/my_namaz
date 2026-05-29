import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_profile.dart';
import 'auth_provider.dart';

/// The current user's profile, as held in auth state.
/// Editing flows go through ProfileController for updates.
final profileProvider = Provider<UserProfile?>(
    (ref) => ref.watch(authProvider.select((s) => s.user)));

class ProfileController {
  final Ref ref;
  ProfileController(this.ref);

  /// Persist edits to the current user. If the mobile number changed and
  /// another account already exists under that number, returns false —
  /// the caller should ask the user whether to switch to that account.
  Future<bool> save(UserProfile next) async {
    final userDao = ref.read(userDaoProvider);
    final current = ref.read(authProvider).user;
    if (current?.id == null) return false;

    // If the mobile changed, check for collision with another account.
    final mobileChanged = next.mobile != current!.mobile ||
        next.countryCode != current.countryCode;
    if (mobileChanged) {
      final other = await userDao.getByMobile(next.countryCode, next.mobile);
      if (other != null && other.id != current.id) {
        // Caller decides whether to switch to other account.
        return false;
      }
    }

    final updated = await userDao
        .updateById(next.copyWith(id: current.id, updatedAt: DateTime.now()));
    await ref.read(authProvider.notifier).setCurrentUser(updated);
    return true;
  }

  /// Switch to the user with the given mobile, creating them if missing.
  Future<UserProfile> switchOrCreate({
    required String countryCode,
    required String mobile,
    required String name,
    String? email,
  }) async {
    final userDao = ref.read(userDaoProvider);
    final existing = await userDao.getByMobile(countryCode, mobile);
    final now = DateTime.now();
    UserProfile saved;
    if (existing == null) {
      saved = await userDao.upsertByMobile(UserProfile(
        mobile: mobile,
        countryCode: countryCode,
        name: name,
        email: email,
        createdAt: now,
        updatedAt: now,
      ));
    } else {
      // Existing user — keep their stored info, only refresh updatedAt.
      saved = existing.copyWith(updatedAt: now);
      await userDao.updateById(saved);
    }
    await ref.read(authProvider.notifier).setCurrentUser(saved);
    return saved;
  }
}

final profileControllerProvider =
    Provider<ProfileController>((ref) => ProfileController(ref));
