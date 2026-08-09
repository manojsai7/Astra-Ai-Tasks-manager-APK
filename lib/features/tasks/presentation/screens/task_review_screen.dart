import 'package:flutter/material.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_extraction_proposal.dart';
import '../../domain/usecases/confirm_task_use_case.dart';
import '../../domain/utils/temporal_resolver.dart';

/// Screen where the user reviews and confirms/edits a task extraction proposal.
class TaskReviewScreen extends StatefulWidget {
  final TaskExtractionProposal proposal;
  final String inboxItemId;
  final DateTime inboxReceivedAt;
  final ConfirmTaskUseCase useCase;

  const TaskReviewScreen({
    super.key,
    required this.proposal,
    required this.inboxItemId,
    required this.inboxReceivedAt,
    required this.useCase,
  });

  @override
  State<TaskReviewScreen> createState() => _TaskReviewScreenState();
}

class _TaskReviewScreenState extends State<TaskReviewScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late TaskType _selectedType;
  late TaskPriority _selectedPriority;
  DateTime? _selectedDueDate;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.proposal.title);
    _descriptionController = TextEditingController(
      text: widget.proposal.description,
    );
    _selectedType = widget.proposal.taskType;
    _selectedPriority = widget.proposal.priority;

    // Resolve date and time using deterministic resolver
    _selectedDueDate = TemporalResolver.resolve(
      dateExpression: widget.proposal.dateExpression,
      timeExpression: widget.proposal.timeExpression,
      referenceTime: widget.inboxReceivedAt,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final initialDate = _selectedDueDate ?? DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2035),
    );

    if (pickedDate == null) return;

    if (!mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );

    setState(() {
      _selectedDueDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime?.hour ?? 0,
        pickedTime?.minute ?? 0,
      );
    });
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task title cannot be empty')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.useCase(
        title: title,
        description: _descriptionController.text,
        taskType: _selectedType,
        priority: _selectedPriority,
        dueAt: _selectedDueDate,
        inboxItemId: widget.inboxItemId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task saved successfully!')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to confirm task: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Detect if we failed to resolve date even though AI proposed something
    final dateAmbiguous =
        _selectedDueDate == null && widget.proposal.dateExpression != null;
    final warningRequired = widget.proposal.requiresReview || dateAmbiguous;

    return Scaffold(
      appBar: AppBar(title: const Text('Review Extracted Task')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Uncertainty / Review warning panel
              if (warningRequired)
                Card(
                  color: colorScheme.errorContainer,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: colorScheme.error, width: 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: colorScheme.onErrorContainer,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Requires Verification',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onErrorContainer,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (widget.proposal.requiresReview &&
                            widget.proposal.uncertaintyReason != null)
                          Text(
                            'AI Notice: ${widget.proposal.uncertaintyReason}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onErrorContainer,
                            ),
                          ),
                        if (dateAmbiguous) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Temporal Alert: The date expression "${widget.proposal.dateExpression}" could not be resolved deterministically. Please select a due date manually.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onErrorContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Title input
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Task Title',
                  border: OutlineInputBorder(),
                  hintText: 'Enter task title...',
                ),
              ),
              const SizedBox(height: 16),

              // Description input
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description / Context',
                  border: OutlineInputBorder(),
                  hintText: 'Enter description (optional)...',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Task Type Dropdown
              DropdownButtonFormField<TaskType>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Task Type',
                  border: OutlineInputBorder(),
                ),
                items: TaskType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedType = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Task Priority Dropdown
              DropdownButtonFormField<TaskPriority>(
                initialValue: _selectedPriority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                ),
                items: TaskPriority.values.map((priority) {
                  return DropdownMenuItem(
                    value: priority,
                    child: Text(priority.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedPriority = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Due Date display & pick
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Due Date', style: theme.textTheme.labelMedium),
                          const SizedBox(height: 4),
                          Text(
                            _selectedDueDate == null
                                ? 'Not Set (No date resolved)'
                                : _selectedDueDate!.toLocal().toString(),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: _selectedDueDate == null
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                              color: _selectedDueDate == null
                                  ? colorScheme.outline
                                  : colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: _pickDueDate,
                        icon: const Icon(Icons.calendar_month_outlined),
                        label: const Text('Change'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _submit,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check),
                    label: const Text('Confirm Task'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
