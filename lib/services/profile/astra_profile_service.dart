import 'package:shared_preferences/shared_preferences.dart';

/// Local-first identity profile used by the ASTRA shell.
/// A user-entered nickname always wins over an account-derived name.
class AstraProfile {
  final String nickname;
  final String email;
  final String? photoUrl;
  final bool isGoogleConnected;

  const AstraProfile({
    this.nickname = '',
    this.email = '',
    this.photoUrl,
    this.isGoogleConnected = false,
  });

  String get displayName => nickname.trim().isNotEmpty ? nickname.trim() : 'there';

  String get initials {
    final value = displayName.trim();
    if (value.isEmpty) return 'A';
    final parts = value.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  AstraProfile copyWith({
    String? nickname,
    String? email,
    String? photoUrl,
    bool clearPhotoUrl = false,
    bool? isGoogleConnected,
  }) {
    return AstraProfile(
      nickname: nickname ?? this.nickname,
      email: email ?? this.email,
      photoUrl: clearPhotoUrl ? null : (photoUrl ?? this.photoUrl),
      isGoogleConnected: isGoogleConnected ?? this.isGoogleConnected,
    );
  }
}

class AstraProfileService {
  static const nicknameKey = 'astra_profile_nickname';
  static const emailKey = 'astra_profile_email';
  static const photoUrlKey = 'astra_profile_photo_url';
  static const googleConnectedKey = 'astra_profile_google_connected';
  static const nicknameSourceKey = 'astra_profile_nickname_source';

  const AstraProfileService();

  Future<AstraProfile> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AstraProfile(
      nickname: prefs.getString(nicknameKey) ?? '',
      email: prefs.getString(emailKey) ?? '',
      photoUrl: prefs.getString(photoUrlKey),
      isGoogleConnected: prefs.getBool(googleConnectedKey) ?? false,
    );
  }

  Future<AstraProfile> setNickname(String nickname) async {
    final clean = nickname.trim();
    final prefs = await SharedPreferences.getInstance();
    if (clean.isEmpty) {
      await prefs.remove(nicknameKey);
      await prefs.remove(nicknameSourceKey);
    } else {
      await prefs.setString(nicknameKey, clean);
      await prefs.setString(nicknameSourceKey, 'user');
    }
    return load();
  }

  Future<AstraProfile> syncGoogleAccount({
    required String email,
    String? displayName,
    String? photoUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(emailKey, email);
    await prefs.setBool(googleConnectedKey, true);
    if (photoUrl != null && photoUrl.isNotEmpty) {
      await prefs.setString(photoUrlKey, photoUrl);
    }

    final source = prefs.getString(nicknameSourceKey);
    final currentNickname = prefs.getString(nicknameKey) ?? '';
    if (source != 'user' && currentNickname.trim().isEmpty) {
      final candidate = (displayName ?? '').trim();
      final fallback = email.split('@').first.trim();
      final nickname = candidate.isNotEmpty ? candidate : fallback;
      if (nickname.isNotEmpty) {
        await prefs.setString(nicknameKey, nickname);
        await prefs.setString(nicknameSourceKey, 'google');
      }
    }

    return load();
  }

  Future<AstraProfile> clearGoogleConnection() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(googleConnectedKey, false);
    await prefs.remove(emailKey);
    await prefs.remove(photoUrlKey);
    if (prefs.getString(nicknameSourceKey) == 'google') {
      await prefs.remove(nicknameKey);
      await prefs.remove(nicknameSourceKey);
    }
    return load();
  }
}