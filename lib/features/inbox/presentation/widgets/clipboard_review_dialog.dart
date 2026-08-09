import 'package:flutter/material.dart';

/// Minimal confirmation/review dialog for clipboard intake.
///
/// Under Phase 1C:
/// - Allows the user to review the copied text.
/// - Allows the user to edit the text before ingestion.
/// - Provides "Ignore" and "Add to Inbox" actions.
/// - Disables "Add to Inbox" if the text is empty or whitespace-only.
class ClipboardReviewDialog extends StatefulWidget {
  final String initialText;

  const ClipboardReviewDialog({super.key, required this.initialText});

  /// Helper method to show the review dialog.
  ///
  /// Returns the confirmed text (original or edited) if user clicks "Add to Inbox",
  /// or `null` if the user ignores the prompt.
  static Future<String?> show(BuildContext context, String text) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false, // Force explicit action
      builder: (context) => ClipboardReviewDialog(initialText: text),
    );
  }

  @override
  State<ClipboardReviewDialog> createState() => _ClipboardReviewDialogState();
}

class _ClipboardReviewDialogState extends State<ClipboardReviewDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.assignment_turned_in_outlined, color: colorScheme.primary),
          const SizedBox(width: 8),
          const Text('New Clipboard Text'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'We detected copied text. Would you like to add it to your Inbox?',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Clipboard Content',
                border: OutlineInputBorder(),
              ),
              maxLines: null,
              keyboardType: TextInputType.multiline,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Ignore'),
        ),
        ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final text = _controller.text.trim();
            return FilledButton(
              onPressed: text.isEmpty
                  ? null
                  : () => Navigator.of(context).pop(_controller.text),
              child: const Text('Add to Inbox'),
            );
          },
        ),
      ],
    );
  }
}
