import 'package:flutter/services.dart';

/// Centralized tactile haptics service for ASTRA.
///
/// Provides structured, subtle haptic feedback for:
/// - Selection / Tab / Filter changes
/// - Recurrence chip taps
/// - Task / Reminder creation success
/// - Task toggle completion & deletion
/// - Snooze and time shift actions
///
/// Safe across all platforms and unit test runners (swallows MissingPluginException/PlatformException).
class AstraHaptics {
  const AstraHaptics._();

  static bool isEnabled = true;

  /// Lightweight tick for discrete selections (chips, segmented buttons, tabs).
  static Future<void> selection() async {
    if (!isEnabled) return;
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }

  /// Subtle tap for button presses and navigation items.
  static Future<void> light() async {
    if (!isEnabled) return;
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Solid tactile click for primary submissions, saves, and confirmation.
  static Future<void> medium() async {
    if (!isEnabled) return;
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Pronounced feedback for destructive or high-impact actions.
  static Future<void> heavy() async {
    if (!isEnabled) return;
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// Satisfying success pulse on completing a task or saving a new entity.
  static Future<void> success() async {
    if (!isEnabled) return;
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Warning feedback for ambiguous input or deletion confirmation.
  static Future<void> warning() async {
    if (!isEnabled) return;
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// Tactile feedback when deleting or clearing a task.
  static Future<void> delete() async {
    if (!isEnabled) return;
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }
}
