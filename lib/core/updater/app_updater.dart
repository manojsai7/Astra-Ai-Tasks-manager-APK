import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

/// ASTRA App Updater
///
/// Checks GitHub Releases for a newer version of the app.
/// Uses zero paid services — GitHub's free API + CDN is the backend.
///
/// Flow:
///   App starts → [AppUpdater.check()] → compares versions →
///   Returns [UpdateInfo] → UI shows bottom-sheet if update available →
///   User taps "Download" → [url_launcher] opens the APK download URL.
class AppUpdater {
  static const String _owner = 'manojsai7';
  static const String _repo  = 'Ai-Tasks-manager';

  /// GitHub Releases API endpoint — always points to the latest release.
  static const String _apiUrl =
      'https://api.github.com/repos/$_owner/$_repo/releases/latest';

  /// Queries GitHub for the latest release and compares it against
  /// the installed version. Returns [null] if the check fails silently.
  static Future<UpdateInfo?> check() async {
    try {
      final response = await http
          .get(Uri.parse(_apiUrl), headers: {'Accept': 'application/vnd.github+json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      // Tag format: "v1.2.3" — strip the leading "v".
      final rawTag = (data['tag_name'] as String? ?? '').replaceFirst('v', '');
      if (rawTag.isEmpty) return null;

      final releaseNotes = data['body'] as String? ?? '';
      final assets = (data['assets'] as List<dynamic>?) ?? [];

      // Prefer arm64 APK; fall back to the first asset.
      String downloadUrl = '';
      for (final asset in assets) {
        final name = (asset['name'] as String? ?? '').toLowerCase();
        if (name.contains('arm64-v8a') && name.endsWith('.apk')) {
          downloadUrl = asset['browser_download_url'] as String? ?? '';
          break;
        }
      }
      if (downloadUrl.isEmpty && assets.isNotEmpty) {
        downloadUrl = assets.first['browser_download_url'] as String? ?? '';
      }

      // Get current installed version.
      final info = await PackageInfo.fromPlatform();
      final currentVersion = info.version; // e.g. "1.0.0"

      final isNewer = _isNewer(rawTag, currentVersion);

      return UpdateInfo(
        latestVersion: rawTag,
        currentVersion: currentVersion,
        downloadUrl: downloadUrl,
        releaseNotes: releaseNotes.trim(),
        isAvailable: isNewer,
      );
    } catch (_) {
      // Never crash the app because of an update check failure.
      return null;
    }
  }

  // ─── Version Comparison ───────────────────────────────────────────────────

  /// Returns true if [latest] is strictly newer than [current].
  /// Handles "1.2.3" style semver strings.
  static bool _isNewer(String latest, String current) {
    try {
      final l = _parse(latest);
      final c = _parse(current);
      for (int i = 0; i < l.length && i < c.length; i++) {
        if (l[i] > c[i]) return true;
        if (l[i] < c[i]) return false;
      }
      return l.length > c.length;
    } catch (_) {
      return false;
    }
  }

  static List<int> _parse(String v) =>
      v.split('.').map((p) => int.tryParse(p) ?? 0).toList();
}

// ─── Data Model ───────────────────────────────────────────────────────────────

class UpdateInfo {
  final String latestVersion;
  final String currentVersion;
  final String downloadUrl;
  final String releaseNotes;
  final bool isAvailable;

  const UpdateInfo({
    required this.latestVersion,
    required this.currentVersion,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.isAvailable,
  });

  /// Short release note preview (first 3 lines).
  String get shortNotes {
    final lines = releaseNotes.split('\n').where((l) => l.trim().isNotEmpty).toList();
    return lines.take(3).join('\n');
  }
}
