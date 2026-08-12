import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_updater.dart';
import 'update_downloader.dart';


/// Shows a styled bottom-sheet when a new ASTRA version is available.
///
/// Usage:
///   ```dart
///   UpdateSheet.show(context, info);
///   ```
class UpdateSheet extends StatelessWidget {
  final UpdateInfo info;
  const UpdateSheet({super.key, required this.info});

  /// Checks for an update and shows the sheet if one is available.
  /// Call this in [main.dart] or any screen's [initState] — it is silent on failure.
  static Future<void> checkAndShow(BuildContext context) async {
    final info = await AppUpdater.check();
    if (info == null || !info.isAvailable) return;
    if (!context.mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UpdateSheet(info: info),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      decoration: BoxDecoration(
        color: const Color(0xFF12121A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF7C65F4).withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C65F4), Color(0xFFC6FF3D)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.system_update_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Update Available 🚀',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'v${info.currentVersion}  →  v${info.latestVersion}',
                      style: const TextStyle(color: Color(0xFFC6FF3D), fontSize: 13),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Release notes preview ───────────────────────────────────
            if (info.shortNotes.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(
                  info.shortNotes,
                  style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Actions ────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white54,
                      side: const BorderSide(color: Colors.white12),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Later'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C65F4), Color(0xFF9C85FF)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.download_rounded, color: Colors.white, size: 18),
                      label: const Text(
                        'Download & Install',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                      onPressed: () => _download(context),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Opens GitHub CDN — free & fast',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _download(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);

    final url = info.downloadUrl.isNotEmpty
        ? info.downloadUrl
        : 'https://github.com/manojsai7/Ai-Tasks-manager/releases/latest';

    messenger.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFC6FF3D)),
            ),
            SizedBox(width: 12),
            Text('Downloading update APK...'),
          ],
        ),
        duration: Duration(seconds: 15),
      ),
    );

    final fileName = 'astra_v${info.latestVersion}.apk';
    final success = await UpdateDownloader.downloadAndInstall(
      url: url,
      fileName: fileName,
    );

    messenger.hideCurrentSnackBar();

    if (!success) {
      // Fallback: Open browser download link
      final uri = Uri.parse(url);
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Could not open download link.')),
        );
      }
    }
  }
}
