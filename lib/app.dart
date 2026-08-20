import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/reminder_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/profile_settings_screen.dart';
import 'screens/profile_setup_gate.dart';

class AstraApp extends ConsumerStatefulWidget {
  final String initialRoute;
  const AstraApp({super.key, required this.initialRoute});

  @override
  ConsumerState<AstraApp> createState() => _AstraAppState();
}

class _AstraAppState extends ConsumerState<AstraApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listenManual(authProvider, (previous, next) {
        if ((previous?.isAuthenticated ?? true) && !next.isAuthenticated) {
          _navigatorKey.currentState?.pushNamedAndRemoveUntil('/auth', (r) => false);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(reminderBootstrapProvider);

    return MaterialApp(
      title: 'ASTRA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      navigatorKey: _navigatorKey,
      initialRoute: widget.initialRoute,
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/auth': (context) => const AuthScreen(),
        '/home': (context) => const ProfileSetupGate(),
        '/profile': (context) => const ProfileSettingsScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/home') {
          return PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const ProfileSetupGate(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              final scale = Tween<double>(begin: 0.96, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              );
              final opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut),
              );
              return FadeTransition(
                opacity: opacity,
                child: ScaleTransition(scale: scale, child: child),
              );
            },
            transitionDuration: const Duration(milliseconds: 260),
          );
        }
        return null;
      },
    );
  }
}
