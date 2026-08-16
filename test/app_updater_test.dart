import 'package:flutter_test/flutter_test.dart';

import 'package:astra/core/updater/app_updater.dart';
import 'package:astra/core/updater/update_downloader.dart';

void main() {
  group('ASTRA Phase U1: App Updater & Release Asset Tests', () {
    // A. current version < latest -> update available
    test('A. current version < latest -> update available (isNewer = true)', () {
      expect(AppUpdater.isNewer('2.1.1', '1.1.4'), isTrue);
      expect(AppUpdater.isNewer('1.2.0', '1.1.9'), isTrue);
      expect(AppUpdater.isNewer('2.0.0', '1.9.9'), isTrue);
    });

    // B. current version == latest -> no update (isNewer = false)
    test('B. current version == latest or newer -> no update available', () {
      expect(AppUpdater.isNewer('2.1.1', '2.1.1'), isFalse);
      expect(AppUpdater.isNewer('1.1.4', '2.1.1'), isFalse);
      expect(AppUpdater.isNewer('1.0.0', '1.0.0'), isFalse);
    });

    // C. Download state progression & human-readable formatting
    test('C. Download state progression & byte formatting', () {
      expect(UpdateDownloadState.values, contains(UpdateDownloadState.downloading));
      expect(UpdateDownloadState.values, contains(UpdateDownloadState.downloaded));
      expect(UpdateDownloadState.values, contains(UpdateDownloadState.installing));
      expect(UpdateDownloadState.values, contains(UpdateDownloadState.failed));

      expect(UpdateDownloader.formatBytes(0), '0 B');
      expect(UpdateDownloader.formatBytes(1024), '1.0 KB');
      expect(UpdateDownloader.formatBytes(15 * 1024 * 1024), '15.0 MB');
    });

    // D. Release asset selection -> ARM64 selects arm64 APK
    test('D. Release asset selection prefers ARM64 APK on modern Android', () {
      final assets = [
        {
          'name': 'app-x86_64-release.apk',
          'browser_download_url': 'https://github.com/manojsai7/Astra-Ai-Tasks-manager-APK/releases/download/v2.1.1/app-x86_64-release.apk',
        },
        {
          'name': 'app-arm64-v8a-release.apk',
          'browser_download_url': 'https://github.com/manojsai7/Astra-Ai-Tasks-manager-APK/releases/download/v2.1.1/app-arm64-v8a-release.apk',
        },
        {
          'name': 'app-armeabi-v7a-release.apk',
          'browser_download_url': 'https://github.com/manojsai7/Astra-Ai-Tasks-manager-APK/releases/download/v2.1.1/app-armeabi-v7a-release.apk',
        },
      ];

      final arm64Url = AppUpdater.selectReleaseAsset(assets, targetAbi: 'arm64');
      expect(arm64Url, contains('app-arm64-v8a-release.apk'));

      final armv7Url = AppUpdater.selectReleaseAsset(assets, targetAbi: 'armv7');
      expect(armv7Url, contains('app-armeabi-v7a-release.apk'));
    });

    // E. Failure -> empty assets or bad URL returns safe fallback
    test('E. Failure handling and asset fallback', () {
      expect(AppUpdater.selectReleaseAsset([]), '');

      final fallbackAssets = [
        {
          'name': 'astra-release.apk',
          'browser_download_url': 'https://github.com/manojsai7/Astra-Ai-Tasks-manager-APK/releases/download/v2.1.1/astra-release.apk',
        },
      ];
      expect(AppUpdater.selectReleaseAsset(fallbackAssets), contains('astra-release.apk'));
    });

    // F. Repository URL & GitHub release configuration verification
    test('F. UpdateInfo data model retains release notes and metadata', () {
      const info = UpdateInfo(
        latestVersion: '2.1.1',
        currentVersion: '1.1.4',
        downloadUrl: 'https://github.com/manojsai7/Astra-Ai-Tasks-manager-APK/releases/download/v2.1.1/app-arm64-v8a-release.apk',
        releaseNotes: 'Smarter chat.\nBetter memory.\nImproved scheduling.',
        isAvailable: true,
      );

      expect(info.isAvailable, isTrue);
      expect(info.latestVersion, '2.1.1');
      expect(info.shortNotes, contains('Smarter chat.'));
      expect(info.downloadUrl, contains('manojsai7/Astra-Ai-Tasks-manager-APK'));
    });
  });
}
