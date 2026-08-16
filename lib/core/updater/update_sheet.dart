import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_theme.dart';
import '../../widgets/design_system/astra_3d_button.dart';
import 'app_updater.dart';
import 'update_downloader.dart';

/// Premium ASTRA Update Modal Sheet matching the dark glass / neon-lime / cyan ASTRA design system.
class UpdateSheet extends StatefulWidget {
  final UpdateInfo info;
  const UpdateSheet({super.key, required this.info});

  /// Checks for an update and shows the sheet if one is available.
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
  State<UpdateSheet> createState() => _UpdateSheetState();
}

class _UpdateSheetState extends State<UpdateSheet> {
  UpdateDownloadState _state = UpdateDownloadState.available;
  double _progress = 0.0;
  int _downloadedBytes = 0;
  int _totalBytes = 0;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      decoration: BoxDecoration(
        color: AstraColors.surface0,
        borderRadius: BorderRadius.circular(AstraRadii.lg),
        border: Border.all(color: AstraColors.edge, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AstraColors.cyan.withValues(alpha: 0.08),
            blurRadius: 16,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Indicator & Header ──
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AstraColors.surface1,
                    borderRadius: BorderRadius.circular(AstraRadii.md),
                    border: Border.all(color: AstraColors.edgeSoft, width: 1),
                  ),
                  child: Icon(
                    _state == UpdateDownloadState.downloaded
                        ? LucideIcons.check
                        : _state == UpdateDownloadState.downloading
                            ? LucideIcons.arrowDownToLine
                            : LucideIcons.sparkles,
                    color: _state == UpdateDownloadState.downloaded
                        ? AstraColors.lime
                        : AstraColors.cyan,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _state == UpdateDownloadState.downloaded
                            ? 'ASTRA UPDATE READY'
                            : _state == UpdateDownloadState.downloading
                                ? 'DOWNLOADING ASTRA'
                                : 'ASTRA UPDATE',
                        style: AstraText.label(
                          color: _state == UpdateDownloadState.downloaded
                              ? AstraColors.lime
                              : AstraColors.cyan,
                          size: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'v${widget.info.currentVersion}  →  v${widget.info.latestVersion}',
                        style: AstraText.metric(color: AstraColors.textPrimary, size: 16),
                      ),
                    ],
                  ),
                ),
                if (_state != UpdateDownloadState.downloading)
                  IconButton(
                    icon: const Icon(LucideIcons.x, color: AstraColors.textMuted, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Dynamic Content based on State ──
            if (_state == UpdateDownloadState.available) ...[
              // Release notes preview
              if (widget.info.shortNotes.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AstraColors.surface1,
                    borderRadius: BorderRadius.circular(AstraRadii.sm),
                    border: Border.all(color: AstraColors.borderSoft, width: 1),
                  ),
                  child: Text(
                    widget.info.shortNotes,
                    style: AstraText.caption(color: AstraColors.textSecondary, size: 13),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Actions
              Row(
                children: [
                  Expanded(
                    child: Astra3DButton(
                      label: 'Later',
                      palette: AstraMaterials.dark,
                      height: 48,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Astra3DButton(
                      label: 'Download update ',
                      palette: AstraMaterials.lime,
                      icon: LucideIcons.download,
                      height: 48,
                      onPressed: _startDownload,
                    ),
                  ),
                ],
              ),
            ] else if (_state == UpdateDownloadState.downloading) ...[
              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: _progress > 0 ? _progress : null,
                  backgroundColor: AstraColors.surface2,
                  valueColor: const AlwaysStoppedAnimation<Color>(AstraColors.lime),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Downloading APK…',
                    style: AstraText.caption(color: AstraColors.textSecondary, size: 12),
                  ),
                  Text(
                    _totalBytes > 0
                        ? '${UpdateDownloader.formatBytes(_downloadedBytes)} / ${UpdateDownloader.formatBytes(_totalBytes)} (${(_progress * 100).toInt()}%)'
                        : '${(_progress * 100).toInt()}%',
                    style: AstraText.metric(color: AstraColors.lime, size: 12),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Download continues in background',
                style: AstraText.caption(color: AstraColors.textDisabled, size: 11),
              ),
            ] else if (_state == UpdateDownloadState.downloaded ||
                _state == UpdateDownloadState.installing) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AstraColors.surface1,
                  borderRadius: BorderRadius.circular(AstraRadii.sm),
                  border: Border.all(color: AstraColors.borderSoft, width: 1),
                ),
                child: Text(
                  'ASTRA v${widget.info.latestVersion} has been downloaded.\nTap Install to update.',
                  style: AstraText.body(color: AstraColors.textPrimary, size: 13),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Astra3DButton(
                      label: 'Close',
                      palette: AstraMaterials.dark,
                      height: 48,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Astra3DButton(
                      label: 'INSTALL NOW',
                      palette: AstraMaterials.lime,
                      icon: LucideIcons.packageCheck,
                      height: 48,
                      onPressed: _installAgain,
                    ),
                  ),
                ],
              ),
            ] else if (_state == UpdateDownloadState.failed) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AstraColors.surface1,
                  borderRadius: BorderRadius.circular(AstraRadii.sm),
                  border: Border.all(color: AstraColors.red.withValues(alpha: 0.3), width: 1),
                ),
                child: Text(
                  _errorMessage ?? 'Download failed. Tap below to open in browser.',
                  style: AstraText.caption(color: AstraColors.red, size: 12),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Astra3DButton(
                      label: 'Cancel',
                      palette: AstraMaterials.dark,
                      height: 48,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Astra3DButton(
                      label: 'Open Browser',
                      palette: AstraMaterials.cyan,
                      icon: LucideIcons.externalLink,
                      height: 48,
                      onPressed: _openInBrowser,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 10),
            Center(
              child: Text(
                'Manojsai CDN · manojsai7/Astra-Ai-Tasks-manager-APK',
                style: AstraText.caption(color: AstraColors.textDisabled, size: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startDownload() async {
    setState(() {
      _state = UpdateDownloadState.downloading;
      _progress = 0.0;
      _errorMessage = null;
    });

    final url = widget.info.downloadUrl.isNotEmpty
        ? widget.info.downloadUrl
        : 'https://github.com/manojsai7/Astra-Ai-Tasks-manager-APK/releases/latest';

    final fileName = 'astra_v${widget.info.latestVersion}.apk';

    await UpdateDownloader.downloadAndInstall(
      url: url,
      fileName: fileName,
      onProgress: (p, downloaded, total) {
        if (mounted) {
          setState(() {
            _progress = p;
            _downloadedBytes = downloaded;
            _totalBytes = total;
          });
        }
      },
      onStateChanged: (state, error) {
        if (mounted) {
          setState(() {
            _state = state;
            _errorMessage = error;
          });
        }
      },
    );
  }

  Future<void> _installAgain() async {
    _startDownload();
  }

  Future<void> _openInBrowser() async {
    final url = widget.info.downloadUrl.isNotEmpty
        ? widget.info.downloadUrl
        : 'https://github.com/manojsai7/Astra-Ai-Tasks-manager-APK/releases/latest';
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (mounted) Navigator.pop(context);
  }
}
