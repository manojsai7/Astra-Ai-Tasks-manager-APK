import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/database/database.dart';
import 'providers/reminder_provider.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();

  try {
    final db = constructDb();
    await bootstrapReminderEngine(db);
  } catch (e) {
    debugPrint('[main] Reminder engine bootstrap error: $e');
  }

  final prefs = await SharedPreferences.getInstance();
  final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
  final hasSeenAuth = prefs.getBool('hasSeenAuth') ?? false;

  // Route logic:
  //   - First launch → /onboarding (sets hasSeenOnboarding at completion)
  //   - Returning user, not yet authenticated → /auth
  //   - Returning user, authenticated → /home
  final String initialRoute;
  if (!hasSeenOnboarding) {
    initialRoute = '/onboarding';
  } else if (!hasSeenAuth) {
    initialRoute = '/auth';
  } else {
    initialRoute = '/home';
  }

  runApp(
    ProviderScope(
      child: AstraApp(
        initialRoute: initialRoute,
      ),
    ),
  );
}
