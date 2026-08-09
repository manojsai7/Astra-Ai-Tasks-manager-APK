import 'package:flutter/material.dart';
import '../../../../app/router/router.dart';
import '../../../tasks/domain/services/task_extraction_service.dart';
import '../../domain/entities/inbox_item.dart';
import '../../domain/repositories/inbox_repository.dart';
import '../../domain/usecases/inbox_ingestion_use_case.dart';

/// Screen where users can manually input text or review incoming Android shares.
class InboxScreen extends StatefulWidget {
  final InboxIngestionUseCase useCase;
  final InboxRepository repository;
  final TaskExtractionService extractionService;
  final String? prefilledText;

  const InboxScreen({
    super.key,
    required this.useCase,
    required this.repository,
    required this.extractionService,
    this.prefilledText,
  });

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  late final TextEditingController _controller;
  bool _isConfirmingShare = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.prefilledText);
    _isConfirmingShare =
        widget.prefilledText != null && widget.prefilledText!.isNotEmpty;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _extractTask(InboxItem item) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final proposal = await widget.extractionService.extractTask(
        item.rawText,
        item.receivedAt,
      );

      if (mounted) {
        Navigator.of(context).pop(); // Pop loading dialog
      }

      if (mounted) {
        await Navigator.of(context).pushNamed(
          AstraRoutes.taskReview,
          arguments: {
            'proposal': proposal,
            'inboxItemId': item.id,
            'inboxReceivedAt': item.receivedAt,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Pop loading dialog
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Extraction failed: $e')));
      }
    }
  }

  Future<void> _submit() async {
    final text = _controller.text;
    if (text.trim().isEmpty) return;

    try {
      final source = _isConfirmingShare
          ? InboxSource.androidShare
          : InboxSource.manual;

      await widget.useCase(text, source);
      _controller.clear();
      setState(() {
        _isConfirmingShare = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Added to Inbox')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to ingest: $e')));
      }
    }
  }

  void _cancelConfirmation() {
    _controller.clear();
    setState(() {
      _isConfirmingShare = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Share cancelled')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(title: const Text('Inbox')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Ingestion / Share Confirmation Area
              if (_isConfirmingShare)
                _buildShareConfirmationCard(colorScheme, theme)
              else
                _buildManualInputRow(colorScheme),
              const SizedBox(height: 24),

              // Recent items header
              Text(
                'Recent Raw Items',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),

              // Observed List of Items
              Expanded(
                child: StreamBuilder<List<InboxItem>>(
                  stream: widget.repository.watchInboxItems(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading items: ${snapshot.error}',
                          style: TextStyle(color: colorScheme.error),
                        ),
                      );
                    }

                    final items = snapshot.data ?? [];
                    if (items.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 48,
                              color: colorScheme.outline,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Your inbox is empty',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final time = item.receivedAt.toLocal();
                        final formattedTime =
                            '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} '
                            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.rawText,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Source: ${item.sourceType}',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                    Text(
                                      formattedTime,
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () => _extractTask(item),
                                      icon: const Icon(
                                        Icons.auto_awesome,
                                        size: 16,
                                      ),
                                      label: const Text('Extract Task'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManualInputRow(ColorScheme colorScheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'Enter or paste raw text...',
            ),
            maxLines: null,
            keyboardType: TextInputType.multiline,
          ),
        ),
        const SizedBox(width: 12),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.add),
          label: const Text('Add'),
        ),
      ],
    );
  }

  Widget _buildShareConfirmationCard(ColorScheme colorScheme, ThemeData theme) {
    return Card(
      color: colorScheme.primaryContainer.withAlpha(50),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colorScheme.primary.withAlpha(100), width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.android_rounded, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Confirm Shared Text Ingestion',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Review or edit shared text...',
              ),
              maxLines: null,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _cancelConfirmation,
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Add to Inbox'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
