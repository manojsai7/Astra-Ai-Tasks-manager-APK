import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/scheduler/data/services/google_auth_service.dart';

/// Where a resolved display name actually came from.
///
/// Kept explicit so the UI never has to guess whether a name is real user
/// identity or a neutral placeholder.
enum AstraProfileSource {
  /// User-set nickname persisted locally.
  local,

  /// Google account display name.
  google,

  /// Local-part of the Google account email, used when the account exposes no
  /// display name.
  emailDerived,

  /// Nothing is known — [AstraProfile.fallbackDisplayName] is in use.
  fallback,
}

/// Immutable resolved identity for the signed-in (or local-only) user.
///
/// Replaces the previously hardcoded `'MANOJ'` header identity. There is no
/// build-time default name anywhere in the app: an unknown user resolves to
/// [fallbackDisplayName], which is a neutral placeholder, not a person.
class AstraProfile {
  /// Neutral placeholder used when no identity is known.
  static const String fallbackDisplayName = 'FRIEND';

  /// SharedPreferences key for the locally set nickname.
  static const String prefsKey = 'astra_profile_display_name';

  final String? displayName;
  final String? email;
  final AstraProfileSource source;
  final bool isLoaded;

  const AstraProfile({
    this.displayName,
    this.email,
    this.source = AstraProfileSource.fallback,
    this.isLoaded = false,
  });

  /// Name to render, never null and never empty.
  String get resolvedName {
    final name = displayName?.trim();
    if (name == null || name.isEmpty) return fallbackDisplayName;
    return name;
  }

  /// Uppercased form used by the display-weight header treatments.
  String get headerName => resolvedName.toUpperCase();

  /// True when a real identity (not the placeholder) is known.
  bool get hasIdentity => source != AstraProfileSource.fallback;

  AstraProfile copyWith({
    String? displayName,
    String? email,
    AstraProfileSource? source,
    bool? isLoaded,
    bool clearDisplayName = false,
    bool clearEmail = false,
  }) {
    return AstraProfile(
      displayName: clearDisplayName ? null : (displayName ?? this.displayName),
      email: clearEmail ? null : (email ?? this.email),
      source: source ?? this.source,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }

  @override
  String toString() =>
      'AstraProfile(displayName: $displayName, email: $email, source: $source, isLoaded: $isLoaded)';
}

/// Resolves identity from, in priority order:
///   1. a locally persisted nickname,
///   2. the Google account display name,
///   3. the local-part of the Google account email,
///   4. [AstraProfile.fallbackDisplayName].
class AstraProfileNotifier extends StateNotifier<AstraProfile> {
  AstraProfileNotifier({this._authService}) : super(const AstraProfile());

  /// Injectable for tests; when null the shared singleton is consulted lazily.
  final GoogleAuthService? _authService;

  GoogleAuthService? get _auth {
    if (_authService != null) return _authService;
    try {
      return GoogleAuthService.instance;
    } catch (_) {
      // Plugin unavailable (tests / desktop) — identity simply stays unknown.
      return null;
    }
  }

  /// Reads persisted and account identity. Safe to call repeatedly.
  Future<void> load() async {
    String? localName;
    try {
      final prefs = await SharedPreferences.getInstance();
      localName = prefs.getString(AstraProfile.prefsKey)?.trim();
    } catch (_) {
      localName = null;
    }

    String? accountName;
    String? accountEmail;
    try {
      final user = _auth?.currentUser;
      accountName = user?.displayName?.trim();
      accountEmail = user?.email.trim();
    } catch (_) {
      accountName = null;
      accountEmail = null;
    }

    if (!mounted) return;
    state = _resolve(
      localName: localName,
      accountName: accountName,
      accountEmail: accountEmail,
    );
  }

  /// Persists a user-chosen nickname. An empty value clears it and falls back to
  /// whatever the account provides.
  Future<void> setDisplayName(String? value) async {
    final trimmed = value?.trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      if (trimmed == null || trimmed.isEmpty) {
        await prefs.remove(AstraProfile.prefsKey);
      } else {
        await prefs.setString(AstraProfile.prefsKey, trimmed);
      }
    } catch (_) {
      // Persistence failure must not desync in-memory state below.
    }
    await load();
  }

  /// Records identity straight from a completed Google sign-in.
  Future<void> adoptGoogleIdentity({String? name, String? email}) async {
    String? localName;
    try {
      final prefs = await SharedPreferences.getInstance();
      localName = prefs.getString(AstraProfile.prefsKey)?.trim();
    } catch (_) {
      localName = null;
    }

    if (!mounted) return;
    state = _resolve(
      localName: localName,
      accountName: name?.trim(),
      accountEmail: email?.trim(),
    );
  }

  /// Drops account-derived identity on sign-out. A locally set nickname is
  /// intentionally preserved — it is the user's own data, not Google's.
  Future<void> clearAccountIdentity() async {
    await load();
  }

  AstraProfile _resolve({
    String? localName,
    String? accountName,
    String? accountEmail,
  }) {
    if (localName != null && localName.isNotEmpty) {
      return AstraProfile(
        displayName: localName,
        email: (accountEmail != null && accountEmail.isNotEmpty) ? accountEmail : null,
        source: AstraProfileSource.local,
        isLoaded: true,
      );
    }

    if (accountName != null && accountName.isNotEmpty) {
      return AstraProfile(
        displayName: accountName,
        email: (accountEmail != null && accountEmail.isNotEmpty) ? accountEmail : null,
        source: AstraProfileSource.google,
        isLoaded: true,
      );
    }

    if (accountEmail != null && accountEmail.isNotEmpty) {
      final localPart = accountEmail.split('@').first.trim();
      if (localPart.isNotEmpty) {
        return AstraProfile(
          displayName: localPart,
          email: accountEmail,
          source: AstraProfileSource.emailDerived,
          isLoaded: true,
        );
      }
    }

    return const AstraProfile(
      source: AstraProfileSource.fallback,
      isLoaded: true,
    );
  }
}

final astraProfileProvider =
    StateNotifierProvider<AstraProfileNotifier, AstraProfile>((ref) {
  return AstraProfileNotifier()..load();
});
