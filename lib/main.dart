import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/inbox_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/focus_screen.dart';
import 'providers/message_provider.dart';

void main() {
  runApp(
    const ProviderScope(
      child: AstraApp(),
    ),
  );
}

class AstraApp extends StatelessWidget {
  const AstraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ASTRA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainScreen(),
    );
  }
}

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;
  static const MethodChannel _shareChannel = MethodChannel('dev.codehunters.astra/share_bridge');

  static const List<Widget> _pages = [
    HomeScreen(),
    InboxScreen(),
    TasksScreen(),
    FocusScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initShareListener();
  }

  void _initShareListener() {
    // 1. Check for initial shared text (cold start)
    _shareChannel.invokeMethod<String>('getInitialShareText').then((text) {
      if (text != null && text.isNotEmpty) {
        _handleSharedText(text);
      }
    }).catchError((_) {});

    // 2. Listen for incoming shares while app is open (warm start)
    _shareChannel.setMethodCallHandler((call) async {
      if (call.method == 'onShareReceived') {
        final text = call.arguments as String?;
        if (text != null && text.isNotEmpty) {
          _handleSharedText(text);
        }
      }
    });
  }

  void _handleSharedText(String text) {
    // Add to inbox
    ref.read(messageNotifierProvider.notifier).addMessage(text);
    // Switch to inbox tab
    setState(() {
      _selectedIndex = 1; // Inbox index
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        backgroundColor: AppTheme.surface,
        indicatorColor: AppTheme.primary.withAlpha(51),
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: AppTheme.textMuted),
            selectedIcon: Icon(Icons.home, color: AppTheme.primary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.inbox_outlined, color: AppTheme.textMuted),
            selectedIcon: Icon(Icons.inbox, color: AppTheme.primary),
            label: 'Inbox',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined, color: AppTheme.textMuted),
            selectedIcon: Icon(Icons.checklist, color: AppTheme.primary),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.timer_outlined, color: AppTheme.textMuted),
            selectedIcon: Icon(Icons.timer, color: AppTheme.primary),
            label: 'Focus',
          ),
        ],
      ),
    );
  }
}
