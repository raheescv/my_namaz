import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/user_dao.dart';
import '../models/user_profile.dart';

const _currentUserIdKey = 'currentUserId';

class AuthState {
  final bool ready;
  final UserProfile? user;
  const AuthState({required this.ready, this.user});

  bool get isLoggedIn => user != null;

  AuthState copyWith({bool? ready, UserProfile? user, bool clearUser = false}) =>
      AuthState(
        ready: ready ?? this.ready,
        user: clearUser ? null : (user ?? this.user),
      );
}

class AuthController extends StateNotifier<AuthState> {
  final UserDao _userDao;
  AuthController(this._userDao) : super(const AuthState(ready: false)) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getInt(_currentUserIdKey);
      if (id == null) {
        state = const AuthState(ready: true);
        return;
      }
      final user = await _userDao.getById(id);
      if (user == null) {
        // Pointer is stale — clear it.
        await prefs.remove(_currentUserIdKey);
        state = const AuthState(ready: true);
        return;
      }
      debugPrint('[auth] resumed user id=${user.id} mobile=${user.fullPhone}');
      state = AuthState(ready: true, user: user);
    } catch (e, st) {
      debugPrint('[auth] load failed: $e\n$st');
      state = const AuthState(ready: true);
    }
  }

  /// Switch the active user. Persists the id and updates state.
  Future<void> setCurrentUser(UserProfile? user) async {
    final prefs = await SharedPreferences.getInstance();
    if (user == null || user.id == null) {
      await prefs.remove(_currentUserIdKey);
      state = state.copyWith(ready: true, clearUser: true);
    } else {
      await prefs.setInt(_currentUserIdKey, user.id!);
      state = AuthState(ready: true, user: user);
    }
  }

  /// Refresh the in-memory user from disk (after a profile edit).
  Future<void> refreshUser() async {
    final cur = state.user;
    if (cur?.id == null) return;
    final fresh = await _userDao.getById(cur!.id!);
    if (fresh != null) state = state.copyWith(user: fresh);
  }

  Future<void> logout() async => setCurrentUser(null);
}

final userDaoProvider = Provider<UserDao>((_) => UserDao());

final authProvider = StateNotifierProvider<AuthController, AuthState>(
    (ref) => AuthController(ref.watch(userDaoProvider)));

/// Convenience: the current user's id, or null if logged out.
final currentUserIdProvider = Provider<int?>(
    (ref) => ref.watch(authProvider.select((s) => s.user?.id)));
