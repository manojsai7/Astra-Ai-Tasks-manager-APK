import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'assistant_provider.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;

  const AuthState({this.isAuthenticated = false, this.isLoading = false, this.error});
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;

  AuthNotifier(this.ref) : super(const AuthState());

  Future<void> checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool('hasSeenAuth') ?? false;
    if (hasSeen) {
      state = state.copyWith(isAuthenticated: true);
    }
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final auth = ref.read(googleAuthServiceProvider);
      final user = await auth.signIn();
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('hasSeenAuth', true);
        state = state.copyWith(isAuthenticated: true, isLoading: false);
        return true;
      } else {
        state = state.copyWith(isLoading: false, error: 'Sign-in cancelled. Please try again.');
        return false;
      }
    } catch (e) {
      String errText = e.toString();
      if (errText.contains('10') || errText.contains('DEVELOPER_ERROR') || errText.contains('ApiException')) {
        errText = 'OAuth Configuration Error: SHA-1 fingerprint missing in Firebase Console for dev.codehunters.astra.\nCheck instructions below.';
      }
      state = state.copyWith(isLoading: false, error: errText);
      return false;
    }
  }

  Future<void> skipOrBypassAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenAuth', true);
    state = state.copyWith(isAuthenticated: true, isLoading: false);
  }

  void reset() {
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

extension AuthStateExt on AuthState {
  AuthState copyWith({bool? isAuthenticated, bool? isLoading, String? error}) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
