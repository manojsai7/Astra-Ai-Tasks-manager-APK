import 'package:flutter_test/flutter_test.dart';
import 'package:astra/core/updater/update_downloader.dart';
import 'package:astra/core/updater/app_update_service.dart';
import 'package:astra/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 5D.2-A — Update Downloader Friendly Error Classification', () {
    test('SocketException / ClientException produces friendly connection error copy', () {
      const rawError = 'ClientException: Connection closed while receiving data, uri=https://github-production-release-asset-234234.s3.amazonaws.com/...';
      final friendly = UpdateDownloader.friendlyDownloadError(rawError);
      expect(friendly, contains('connection to the update server was interrupted'));
      expect(friendly, contains('installation is unchanged'));
      expect(friendly.contains('s3.amazonaws.com'), isFalse);
      expect(friendly.contains('ClientException'), isFalse);
    });

    test('Timeout exception produces clear timeout guidance', () {
      const rawError = 'TimeoutException after 0:00:10.000000';
      final friendly = UpdateDownloader.friendlyDownloadError(rawError);
      expect(friendly, contains('took too long to respond'));
    });

    test('404 error produces unavailable notice', () {
      const rawError = 'HTTP 404 Not Found';
      final friendly = UpdateDownloader.friendlyDownloadError(rawError);
      expect(friendly, contains('no longer available'));
    });

    test('Null or empty error produces default graceful fallback', () {
      final friendly = UpdateDownloader.friendlyDownloadError(null);
      expect(friendly, contains('download was interrupted'));
    });
  });

  group('Phase 5D.2-D — Permission Truthfulness & State Machine', () {
    test('checkReminderReadiness returns unknown when platform plugin is unavailable (never assumes ready)', () async {
      final state = await NotificationService.checkReminderReadiness();
      // On non-Android test environment, plugin is not registered -> MUST return unknown, NOT ready.
      expect(state, equals(ReminderReadinessState.unknown));
      expect(state != ReminderReadinessState.ready, isTrue);
    });
  });

  group('Phase 5D.2 — AppUpdateService', () {
    test('AppUpdateService singleton initialized safely', () {
      final service = AppUpdateService.instance;
      expect(service.isChecking, isFalse);
      expect(service.latestInfo, isNull);
    });
  });
}
