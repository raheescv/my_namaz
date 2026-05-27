import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/user_dao.dart';
import '../models/user_profile.dart';

final userDaoProvider = Provider<UserDao>((_) => UserDao());

class ProfileController extends StateNotifier<AsyncValue<UserProfile?>> {
  final UserDao _dao;
  ProfileController(this._dao) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await _dao.get());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> save(UserProfile p) async {
    await _dao.upsert(p);
    state = AsyncValue.data(p);
  }
}

final profileProvider =
    StateNotifierProvider<ProfileController, AsyncValue<UserProfile?>>(
  (ref) => ProfileController(ref.watch(userDaoProvider)),
);
