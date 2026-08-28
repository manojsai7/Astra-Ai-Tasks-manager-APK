import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astra/providers/profile_provider.dart';

/// Identity must always come from a real source. These tests pin the resolution
/// order and prove that an unknown user resolves to a neutral placeholder rather
/// than to any hardcoded person's name.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AstraProfile — resolution', () {
    test('no identity resolves to the neutral placeholder, not a real name', () {
      const profile = AstraProfile();

      expect(profile.resolvedName, AstraProfile.fallbackDisplayName);
      expect(profile.headerName, AstraProfile.fallbackDisplayName.toUpperCase());
      expect(profile.hasIdentity, isFalse);
    });

    test('blank and whitespace-only names fall back', () {
      expect(const AstraProfile(displayName: '').resolvedName,
          AstraProfile.fallbackDisplayName);
      expect(const AstraProfile(displayName: '   ').resolvedName,
          AstraProfile.fallbackDisplayName);
    });

    test('headerName uppercases for the display-weight treatment', () {
      const profile = AstraProfile(
        displayName: 'Ada Lovelace',
        source: AstraProfileSource.google,
      );

      expect(profile.headerName, 'ADA LOVELACE');
      expect(profile.hasIdentity, isTrue);
    });
  });

  group('AstraProfileNotifier — precedence', () {
    test('load with nothing persisted yields the fallback and marks loaded', () async {
      final notifier = AstraProfileNotifier();
      addTearDown(notifier.dispose);

      await notifier.load();

      expect(notifier.state.source, AstraProfileSource.fallback);
      expect(notifier.state.isLoaded, isTrue);
      expect(notifier.state.resolvedName, AstraProfile.fallbackDisplayName);
    });

    test('a persisted nickname wins and is reported as local', () async {
      SharedPreferences.setMockInitialValues({
        AstraProfile.prefsKey: 'Grace',
      });
      final notifier = AstraProfileNotifier();
      addTearDown(notifier.dispose);

      await notifier.load();

      expect(notifier.state.displayName, 'Grace');
      expect(notifier.state.source, AstraProfileSource.local);
      expect(notifier.state.headerName, 'GRACE');
    });

    test('setDisplayName persists and re-resolves', () async {
      final notifier = AstraProfileNotifier();
      addTearDown(notifier.dispose);

      await notifier.setDisplayName('  Ada  ');

      expect(notifier.state.displayName, 'Ada');
      expect(notifier.state.source, AstraProfileSource.local);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AstraProfile.prefsKey), 'Ada');
    });

    test('setDisplayName with empty input clears back to the fallback', () async {
      SharedPreferences.setMockInitialValues({
        AstraProfile.prefsKey: 'Grace',
      });
      final notifier = AstraProfileNotifier();
      addTearDown(notifier.dispose);

      await notifier.load();
      expect(notifier.state.source, AstraProfileSource.local);

      await notifier.setDisplayName('   ');

      expect(notifier.state.source, AstraProfileSource.fallback);
      expect(notifier.state.resolvedName, AstraProfile.fallbackDisplayName);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AstraProfile.prefsKey), isNull);
    });

    test('Google display name is adopted when no nickname is set', () async {
      final notifier = AstraProfileNotifier();
      addTearDown(notifier.dispose);

      await notifier.adoptGoogleIdentity(
        name: 'Ada Lovelace',
        email: 'ada@example.com',
      );

      expect(notifier.state.displayName, 'Ada Lovelace');
      expect(notifier.state.email, 'ada@example.com');
      expect(notifier.state.source, AstraProfileSource.google);
    });

    test('a local nickname outranks the Google display name', () async {
      SharedPreferences.setMockInitialValues({
        AstraProfile.prefsKey: 'Ada',
      });
      final notifier = AstraProfileNotifier();
      addTearDown(notifier.dispose);

      await notifier.adoptGoogleIdentity(
        name: 'Ada Lovelace',
        email: 'ada@example.com',
      );

      expect(notifier.state.displayName, 'Ada');
      expect(notifier.state.source, AstraProfileSource.local);
      // Email still surfaces so the profile sheet can show the real account.
      expect(notifier.state.email, 'ada@example.com');
    });

    test('email local-part is used when the account exposes no display name', () async {
      final notifier = AstraProfileNotifier();
      addTearDown(notifier.dispose);

      await notifier.adoptGoogleIdentity(name: null, email: 'grace@example.com');

      expect(notifier.state.displayName, 'grace');
      expect(notifier.state.source, AstraProfileSource.emailDerived);
      expect(notifier.state.headerName, 'GRACE');
    });

    test('an account with neither name nor email stays on the fallback', () async {
      final notifier = AstraProfileNotifier();
      addTearDown(notifier.dispose);

      await notifier.adoptGoogleIdentity(name: '  ', email: '  ');

      expect(notifier.state.source, AstraProfileSource.fallback);
      expect(notifier.state.hasIdentity, isFalse);
    });

    test('sign-out drops account identity but keeps a local nickname', () async {
      SharedPreferences.setMockInitialValues({
        AstraProfile.prefsKey: 'Ada',
      });
      final notifier = AstraProfileNotifier();
      addTearDown(notifier.dispose);

      await notifier.adoptGoogleIdentity(
        name: 'Ada Lovelace',
        email: 'ada@example.com',
      );
      expect(notifier.state.email, 'ada@example.com');

      await notifier.clearAccountIdentity();

      expect(notifier.state.displayName, 'Ada');
      expect(notifier.state.source, AstraProfileSource.local);
      expect(notifier.state.email, isNull);
    });
  });
}
