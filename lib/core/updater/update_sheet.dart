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
  String? _persistedApkPath;
  bool _showTechnicalDetails = false;

  @override
  void initState() {
    super.initState();
    _checkPersistedApk();
  }

  Future<void> _checkPersistedApk() async {
    final file = await UpdateDownloader.getPersistedApk(version: widget.info.latestVersion);
    if (file != null && mounted) {
      setState(() {
        _state = UpdateDownloadState.downloaded;
        _persistedApkPath = file.path;
      });
    }
  }

  Future<void> _startDownload() async {
    if (widget.info.downloadUrl.isEmpty) {
      setState(() {
        _state = UpdateDownloadState.failed;
        _errorMessage = 'Download link not available for this release.';
      });
      return;
    }

    setState(() {
      _state = UpdateDownloadState.downloading;
      _progress = 0.0;
      _downloadedBytes = 0;
      _errorMessage = null;
    });

    await UpdateDownloader.downloadAndInstall(
      url: widget.info.downloadUrl,
      version: widget.info.latestVersion,
      onProgress: (progress, downloaded, total) {
        if (mounted) {
          setState(() {
            _progress = progress;
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
          if (state == UpdateDownloadState.downloaded) {
            _checkPersistedApk();
          }
        }
      },
    );
  }

  Future<void> _installPersisted() async {
    if (_persistedApkPath != null && _persistedApkPath!.isNotEmpty) {
      await UpdateDownloader.installApk(
        _persistedApkPath!,
        onStateChanged: (state, error) {
          if (mounted) {
            setState(() {
              _state = state;
              _errorMessage = error;
            });
          }
        },
      );
    } else {
      _startDownload();
    }
  }

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
                        ? LucideIcons.packageCheck
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
                            ? 'DOWNLOADED • READY TO INSTALL'
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
                      label: 'Download Update',
                      palette: AstraMaterials.lime,
                      icon: LucideIcons.download,
                      height: 48,
                      onPressed: _startDownload,
                    ),
                  ),
                ],
              ),
            ] else if (_state == UpdateDownloadState.downloading) ...[
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
                    'Downloading to Downloads/…',
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
                'Persistent APK saved to Downloads/ASTRA',
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
                  border: Border.all(color: AstraColors.lime.withValues(alpha: 0.3), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ASTRA-v${widget.info.latestVersion}.apk is saved in Downloads.',
                      style: AstraText.body(color: AstraColors.textPrimary, size: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ready to install. The file will remain in Downloads if you need to retry.',
                      style: AstraText.caption(color: AstraColors.textMuted, size: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Astra3DButton(
                      label: 'RE-DOWNLOAD',
                      palette: AstraMaterials.dark,
                      icon: LucideIcons.refreshCw,
                      height: 48,
                      onPressed: _startDownload,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Astra3DButton(
                      label: 'INSTALL',
                      palette: AstraMaterials.lime,
                      icon: LucideIcons.packageCheck,
                      height: 48,
                      onPressed: _installPersisted,
                    ),
                  ),
                ],
              ),
            ] else if (_state == UpdateDownloadState.failed) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AstraColors.surface1,
                  borderRadius: BorderRadius.circular(AstraRadii.sm),
                  border: Border.all(color: AstraColors.red.withValues(alpha: 0.4), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.alertTriangle, color: AstraColors.red, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Update couldn\'t be downloaded',
                          style: AstraText.label(color: AstraColors.red, size: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      UpdateDownloader.friendlyDownloadError(_errorMessage),
                      style: AstraText.body(color: AstraColors.textSecondary, size: 12.5),
                    ),
                    if (_errorMessage != null && _errorMessage!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => setState(() => _showTechnicalDetails = !_showTechnicalDetails),
                        child: Row(
                          children: [
                            Text(
                              _showTechnicalDetails ? 'Technical details ▾' : 'Technical details ▸',
                              style: AstraText.caption(color: AstraColors.textMuted, size: 11),
                            ),
                          ],
                        ),
                      ),
                      if (_showTechnicalDetails) ...[
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: SelectableText(
                            _errorMessage!,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10,
                              color: AstraColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Astra3DButton(
                      label: 'Download Page',
                      palette: AstraMaterials.dark,
                      icon: LucideIcons.externalLink,
                      height: 48,
                      onPressed: () {
                        if (widget.info.downloadUrl.isNotEmpty) {
                          launchUrl(
                            Uri.parse(widget.info.downloadUrl),
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Astra3DButton(
                      label: 'Retry Download',
                      palette: AstraMaterials.lime,
                      icon: LucideIcons.refreshCw,
                      height: 48,
                      onPressed: _startDownload,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
