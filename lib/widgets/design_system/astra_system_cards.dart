import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'astra_card.dart';

/// Standardized loading card component matching ASTRA dark tactile design.
class AstraLoadingCard extends StatelessWidget {
  final String message;
  const AstraLoadingCard({super.key, this.message = 'Loading...'});

  @override
  Widget build(BuildContext context) {
    return AstraCard(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AstraColors.lime,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              style: AstraText.label(color: AstraColors.textMuted, size: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// Standardized error card component with retry action.
class AstraErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const AstraErrorCard({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return AstraCard(
      borderColor: AstraColors.red.withValues(alpha: .5),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AstraColors.red, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              message,
              style: AstraText.body(size: 14, color: AstraColors.textPrimary),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 10),
            TextButton(
              onPressed: onRetry,
              child: Text('RETRY', style: AstraText.label(color: AstraColors.lime, size: 12)),
            ),
          ],
        ],
      ),
    );
  }
}

/// Standardized AI Thinking Indicator for Assistant states.
class AstraThinkingIndicator extends StatelessWidget {
  const AstraThinkingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return AstraCard(
      borderColor: AstraColors.cyan.withValues(alpha: .4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AstraColors.cyan,
            ),
          ),
          const SizedBox(width: 12),
          Text('Thinking...', style: AstraText.label(color: AstraColors.cyan, size: 12)),
        ],
      ),
    );
  }
}
