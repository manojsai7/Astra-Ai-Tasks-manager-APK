/// ASTRA — Root application widget and dependency composition root
///
/// [AstraApp] is the top-level widget that configures [MaterialApp].
/// [Dependencies] is a simple container class for explicit constructor injection.
library;

import 'dart:async';
import 'package:flutter/material.dart';

import '../core/database/database.dart';
import '../core/native_bridge/native_bridge.dart';
import '../features/inbox/domain/entities/inbox_item.dart';
import '../features/inbox/domain/repositories/inbox_repository.dart';
import '../features/inbox/domain/services/clipboard_intake_service.dart';
import '../features/inbox/domain/usecases/inbox_ingestion_use_case.dart';
import '../features/inbox/presentation/widgets/clipboard_review_dialog.dart';
import '../features/tasks/domain/repositories/task_repository.dart';
import '../features/tasks/domain/services/task_extraction_service.dart';
import '../features/tasks/domain/usecases/confirm_task_use_case.dart';
import 'router/router.dart';
import 'theme/theme.dart';

/// Composition root holding instantiated dependencies.
class Dependencies {
  final AppDatabase database;
  final InboxRepository inboxRepository;
  final InboxIngestionUseCase inboxIngestionUseCase;
  final NativeBridge nativeBridge;
  final ClipboardIntakeService clipboardIntakeService;
  final TaskRepository taskRepository;
  final ConfirmTaskUseCase confirmTaskUseCase;
  final TaskExtractionService taskExtractionService;

  const Dependencies({
    required this.database,
    required this.inboxRepository,
    required this.inboxIngestionUseCase,
    required this.nativeBridge,
    required this.clipboardIntakeService,
    required this.taskRepository,
    required this.confirmTaskUseCase,
    required this.taskExtractionService,
  });
}

/// The root widget of the ASTRA application.
class AstraApp extends StatefulWidget {
  final Dependencies dependencies;

  const AstraApp({super.key, required this.dependencies});

  @override
  State<AstraApp> createState() => _AstraAppState();
}

class _AstraAppState extends State<AstraApp> with WidgetsBindingObserver {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final StreamSubscription<String> _shareSubscription;
  bool _isCheckingClipboard = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Listen to native warm-intent shares while the app is running
    _shareSubscription = widget.dependencies.nativeBridge.shareStream.listen(
      _onShareReceived,
    );

    // Check for cold-start share text and clipboard content after the first frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final initialText = await widget.dependencies.nativeBridge
          .getInitialShareText();
      if (initialText != null && initialText.isNotEmpty) {
        _onShareReceived(initialText);
      } else {
        await _checkClipboard();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _shareSubscription.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkClipboard();
    }
  }

  Future<void> _checkClipboard() async {
    if (_isCheckingClipboard) return;
    _isCheckingClipboard = true;

    try {
      final clipboardService = widget.dependencies.clipboardIntakeService;
      final text = await clipboardService.getClipboardText();

      if (clipboardService.shouldPrompt(text)) {
        // Mark processed immediately so that a subsequent resume (or fast clicks) does not trigger another dialog
        clipboardService.markProcessed(text);

        final context = _navigatorKey.currentContext;
        if (context != null && context.mounted) {
          final confirmedText = await ClipboardReviewDialog.show(
            context,
            text!,
          );
          if (confirmedText != null && context.mounted) {
            final messenger = ScaffoldMessenger.of(context);
            try {
              await widget.dependencies.inboxIngestionUseCase(
                confirmedText,
                InboxSource.clipboard,
              );
              messenger.showSnackBar(
                const SnackBar(content: Text('Added to Inbox')),
              );
            } catch (e) {
              messenger.showSnackBar(
                SnackBar(content: Text('Failed to ingest clipboard: $e')),
              );
            }
          }
        }
      }
    } finally {
      _isCheckingClipboard = false;
    }
  }

  void _onShareReceived(String text) {
    // Navigate using the navigatorKey since we are executing above the Navigator context
    _navigatorKey.currentState?.pushNamed(AstraRoutes.inbox, arguments: text);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'ASTRA',
      debugShowCheckedModeBanner: false,
      theme: astraTheme(Brightness.light),
      darkTheme: astraTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      initialRoute: AstraRoutes.home,
      onGenerateRoute: (settings) =>
          onGenerateRoute(settings, widget.dependencies),
      onUnknownRoute: onUnknownRoute,
    );
  }
}
