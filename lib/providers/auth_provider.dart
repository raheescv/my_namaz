import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/constants.dart';

class AuthState {
  final bool ready;
  final bool isLoggedIn;
  const AuthState({required this.ready, required this.isLoggedIn});
  AuthState copyWith({bool? ready, bool? isLoggedIn}) => AuthState(
        ready: ready ?? this.ready,
        isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      );
}

class AuthController extends StateNotifier<AuthState> {
  AuthController() : super(const AuthState(ready: false, isLoggedIn: false)) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final loggedIn = prefs.getBool(K.prefsLoggedIn) ?? false;
      debugPrint('[auth] ready, loggedIn=$loggedIn');
      state = AuthState(ready: true, isLoggedIn: loggedIn);
    } catch (e, st) {
      debugPrint('[auth] load failed: $e\n$st');
      // Fall through to login on any pref-load error rather than hang.
      state = const AuthState(ready: true, isLoggedIn: false);
    }
  }

  Future<void> setLoggedIn(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(K.prefsLoggedIn, v);
    state = state.copyWith(isLoggedIn: v);
  }
}

final authProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) => AuthController());
