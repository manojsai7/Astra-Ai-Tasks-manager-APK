import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:astra/features/scheduler/data/services/google_auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('GoogleAuthService Scope & Initialization Tests (Phase 2X-2)', () {
    test('1. Scope list contains calendar.events write scope', () {
      final scopes = GoogleAuthService.scopes;
      expect(scopes, contains('https://www.googleapis.com/auth/calendar.events'));
    });

    test('2. Gmail readonly scope remains present', () {
      final scopes = GoogleAuthService.scopes;
      expect(scopes, contains('https://www.googleapis.com/auth/gmail.readonly'));
    });

    test('3. Calendar readonly scope remains present', () {
      final scopes = GoogleAuthService.scopes;
      expect(scopes, contains('https://www.googleapis.com/auth/calendar.readonly'));
    });

    test('4. GoogleAuthService initializes with full scope list', () {
      final authService = GoogleAuthService.instance;
      authService.initialize();

      expect(authService.isSignedIn, isFalse);
      expect(authService.currentUser, isNull);
    });

    test('5. Least privilege invariant: scope count is exactly 3', () {
      final scopes = GoogleAuthService.scopes;
      // Exactly gmail.readonly, calendar.readonly, calendar.events
      expect(scopes.length, 3);
    });
  });
}
