import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../lib/services/profile/astra_profile_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('stores and loads a user nickname', () async {
    const service = AstraProfileService();

    await service.setNickname('Manoj');
    final profile = await service.load();

    expect(profile.nickname, 'Manoj');
    expect(profile.displayName, 'Manoj');
    expect(profile.initials, 'M');
  });

  test('google profile fills missing nickname', () async {
    const service = AstraProfileService();

    final profile = await service.syncGoogleAccount(
      email: 'manojsai@example.com',
      displayName: 'Manoj Sai',
      photoUrl: 'https://example.com/profile.jpg',
    );

    expect(profile.email, 'manojsai@example.com');
    expect(profile.nickname, 'Manoj Sai');
    expect(profile.isGoogleConnected, isTrue);
    expect(profile.photoUrl, 'https://example.com/profile.jpg');
  });

  test('explicit nickname is never overwritten by google sync', () async {
    const service = AstraProfileService();

    await service.setNickname('Captain');
    final profile = await service.syncGoogleAccount(
      email: 'manojsai@example.com',
      displayName: 'Manoj Sai',
    );

    expect(profile.nickname, 'Captain');
    expect(profile.email, 'manojsai@example.com');
  });

  test('google-only nickname is cleared when account disconnects', () async {
    const service = AstraProfileService();

    await service.syncGoogleAccount(
      email: 'manojsai@example.com',
      displayName: 'Manoj Sai',
    );
    final cleared = await service.setGoogleConnected(false);

    expect(cleared.nickname, isEmpty);
    expect(cleared.email, isEmpty);
    expect(cleared.photoUrl, isNull);
    expect(cleared.isGoogleConnected, isFalse);
  });

  test('explicit nickname survives google disconnect', () async {
    const service = AstraProfileService();

    await service.setNickname('Captain');
    await service.syncGoogleAccount(
      email: 'manojsai@example.com',
      displayName: 'Manoj Sai',
    );
    final cleared = await service.setGoogleConnected(false);

    expect(cleared.nickname, 'Captain');
    expect(cleared.email, isEmpty);
    expect(cleared.isGoogleConnected, isFalse);
  });
}
