/// ASTRA — Temporary foundation home screen (Phase 0)
///
/// This screen exists only to verify that:
///  1. Application startup succeeds.
///  2. The Material 3 theme is applied correctly.
///  3. The project structure compiles and routes work.
library;

import 'package:flutter/material.dart';
import '../../app/router/router.dart';

/// Temporary foundation screen — validates theme + routing only.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'ASTRA',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                  letterSpacing: 2.0,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'AI-assisted personal planning and reminder application.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              // Simple visual check to ensure Material 3 theme colors are loaded
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Material 3 Theme Check',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _ColorIndicator(
                            color: colorScheme.primary,
                            label: 'Primary',
                            onColor: colorScheme.onPrimary,
                          ),
                          _ColorIndicator(
                            color: colorScheme.secondary,
                            label: 'Secondary',
                            onColor: colorScheme.onSecondary,
                          ),
                          _ColorIndicator(
                            color: colorScheme.primaryContainer,
                            label: 'Container',
                            onColor: colorScheme.onPrimaryContainer,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed(AstraRoutes.inbox);
                },
                icon: const Icon(Icons.inbox_outlined),
                label: const Text('Go to Inbox'),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed(AstraRoutes.tasks);
                },
                icon: const Icon(Icons.task_alt_outlined),
                label: const Text('Go to Tasks'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorIndicator extends StatelessWidget {
  const _ColorIndicator({
    required this.color,
    required this.label,
    required this.onColor,
  });

  final Color color;
  final String label;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Center(
            child: Text(
              'Aa',
              style: TextStyle(color: onColor, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
