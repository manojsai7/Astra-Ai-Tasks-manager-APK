import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/profile/astra_profile_service.dart';

final astraProfileServiceProvider = Provider<AstraProfileService>((ref) {
  return const AstraProfileService();
});

final astraProfileProvider = StateNotifierProvider<AstraProfileNotifier, AstraProfile>((ref) {
  final notifier = AstraProfileNotifier(ref.read(astraProfileServiceProvider));
  notifier.load();
  return notifier;
});

class AstraProfileNotifier extends StateNotifier<AstraProfile> {
  final AstraProfileService _service;

  AstraProfileNotifier(this._service) : super(const AstraProfile());

  Future<void> load() async {
    state = await _service.load();
  }

  Future<void> setNickname(String nickname) async {
    state = await _service.setNickname(nickname);
  }

  Future<void> syncGoogleAccount({
    required String email,
    String? displayName,
    String? photoUrl,
  }) async {
    state = await _service.syncGoogleAccount(
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
    );
  }

  Future<void> clearGoogleConnection() async {
    state = await _service.clearGoogleConnection();
  }
}