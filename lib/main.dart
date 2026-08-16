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
  final hasSeenAuth = prefs.getBool('hasSeenAuth') ?? false;

  runApp(
    ProviderScope(
      child: AstraApp(
        initialRoute: hasSeenAuth ? '/home' : '/auth',
      ),
    ),
  );
}
