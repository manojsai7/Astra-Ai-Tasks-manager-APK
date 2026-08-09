/// ASTRA — Application router
///
/// Defines the named routes for the ASTRA application and binds them
/// using explicit dependency injection.
library;

import 'package:flutter/material.dart';

import '../../features/home/home_screen.dart';
import '../../features/inbox/presentation/screens/inbox_screen.dart';
import '../../features/tasks/domain/entities/task_extraction_proposal.dart';
import '../../features/tasks/presentation/screens/task_review_screen.dart';
import '../../features/tasks/presentation/screens/tasks_screen.dart';
import '../app.dart';

// ---------------------------------------------------------------------------
// Route names
// ---------------------------------------------------------------------------

/// Named route constants.
abstract final class AstraRoutes {
  AstraRoutes._();

  /// Root / home route.
  static const String home = '/';

  /// Local Inbox screen route.
  static const String inbox = '/inbox';

  /// Tasks list screen route.
  static const String tasks = '/tasks';

  /// Task review screen route.
  static const String taskReview = '/task-review';
}

// ---------------------------------------------------------------------------
// Route factory
// ---------------------------------------------------------------------------

/// Returns the [Route] for the given [RouteSettings] injecting dependencies explicitly.
Route<dynamic>? onGenerateRoute(
  RouteSettings settings,
  Dependencies dependencies,
) {
  switch (settings.name) {
    case AstraRoutes.home:
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const HomeScreen(),
      );
    case AstraRoutes.inbox:
      final sharedText = settings.arguments as String?;
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => InboxScreen(
          useCase: dependencies.inboxIngestionUseCase,
          repository: dependencies.inboxRepository,
          extractionService: dependencies.taskExtractionService,
          prefilledText: sharedText,
        ),
      );
    case AstraRoutes.tasks:
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => TasksScreen(repository: dependencies.taskRepository),
      );
    case AstraRoutes.taskReview:
      final args = settings.arguments as Map<String, dynamic>;
      final proposal = args['proposal'] as TaskExtractionProposal;
      final inboxItemId = args['inboxItemId'] as String;
      final inboxReceivedAt = args['inboxReceivedAt'] as DateTime;

      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => TaskReviewScreen(
          proposal: proposal,
          inboxItemId: inboxItemId,
          inboxReceivedAt: inboxReceivedAt,
          useCase: dependencies.confirmTaskUseCase,
        ),
      );
    default:
      return null;
  }
}

/// Fallback route rendered when [onGenerateRoute] returns `null`.
Route<dynamic> onUnknownRoute(RouteSettings settings) {
  return MaterialPageRoute<void>(
    settings: settings,
    builder: (_) => const _NotFoundScreen(),
  );
}

// ---------------------------------------------------------------------------
// 404 screen
// ---------------------------------------------------------------------------

class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Route not found',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
