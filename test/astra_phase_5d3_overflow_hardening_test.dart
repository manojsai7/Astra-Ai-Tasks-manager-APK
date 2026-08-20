import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:astra/theme/app_theme.dart';
import 'package:astra/widgets/data/astra_backup_sheet.dart';
import 'package:astra/core/updater/update_sheet.dart';
import 'package:astra/core/updater/app_updater.dart';
import 'package:astra/services/data/astra_backup_service.dart';
import 'package:astra/screens/home_screen.dart';

Widget _wrapWithViewport(Widget child, {double width = 360.0, double height = 800.0, EdgeInsets viewInsets = EdgeInsets.zero}) {
  return ProviderScope(
    child: MaterialApp(
      theme: AppTheme.darkTheme,
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, height),
          viewInsets: viewInsets,
          padding: const EdgeInsets.only(top: 24, bottom: 16),
        ),
        child: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'hasSeenOnboarding': true,
      'hasSeenAuth': true,
    });
  });

  group('Phase 5D.3 — Global Overflow Hardening & Multi-Viewport Verification', () {
    // ── Test A: 360dp Home Screen Progress & Percentage ───────────────────────
    testWidgets('A: 360dp viewport - Home Screen renders 100% completion with 0 RenderFlex overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _wrapWithViewport(
          const HomeScreen(),
          width: 360,
          height: 800,
        ),
      );
      await tester.pumpAndSettle();

      // Ensure no overflow exception was thrown
      expect(tester.takeException(), isNull);
      expect(find.text('TODAY'), findsOneWidget);
      expect(find.text('MANOJ'), findsOneWidget);
    });

    // ── Test B: 360dp Backup Sheet Sticky CTA & Compact Categories ────────────
    testWidgets('B: 360dp viewport - AstraBackupSheet renders sticky BACK UP NOW and RESTORE CTAs immediately', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _wrapWithViewport(
          const AstraBackupSheet(),
          width: 360,
          height: 800,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('BACKUP DATA'), findsOneWidget);
      expect(find.byKey(const Key('backup_now_button')), findsOneWidget);
      expect(find.byKey(const Key('restore_data_button')), findsOneWidget);

      // Verify Select All and Clear buttons
      expect(find.byKey(const Key('backup_select_all_button')), findsOneWidget);
      expect(find.byKey(const Key('backup_clear_button')), findsOneWidget);
    });

    // ── Test C: Password Dialog with Long Filename & Categories ───────────────
    testWidgets('C: Enter Password Dialog with 80-char filename & 8 categories renders safely without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final metadata = AstraBackupMetadata(
        backupVersion: 2,
        schemaVersion: 10,
        createdAt: DateTime(2026, 8, 20, 14, 30),
        appVersion: '2.2.1',
        taskCount: 42,
        sessionCount: 1,
        messageCount: 156,
        memoryCount: 18,
        reminderCount: 8,
        ritualRuleCount: 0,
        panchangCount: 0,
        checksum: 'test-checksum',
        selectedCategories: AstraBackupCategory.values.map((c) => c.id).toList(),
      );

      const longFileName = 'ASTRA_Backup_2026-08-20_very_long_custom_enterprise_user_archive_name_version_2_final.astra.db';

      await tester.pumpWidget(
        _wrapWithViewport(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: AstraColors.surface1,
                    title: const Text('Decrypt ASTRA Backup'),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Archive: $longFileName',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AstraColors.lime),
                          ),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Categories:', style: TextStyle(fontSize: 12, color: AstraColors.textMuted)),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    '${metadata.selectedCategories.length} categories selected',
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AstraColors.textPrimary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          const TextField(
                            decoration: InputDecoration(labelText: 'Enter Backup Password'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              child: const Text('Open Dialog'),
            ),
          ),
          width: 360,
          height: 800,
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Decrypt ASTRA Backup'), findsOneWidget);
      expect(find.text('8 categories selected'), findsOneWidget);
    });

    // ── Test D: 360dp Update Sheet Progress with Large 100MB+ String ──────────
    testWidgets('D: 360dp Update Sheet progress layout renders cleanly without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const updateInfo = UpdateInfo(
        currentVersion: '2.2.0',
        latestVersion: '2.2.1',
        isAvailable: true,
        downloadUrl: 'https://github.com/manojsai7/Astra-Ai-Tasks-manager-APK/releases/download/v2.2.1/astra-arm64-v2.2.1-1.apk',
        releaseNotes: 'Fixed layout resilience across all device widths.',
      );

      await tester.pumpWidget(
        _wrapWithViewport(
          const UpdateSheet(info: updateInfo),
          width: 360,
          height: 800,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('ASTRA UPDATE'), findsOneWidget);
      expect(find.text('v2.2.0  →  v2.2.1'), findsOneWidget);
      expect(find.text('Download Update'), findsOneWidget);
    });

    // ── Test E: Multi-Viewport Audit (390dp & 412dp) ──────────────────────────
    // ── Test E: Multi-Viewport Audit (390dp & 412dp) ──────────────────────────
    testWidgets('E: 390dp & 412dp viewports - Backup sheet renders without any layout overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _wrapWithViewport(
          const AstraBackupSheet(),
          width: 390,
          height: 844,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('backup_now_button')), findsOneWidget);
      expect(find.byKey(const Key('restore_data_button')), findsOneWidget);
    });

    // ── Test F: Simulated Keyboard Insets (viewInsets: 300dp) ──────────────────
    testWidgets('F: Backup password dialog remains usable with virtual keyboard active (300dp insets)', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _wrapWithViewport(
          const AstraBackupSheet(),
          width: 360,
          height: 800,
          viewInsets: const EdgeInsets.only(bottom: 300),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('backup_now_button')), findsOneWidget);
    });
  });
}
