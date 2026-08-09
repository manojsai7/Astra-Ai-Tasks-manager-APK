import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/inbox_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/focus_screen.dart';
import 'screens/assistant_screen.dart';
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
    AssistantScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initShareListener();
  }

  void _initShareListener() {
    _shareChannel.invokeMethod<String>('getInitialShareText').then((text) {
      if (text != null && text.isNotEmpty) {
        _handleSharedText(text);
      }
    }).catchError((_) {});

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
    ref.read(messageNotifierProvider.notifier).addMessage(text);
    setState(() {
      _selectedIndex = 1;
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
        indicatorColor: AppTheme.primary.withAlpha(38),
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(LucideIcons.house, color: AppTheme.textMuted, size: 20),
            selectedIcon: Icon(LucideIcons.house, color: AppTheme.primary, size: 20),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.inbox, color: AppTheme.textMuted, size: 20),
            selectedIcon: Icon(LucideIcons.inbox, color: AppTheme.primary, size: 20),
            label: 'Inbox',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.checkSquare, color: AppTheme.textMuted, size: 20),
            selectedIcon: Icon(LucideIcons.checkSquare, color: AppTheme.primary, size: 20),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.timer, color: AppTheme.textMuted, size: 20),
            selectedIcon: Icon(LucideIcons.timer, color: AppTheme.primary, size: 20),
            label: 'Focus',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.bot, color: AppTheme.textMuted, size: 20),
            selectedIcon: Icon(LucideIcons.bot, color: AppTheme.primary, size: 20),
            label: 'Assistant',
          ),
        ],
      ),
    );
  }
}
