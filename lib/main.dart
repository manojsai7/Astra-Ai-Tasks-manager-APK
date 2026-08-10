import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();

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
