import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../models/task.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/ritual_provider.dart';
import '../../providers/task_provider.dart';
import '../../services/assistant/astra_recurrence_engine.dart';
import '../../services/haptics/astra_haptics.dart';
import '../../theme/app_theme.dart';

/// Mode of the task detail sheet.
enum TaskDetailMode { create, edit }

/// Canonical, progressive-disclosure ASTRA Task Detail & Creation Sheet.
///
/// Designed with row-oriented selection controls, strict decoupling of date/time/recurrence,
/// and instant temporal previews.
class AstraTaskDetailSheet extends ConsumerStatefulWidget {
  final Task? task;
  final String? taskId;
  final DateTime? initialDate;
  final String? initialPriority;
  final String? initialCategory;
  final bool? initialShowMoreOptions;

  const AstraTaskDetailSheet({
    super.key,
    this.task,
    this.taskId,
    this.initialDate,
    this.initialPriority,
    this.initialCategory,
    this.initialShowMoreOptions,
  });

  bool get isEdit => task != null || taskId != null;

  /// Show canonical creation sheet
  static Future<Task?> create(
    BuildContext context, {
    DateTime? initialDate,
    String? initialPriority,
    String? initialCategory,
    bool? initialShowMoreOptions,
  }) {
    return show(
      context,
      initialDate: initialDate,
      initialPriority: initialPriority,
      initialCategory: initialCategory,
      initialShowMoreOptions: initialShowMoreOptions,
    );
  }

  /// Show canonical edit sheet
  static Future<Task?> edit(
    BuildContext context, {
    required Task task,
    bool? initialShowMoreOptions,
  }) {
    return show(
      context,
      task: task,
      initialShowMoreOptions: initialShowMoreOptions,
    );
  }

  /// Show canonical detail sheet (create or edit)
  static Future<Task?> show(
    BuildContext context, {
    Task? task,
    String? taskId,
    DateTime? initialDate,
    String? initialPriority,
    String? initialCategory,
    bool? initialShowMoreOptions,
  }) {
    return showModalBottomSheet<Task>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AstraColors.surface0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => AstraTaskDetailSheet(
        task: task,
        taskId: taskId,
        initialDate: initialDate,
        initialPriority: initialPriority,
        initialCategory: initialCategory,
        initialShowMoreOptions: initialShowMoreOptions,
      ),
    );
  }

  @override
  ConsumerState<AstraTaskDetailSheet> createState() => _AstraTaskDetailSheetState();
}

class _AstraTaskDetailSheetState extends ConsumerState<AstraTaskDetailSheet> {
  // ─── Section A: Basic ──────────────────────────────────────────────────────
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _orgController;
  late final TextEditingController _categoryController;
  late final TextEditingController _newTagController;
  late final TextEditingController _newStepController;
  late final TextEditingController _linkController;

  final List<SubTask> _steps = [];

  // Progressive disclosure toggle
  bool _showMoreOptions = false;

  // ─── Section B: Schedule (Decoupled Date & Time) ────────────────────────────
  bool _isDurationMode = false;
  DateTime? _deadlineDate;
  TimeOfDay? _deadlineTime;

  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;

  // ─── Section C: Reminder ───────────────────────────────────────────────────
  bool _reminderEnabled = true;
  int _reminderOffsetMinutes = 0; // 0 = at due/start, 10 = 10m before, etc.

  // ─── Section D: Recurrence ─────────────────────────────────────────────────
  RecurrenceFrequency _recurrenceFreq = RecurrenceFrequency.none;
  int _customInterval = 1;
  final Set<int> _selectedWeekdays = {};
  DateTime? _recurrenceStartDate;
  DateTime? _recurrenceEndDate;
  int? _occurrenceLimit;

  // ─── Section E: Importance ─────────────────────────────────────────────────
  String _priority = 'medium';
  bool _isImportant = false;

  // ─── Validation & State ───────────────────────────────────────────────────
  String? _validationError;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final t = widget.task;

    _titleController = TextEditingController(text: t?.title ?? '');
    _descController = TextEditingController(text: t?.description ?? '');
    _orgController = TextEditingController(text: t?.organization ?? '');
    _categoryController = TextEditingController(text: t?.category ?? widget.initialCategory ?? '');
    _newTagController = TextEditingController();
    _newStepController = TextEditingController();
    _linkController = TextEditingController(text: t?.sourceId ?? '');

    _priority = t?.priority ?? widget.initialPriority ?? 'medium';
    _isImportant = t?.isImportant ?? (_priority == 'high' || _priority == 'critical');
    _showMoreOptions = widget.initialShowMoreOptions ?? widget.isEdit;

    if (t != null) {
      _populateFromTask(t);
    } else if (widget.taskId != null) {
      // Async load task from DB
      Future.microtask(() async {
        try {
          final db = ref.read(databaseProvider);
          final entry = await (db.select(db.tasks)..where((tbl) => tbl.id.equals(widget.taskId!))).getSingleOrNull();
          if (entry != null && mounted) {
            final loadedTask = taskEntryToTask(entry);
            setState(() {
              _populateFromTask(loadedTask);
              _showMoreOptions = true;
            });
          }
        } catch (_) {}
      });
    } else {
      // Create mode defaults: Default Tomorrow 8:00 PM
      final initialDate = widget.initialDate ?? DateTime.now().add(const Duration(days: 1));
      _deadlineDate = initialDate;
      _deadlineTime = const TimeOfDay(hour: 20, minute: 0); // Default 8:00 PM
      _startDate = initialDate;
      _startTime = const TimeOfDay(hour: 9, minute: 0);
      _endDate = initialDate;
      _endTime = const TimeOfDay(hour: 10, minute: 0);
      _selectedWeekdays.add(initialDate.weekday);
      _reminderEnabled = true;
    }
  }

  void _populateFromTask(Task t) {
    _titleController.text = t.title;
    _descController.text = t.description ?? '';
    _orgController.text = t.organization ?? '';
    _categoryController.text = t.category ?? '';
    _linkController.text = t.sourceId ?? '';
    _priority = t.priority;
    _isImportant = t.isImportant;

    _steps.clear();
    _steps.addAll(t.subtasks);

    if (t.isDuration) {
      _isDurationMode = true;
      _startDate = t.startAt;
      _startTime = t.startAt != null ? TimeOfDay.fromDateTime(t.startAt!) : const TimeOfDay(hour: 9, minute: 0);
      _endDate = t.endAt;
      _endTime = t.endAt != null ? TimeOfDay.fromDateTime(t.endAt!) : const TimeOfDay(hour: 10, minute: 0);
    } else {
      _isDurationMode = false;
      _deadlineDate = t.dueDate;
      if (t.dueTime != null) {
        try {
          final parts = t.dueTime!.split(':');
          _deadlineTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        } catch (_) {
          _deadlineTime = t.dueDate != null ? TimeOfDay.fromDateTime(t.dueDate!) : null;
        }
      } else if (t.dueDate != null) {
        _deadlineTime = TimeOfDay.fromDateTime(t.dueDate!);
      } else {
        _deadlineTime = null;
      }
    }

    if (t.recurrenceRule != null) {
      final rule = t.recurrenceRule!;
      _recurrenceFreq = rule.frequency;
      _customInterval = rule.interval;
      _selectedWeekdays.clear();
      _selectedWeekdays.addAll(rule.byWeekdays);
      _recurrenceStartDate = rule.startDate;
      _recurrenceEndDate = rule.endDate;
      _occurrenceLimit = rule.occurrenceLimit;
      _deadlineTime ??= TimeOfDay(hour: rule.hour, minute: rule.minute);
    }

    _reminderEnabled = t.dueDate != null || t.startAt != null || t.dueTime != null || t.recurrenceRule != null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _orgController.dispose();
    _categoryController.dispose();
    _newTagController.dispose();
    _newStepController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  // ─── Schedule Helpers ──────────────────────────────────────────────────────

  DateTime? _buildEffectiveDue() {
    if (_isDurationMode || _deadlineDate == null) return null;
    final time = _deadlineTime ?? const TimeOfDay(hour: 20, minute: 0);
    return DateTime(
      _deadlineDate!.year,
      _deadlineDate!.month,
      _deadlineDate!.day,
      time.hour,
      time.minute,
    );
  }

  String? _buildEffectiveDueTimeString() {
    if (_deadlineTime == null) return null;
    final h = _deadlineTime!.hour.toString().padLeft(2, '0');
    final m = _deadlineTime!.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  DateTime? _buildEffectiveStart() {
    if (!_isDurationMode || _startDate == null) return null;
    final time = _startTime ?? const TimeOfDay(hour: 9, minute: 0);
    return DateTime(
      _startDate!.year,
      _startDate!.month,
      _startDate!.day,
      time.hour,
      time.minute,
    );
  }

  DateTime? _buildEffectiveEnd() {
    if (!_isDurationMode || _endDate == null) return null;
    final time = _endTime ?? const TimeOfDay(hour: 10, minute: 0);
    return DateTime(
      _endDate!.year,
      _endDate!.month,
      _endDate!.day,
      time.hour,
      time.minute,
    );
  }

  RecurrenceRule? _buildRecurrenceRule() {
    if (_recurrenceFreq == RecurrenceFrequency.none) return null;
    final time = _deadlineTime ?? _startTime ?? const TimeOfDay(hour: 20, minute: 0);
    return RecurrenceRule(
      frequency: _recurrenceFreq,
      interval: _customInterval.clamp(1, 99),
      byWeekdays: _recurrenceFreq == RecurrenceFrequency.weekly ? _selectedWeekdays.toList() : const [],
      startDate: _recurrenceStartDate ?? _deadlineDate,
      endDate: _recurrenceEndDate,
      occurrenceLimit: _occurrenceLimit,
      hour: time.hour,
      minute: time.minute,
    );
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatWhenSummary() {
    if (_isDurationMode && _startDate != null && _endDate != null) {
      final startFmt = DateFormat('MMM d').format(_startDate!);
      final endFmt = DateFormat('MMM d').format(_endDate!);
      final days = _endDate!.difference(_startDate!).inDays + 1;
      return '$startFmt – $endFmt · $days Days';
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    String dateStr;
    if (_deadlineDate == null) {
      dateStr = 'No date';
    } else if (_isSameDay(_deadlineDate, today)) {
      dateStr = 'Today';
    } else if (_isSameDay(_deadlineDate, tomorrow)) {
      dateStr = 'Tomorrow';
    } else {
      dateStr = DateFormat('EEE, MMM d').format(_deadlineDate!);
    }

    if (_deadlineTime != null) {
      final timeStr = _deadlineTime!.format(context);
      return '$dateStr · $timeStr';
    } else {
      return dateStr;
    }
  }

  String _formatRepeatSummary() {
    if (_recurrenceFreq == RecurrenceFrequency.none) return 'Never';
    String freqStr;
    switch (_recurrenceFreq) {
      case RecurrenceFrequency.daily:
        freqStr = 'Every day';
        break;
      case RecurrenceFrequency.weekdays:
        freqStr = 'Every weekday';
        break;
      case RecurrenceFrequency.weekly:
        if (_selectedWeekdays.isEmpty) {
          freqStr = 'Every week';
        } else {
          const dayNames = {1: 'Mon', 2: 'Tue', 3: 'Wed', 4: 'Thu', 5: 'Fri', 6: 'Sat', 7: 'Sun'};
          final days = _selectedWeekdays.map((d) => dayNames[d] ?? '').where((s) => s.isNotEmpty).join(', ');
          freqStr = 'Every $days';
        }
        break;
      case RecurrenceFrequency.monthly:
        final dayNum = _deadlineDate?.day ?? 1;
        freqStr = 'Monthly on day $dayNum';
        break;
      case RecurrenceFrequency.yearly:
        freqStr = 'Yearly';
        break;
      case RecurrenceFrequency.custom:
        freqStr = 'Every $_customInterval ${_customInterval == 1 ? "interval" : "intervals"}';
        break;
      default:
        freqStr = 'Repeats';
    }

    if (_recurrenceEndDate != null) {
      final endStr = DateFormat('MMM d').format(_recurrenceEndDate!);
      return '$freqStr · until $endStr';
    }
    return freqStr;
  }

  String _formatRemindSummary() {
    if (!_reminderEnabled) return 'Off';
    if (_reminderOffsetMinutes == 0) return 'At due time';
    if (_reminderOffsetMinutes == 5) return '5 min before';
    if (_reminderOffsetMinutes == 10) return '10 min before';
    if (_reminderOffsetMinutes == 15) return '15 min before';
    if (_reminderOffsetMinutes == 30) return '30 min before';
    if (_reminderOffsetMinutes == 60) return '1 hour before';
    if (_reminderOffsetMinutes == 1440) return '1 day before';
    return '$_reminderOffsetMinutes min before';
  }

  String _formatPrioritySummary() {
    switch (_priority) {
      case 'low':
        return 'Low';
      case 'high':
        return 'High';
      case 'critical':
        return 'Urgent';
      default:
        return 'Medium';
    }
  }

  // ─── Step / Subtask Operations ─────────────────────────────────────────────

  void _addStep() {
    final name = _newStepController.text.trim();
    if (name.isEmpty) return;
    AstraHaptics.light();
    setState(() {
      _steps.add(SubTask.create(name));
      _newStepController.clear();
    });
  }

  void _toggleStep(int index) {
    AstraHaptics.selection();
    setState(() {
      final s = _steps[index];
      _steps[index] = s.copyWith(isCompleted: !s.isCompleted);
    });
  }

  void _deleteStep(int index) {
    AstraHaptics.light();
    setState(() {
      _steps.removeAt(index);
    });
  }

  // ─── Validation & Submission ───────────────────────────────────────────────

  bool _validate() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _validationError = 'Please enter a task title');
      AstraHaptics.warning();
      return false;
    }
    if (title.length < 2 && RegExp(r'^[\W_]+$').hasMatch(title)) {
      setState(() => _validationError = 'Please enter a meaningful task title');
      AstraHaptics.warning();
      return false;
    }

    if (_isDurationMode) {
      final start = _buildEffectiveStart();
      final end = _buildEffectiveEnd();
      if (start == null || end == null) {
        setState(() => _validationError = 'Please set both start and end time');
        AstraHaptics.warning();
        return false;
      }
      if (end.isBefore(start)) {
        setState(() => _validationError = 'End time cannot be earlier than start time');
        AstraHaptics.warning();
        return false;
      }
    }

    setState(() => _validationError = null);
    return true;
  }

  Future<void> _save() async {
    if (!_validate()) return;

    setState(() => _isSubmitting = true);
    AstraHaptics.medium();

    try {
      final title = _titleController.text.trim();
      final desc = _descController.text.trim().isEmpty ? null : _descController.text.trim();
      final org = _orgController.text.trim().isEmpty ? null : _orgController.text.trim();
      final cat = _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim();
      final link = _linkController.text.trim().isEmpty ? null : _linkController.text.trim();

      final due = _buildEffectiveDue();
      final dueTimeStr = _buildEffectiveDueTimeString();
      final startAt = _buildEffectiveStart();
      final endAt = _buildEffectiveEnd();
      final recurrence = _buildRecurrenceRule();

      final effectivePriority = _isImportant ? 'high' : _priority;

      if (widget.isEdit) {
        // ─── UPDATE FLOW ────────────────────────────────────────────────────
        final original = widget.task!;
        final updatedTask = original.copyWith(
          title: title,
          description: desc,
          organization: org,
          category: cat,
          sourceId: link ?? original.sourceId,
          dueDate: _isDurationMode ? null : due,
          dueTime: _isDurationMode ? null : dueTimeStr,
          startAt: startAt,
          endAt: endAt,
          recurrenceRule: recurrence,
          priority: effectivePriority,
          subtasks: _steps,
          updatedAt: DateTime.now(),
        );

        // 1. Update Drift SQLite via TaskNotifier
        await ref.read(taskNotifierProvider.notifier).updateTask(updatedTask);
        ref.invalidate(taskListProvider);

        // 2. Manage single active reminder invariant
        final reminderService = ref.read(reminderServiceProvider);
        await reminderService.cancelReminderForTask(updatedTask.id);

        if (_reminderEnabled) {
          final targetTime = updatedTask.effectiveTargetDate ?? updatedTask.dueDate;
          if (targetTime != null && targetTime.isAfter(DateTime.now())) {
            final scheduledAt = targetTime.subtract(Duration(minutes: _reminderOffsetMinutes));
            await reminderService.scheduleReminder(
              taskId: updatedTask.id,
              taskTitle: updatedTask.title,
              scheduledAt: scheduledAt.isBefore(DateTime.now()) ? DateTime.now().add(const Duration(seconds: 10)) : scheduledAt,
            );
          }
        }

        AstraHaptics.success();
        if (mounted) {
          Navigator.of(context).pop(updatedTask);
        }
      } else {
        // ─── CREATE FLOW (Task -> TaskNotifier + ReminderService) ────────────
        final taskId = DateTime.now().millisecondsSinceEpoch.toString();
        final newTask = Task(
          id: taskId,
          title: title,
          description: desc,
          organization: org,
          category: cat,
          dueDate: _isDurationMode ? null : due,
          dueTime: _isDurationMode ? null : dueTimeStr,
          startAt: startAt,
          endAt: endAt,
          recurrenceRule: recurrence,
          priority: effectivePriority,
          subtasks: _steps,
          source: 'manual',
          sourceId: link,
          status: due != null || startAt != null || dueTimeStr != null || recurrence != null
              ? 'active'
              : 'pending',
          createdAt: DateTime.now(),
        );

        await ref.read(taskNotifierProvider.notifier).addTask(newTask);
        ref.invalidate(taskListProvider);

        if (_reminderEnabled) {
          final targetTime = newTask.effectiveTargetDate ?? newTask.dueDate;
          if (targetTime != null && targetTime.isAfter(DateTime.now())) {
            final scheduledAt = targetTime.subtract(Duration(minutes: _reminderOffsetMinutes));
            await ref.read(reminderServiceProvider).scheduleReminder(
              taskId: newTask.id,
              taskTitle: newTask.title,
              scheduledAt: scheduledAt.isBefore(DateTime.now()) ? DateTime.now().add(const Duration(seconds: 10)) : scheduledAt,
            );
          }
        }

        AstraHaptics.success();
        if (mounted) {
          Navigator.of(context).pop(newTask);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _validationError = 'Failed to save task: $e';
          _isSubmitting = false;
        });
      }
    }
  }

  // ─── Modal Row Pickers ─────────────────────────────────────────────────────

  void _showWhenPickerSheet() {
    AstraHaptics.selection();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AstraColors.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final tomorrow = today.add(const Duration(days: 1));

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AstraColors.surface3,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'SCHEDULE TYPE',
                    style: TextStyle(
                      color: AstraColors.cyan,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildModalChip('TASK (DEADLINE)', !_isDurationMode, () {
                        setModalState(() => _isDurationMode = false);
                        setState(() => _isDurationMode = false);
                      }),
                      _buildModalChip('EVENT (START/END)', _isDurationMode, () {
                        setModalState(() {
                          _isDurationMode = true;
                          _startDate ??= DateTime.now();
                          _endDate ??= DateTime.now();
                        });
                        setState(() {
                          _isDurationMode = true;
                          _startDate ??= DateTime.now();
                          _endDate ??= DateTime.now();
                        });
                      }),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_isDurationMode) ...[
                    const Text(
                      'START DATE',
                      style: TextStyle(
                        color: AstraColors.cyan,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildModalChip('Today', _isSameDay(_startDate, today), () {
                          setModalState(() => _startDate = today);
                          setState(() => _startDate = today);
                        }),
                        _buildModalChip('Tomorrow', _isSameDay(_startDate, tomorrow), () {
                          setModalState(() => _startDate = tomorrow);
                          setState(() => _startDate = tomorrow);
                        }),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'END DATE',
                      style: TextStyle(
                        color: AstraColors.cyan,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildModalChip('Today', _isSameDay(_endDate, today), () {
                          setModalState(() => _endDate = today);
                          setState(() => _endDate = today);
                        }),
                        _buildModalChip('Tomorrow', _isSameDay(_endDate, tomorrow), () {
                          setModalState(() => _endDate = tomorrow);
                          setState(() => _endDate = tomorrow);
                        }),
                      ],
                    ),
                  ] else ...[
                    const Text(
                      'DATE ANCHOR',
                      style: TextStyle(
                        color: AstraColors.cyan,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildModalChip('Today', _isSameDay(_deadlineDate, today), () {
                          setModalState(() => _deadlineDate = today);
                          setState(() => _deadlineDate = today);
                        }),
                        _buildModalChip('Tomorrow', _isSameDay(_deadlineDate, tomorrow), () {
                          setModalState(() => _deadlineDate = tomorrow);
                          setState(() => _deadlineDate = tomorrow);
                        }),
                        _buildModalChip('Pick date', _deadlineDate != null && !_isSameDay(_deadlineDate, today) && !_isSameDay(_deadlineDate, tomorrow), () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _deadlineDate ?? tomorrow,
                            firstDate: DateTime(now.year - 1),
                            lastDate: DateTime(now.year + 5),
                            builder: (context, child) => Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: AstraColors.cyan,
                                  onPrimary: Colors.black,
                                  surface: AstraColors.surface1,
                                  onSurface: AstraColors.textPrimary,
                                ),
                              ),
                              child: child!,
                            ),
                          );
                          if (picked != null) {
                            setModalState(() => _deadlineDate = picked);
                            setState(() => _deadlineDate = picked);
                          }
                        }),
                        _buildModalChip('No date', _deadlineDate == null, () {
                          setModalState(() => _deadlineDate = null);
                          setState(() => _deadlineDate = null);
                        }),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  const Text(
                    'TIME OF DAY',
                    style: TextStyle(
                      color: AstraColors.cyan,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildModalChip('None', _deadlineTime == null, () {
                        setModalState(() => _deadlineTime = null);
                        setState(() => _deadlineTime = null);
                      }),
                      _buildModalChip('9:00 AM', _deadlineTime?.hour == 9 && _deadlineTime?.minute == 0, () {
                        const t = TimeOfDay(hour: 9, minute: 0);
                        setModalState(() => _deadlineTime = t);
                        setState(() => _deadlineTime = t);
                      }),
                      _buildModalChip('1:00 PM', _deadlineTime?.hour == 13 && _deadlineTime?.minute == 0, () {
                        const t = TimeOfDay(hour: 13, minute: 0);
                        setModalState(() => _deadlineTime = t);
                        setState(() => _deadlineTime = t);
                      }),
                      _buildModalChip('5:00 PM', _deadlineTime?.hour == 17 && _deadlineTime?.minute == 0, () {
                        const t = TimeOfDay(hour: 17, minute: 0);
                        setModalState(() => _deadlineTime = t);
                        setState(() => _deadlineTime = t);
                      }),
                      _buildModalChip('8:00 PM', _deadlineTime?.hour == 20 && _deadlineTime?.minute == 0, () {
                        const t = TimeOfDay(hour: 20, minute: 0);
                        setModalState(() => _deadlineTime = t);
                        setState(() => _deadlineTime = t);
                      }),
                      _buildModalChip('Custom time', _deadlineTime != null && !{9, 13, 17, 20}.contains(_deadlineTime!.hour), () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _deadlineTime ?? const TimeOfDay(hour: 20, minute: 0),
                          builder: (context, child) => Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: AstraColors.cyan,
                                onPrimary: Colors.black,
                                surface: AstraColors.surface1,
                                onSurface: AstraColors.textPrimary,
                              ),
                            ),
                            child: child!,
                          ),
                        );
                        if (picked != null) {
                          setModalState(() => _deadlineTime = picked);
                          setState(() => _deadlineTime = picked);
                        }
                      }),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AstraColors.surface2,
                        foregroundColor: AstraColors.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('DONE', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showRepeatPickerSheet() {
    AstraHaptics.selection();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AstraColors.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final now = DateTime.now();

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AstraColors.surface3,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'RECURRENCE FREQUENCY',
                    style: TextStyle(
                      color: AstraColors.cyan,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildModalChip('Never', _recurrenceFreq == RecurrenceFrequency.none, () {
                        setModalState(() => _recurrenceFreq = RecurrenceFrequency.none);
                        setState(() => _recurrenceFreq = RecurrenceFrequency.none);
                      }),
                      _buildModalChip('Daily', _recurrenceFreq == RecurrenceFrequency.daily, () {
                        setModalState(() => _recurrenceFreq = RecurrenceFrequency.daily);
                        setState(() => _recurrenceFreq = RecurrenceFrequency.daily);
                      }),
                      _buildModalChip('Weekdays (Mon-Fri)', _recurrenceFreq == RecurrenceFrequency.weekdays, () {
                        setModalState(() => _recurrenceFreq = RecurrenceFrequency.weekdays);
                        setState(() => _recurrenceFreq = RecurrenceFrequency.weekdays);
                      }),
                      _buildModalChip('Weekly', _recurrenceFreq == RecurrenceFrequency.weekly, () {
                        setModalState(() {
                          _recurrenceFreq = RecurrenceFrequency.weekly;
                          if (_selectedWeekdays.isEmpty) {
                            _selectedWeekdays.add(_deadlineDate?.weekday ?? DateTime.now().weekday);
                          }
                        });
                        setState(() {
                          _recurrenceFreq = RecurrenceFrequency.weekly;
                          if (_selectedWeekdays.isEmpty) {
                            _selectedWeekdays.add(_deadlineDate?.weekday ?? DateTime.now().weekday);
                          }
                        });
                      }),
                      _buildModalChip('Monthly', _recurrenceFreq == RecurrenceFrequency.monthly, () {
                        setModalState(() => _recurrenceFreq = RecurrenceFrequency.monthly);
                        setState(() => _recurrenceFreq = RecurrenceFrequency.monthly);
                      }),
                      _buildModalChip('Yearly', _recurrenceFreq == RecurrenceFrequency.yearly, () {
                        setModalState(() => _recurrenceFreq = RecurrenceFrequency.yearly);
                        setState(() => _recurrenceFreq = RecurrenceFrequency.yearly);
                      }),
                    ],
                  ),

                  // Weekly Days Selector
                  if (_recurrenceFreq == RecurrenceFrequency.weekly) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'REPEAT ON',
                      style: TextStyle(
                        color: AstraColors.cyan,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (int i = 1; i <= 7; i++)
                          _buildWeekdayButton(i, setModalState),
                      ],
                    ),
                  ],

                  // Start & End Window
                  if (_recurrenceFreq != RecurrenceFrequency.none) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'START & END DURATION (OPTIONAL)',
                      style: TextStyle(
                        color: AstraColors.cyan,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _recurrenceStartDate ?? _deadlineDate ?? now,
                                firstDate: DateTime(now.year - 1),
                                lastDate: DateTime(now.year + 5),
                              );
                              if (picked != null) {
                                setModalState(() => _recurrenceStartDate = picked);
                                setState(() => _recurrenceStartDate = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: AstraColors.surface2,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _recurrenceStartDate != null
                                    ? 'From: ${DateFormat("d MMM yyyy").format(_recurrenceStartDate!)}'
                                    : 'From: Default',
                                style: const TextStyle(fontSize: 12, color: AstraColors.textPrimary),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _recurrenceEndDate ?? now.add(const Duration(days: 30)),
                                firstDate: now,
                                lastDate: DateTime(now.year + 5),
                              );
                              if (picked != null) {
                                setModalState(() => _recurrenceEndDate = picked);
                                setState(() => _recurrenceEndDate = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: AstraColors.surface2,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _recurrenceEndDate != null
                                    ? 'Until: ${DateFormat("d MMM yyyy").format(_recurrenceEndDate!)}'
                                    : 'Until: Forever',
                                style: const TextStyle(fontSize: 12, color: AstraColors.textPrimary),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AstraColors.surface2,
                        foregroundColor: AstraColors.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('DONE', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWeekdayButton(int weekday, StateSetter setModalState) {
    const dayLetters = {1: 'M', 2: 'T', 3: 'W', 4: 'T', 5: 'F', 6: 'S', 7: 'S'};
    final isSelected = _selectedWeekdays.contains(weekday);
    return InkWell(
      onTap: () {
        AstraHaptics.selection();
        setModalState(() {
          if (isSelected && _selectedWeekdays.length > 1) {
            _selectedWeekdays.remove(weekday);
          } else {
            _selectedWeekdays.add(weekday);
          }
        });
        setState(() {});
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AstraColors.cyan : AstraColors.surface2,
          shape: BoxShape.circle,
        ),
        child: Text(
          dayLetters[weekday] ?? '',
          style: TextStyle(
            color: isSelected ? Colors.black : AstraColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  void _showRemindPickerSheet() {
    AstraHaptics.selection();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AstraColors.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AstraColors.surface3,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'NOTIFICATION TIMING',
                    style: TextStyle(
                      color: AstraColors.cyan,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildModalChip('At due time', _reminderEnabled && _reminderOffsetMinutes == 0, () {
                        setModalState(() {
                          _reminderEnabled = true;
                          _reminderOffsetMinutes = 0;
                        });
                        setState(() {
                          _reminderEnabled = true;
                          _reminderOffsetMinutes = 0;
                        });
                      }),
                      _buildModalChip('5 min before', _reminderEnabled && _reminderOffsetMinutes == 5, () {
                        setModalState(() {
                          _reminderEnabled = true;
                          _reminderOffsetMinutes = 5;
                        });
                        setState(() {
                          _reminderEnabled = true;
                          _reminderOffsetMinutes = 5;
                        });
                      }),
                      _buildModalChip('15 min before', _reminderEnabled && _reminderOffsetMinutes == 15, () {
                        setModalState(() {
                          _reminderEnabled = true;
                          _reminderOffsetMinutes = 15;
                        });
                        setState(() {
                          _reminderEnabled = true;
                          _reminderOffsetMinutes = 15;
                        });
                      }),
                      _buildModalChip('1 hour before', _reminderEnabled && _reminderOffsetMinutes == 60, () {
                        setModalState(() {
                          _reminderEnabled = true;
                          _reminderOffsetMinutes = 60;
                        });
                        setState(() {
                          _reminderEnabled = true;
                          _reminderOffsetMinutes = 60;
                        });
                      }),
                      _buildModalChip('1 day before', _reminderEnabled && _reminderOffsetMinutes == 1440, () {
                        setModalState(() {
                          _reminderEnabled = true;
                          _reminderOffsetMinutes = 1440;
                        });
                        setState(() {
                          _reminderEnabled = true;
                          _reminderOffsetMinutes = 1440;
                        });
                      }),
                      _buildModalChip('Off', !_reminderEnabled, () {
                        setModalState(() => _reminderEnabled = false);
                        setState(() => _reminderEnabled = false);
                      }),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AstraColors.surface2,
                        foregroundColor: AstraColors.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('DONE', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showPriorityPickerSheet() {
    AstraHaptics.selection();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AstraColors.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AstraColors.surface3,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'PRIORITY LEVEL',
                    style: TextStyle(
                      color: AstraColors.cyan,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildModalChip('Low', _priority == 'low', () {
                        setModalState(() => _priority = 'low');
                        setState(() => _priority = 'low');
                      }),
                      _buildModalChip('Medium', _priority == 'medium', () {
                        setModalState(() => _priority = 'medium');
                        setState(() => _priority = 'medium');
                      }),
                      _buildModalChip('High', _priority == 'high', () {
                        setModalState(() => _priority = 'high');
                        setState(() => _priority = 'high');
                      }),
                      _buildModalChip('Urgent', _priority == 'critical', () {
                        setModalState(() => _priority = 'critical');
                        setState(() => _priority = 'critical');
                      }),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AstraColors.surface2,
                        foregroundColor: AstraColors.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('DONE', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModalChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        AstraHaptics.selection();
        onTap();
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AstraColors.cyan : AstraColors.surface2,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : AstraColors.textPrimary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ─── Row Widget Builder ────────────────────────────────────────────────────

  Widget _buildSettingRow({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    Color? valueColor,
    Widget? trailing,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          AstraHaptics.selection();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AstraColors.surface1,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AstraColors.borderSubtle),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AstraColors.textSecondary),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  color: AstraColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(width: 12),
              if (trailing != null)
                trailing
              else
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          value,
                          style: TextStyle(
                            color: valueColor ?? AstraColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(LucideIcons.chevronRight, size: 16, color: AstraColors.textSecondary),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Build UI ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isEdit = widget.isEdit;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AstraColors.surface0,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AstraColors.surface2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Top Header Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 20, color: AstraColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Close',
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isEdit ? 'TASK DETAILS' : 'NEW TASK',
                      style: const TextStyle(
                        color: AstraColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Save / Create Button
                  ElevatedButton(
                    key: const Key('task_detail_save_button'),
                    onPressed: _isSubmitting ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AstraColors.lime,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : Text(
                            isEdit ? 'SAVE' : 'CREATE',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                  ),
                ],
              ),
            ),

            const Divider(color: AstraColors.borderSubtle, height: 1),

            // Main Scrollable Form Body
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: bottomInset + 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Validation Warning Banner
                    if (_validationError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0x26EF4444),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0x66EF4444)),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.alertCircle, size: 16, color: Color(0xFFEF4444)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _validationError!,
                                style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Title input field
                    TextField(
                      key: const Key('task_detail_title_field'),
                      controller: _titleController,
                      autofocus: !isEdit,
                      style: const TextStyle(
                        color: AstraColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        hintText: 'What needs to be done?',
                        hintStyle: const TextStyle(
                          color: AstraColors.textSecondary,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                        filled: true,
                        fillColor: AstraColors.surface1,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AstraColors.borderSubtle),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AstraColors.borderSubtle),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AstraColors.cyan, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      onChanged: (_) {
                        if (_validationError != null) setState(() => _validationError = null);
                      },
                    ),
                    const SizedBox(height: 14),

                    // ─── ROW-BASED CORE CONTROLS ─────────────────────────────
                    // 1. WHEN Row
                    _buildSettingRow(
                      icon: LucideIcons.calendar,
                      label: 'WHEN',
                      value: _formatWhenSummary(),
                      onTap: _showWhenPickerSheet,
                    ),
                    const SizedBox(height: 8),

                    // 2. REPEAT Row
                    _buildSettingRow(
                      icon: LucideIcons.repeat,
                      label: 'REPEAT',
                      value: _formatRepeatSummary(),
                      onTap: _showRepeatPickerSheet,
                    ),
                    const SizedBox(height: 8),

                    // 3. REMIND Row
                    _buildSettingRow(
                      icon: LucideIcons.bell,
                      label: 'REMIND',
                      value: _formatRemindSummary(),
                      onTap: _showRemindPickerSheet,
                    ),
                    const SizedBox(height: 8),

                    // 4. PRIORITY Row
                    _buildSettingRow(
                      icon: LucideIcons.flag,
                      label: 'PRIORITY',
                      value: _formatPrioritySummary(),
                      onTap: _showPriorityPickerSheet,
                    ),
                    const SizedBox(height: 16),

                    // ─── PROGRESSIVE DISCLOSURE TOGGLE ───────────────────────
                    Center(
                      child: TextButton.icon(
                        onPressed: () {
                          AstraHaptics.selection();
                          setState(() => _showMoreOptions = !_showMoreOptions);
                        },
                        icon: Icon(
                          _showMoreOptions ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                          size: 16,
                          color: AstraColors.cyan,
                        ),
                        label: Text(
                          _showMoreOptions ? 'FEWER DETAILS' : 'MORE DETAILS',
                          style: const TextStyle(
                            color: AstraColors.cyan,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),

                    // ─── STAGE 2: SECONDARY DETAILS (Progressive Disclosure) ─
                    if (_showMoreOptions) ...[
                      const SizedBox(height: 12),

                      // Description / Notes
                      const Text(
                        'NOTES & DESCRIPTION',
                        style: TextStyle(
                          color: AstraColors.cyan,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        key: const Key('task_detail_desc_field'),
                        controller: _descController,
                        maxLines: 3,
                        style: const TextStyle(color: AstraColors.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Add extra details, instructions, or context...',
                          hintStyle: const TextStyle(color: AstraColors.textSecondary, fontSize: 14),
                          filled: true,
                          fillColor: AstraColors.surface1,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AstraColors.borderSubtle),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AstraColors.borderSubtle),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AstraColors.cyan),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Checklist / Steps
                      const Text(
                        'CHECKLIST & STEPS',
                        style: TextStyle(
                          color: AstraColors.cyan,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),

                      if (_steps.isNotEmpty)
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _steps.length,
                          itemBuilder: (context, index) {
                            final step = _steps[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AstraColors.surface1,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AstraColors.borderSubtle),
                              ),
                              child: Row(
                                children: [
                                  InkWell(
                                    onTap: () => _toggleStep(index),
                                    child: Icon(
                                      step.isCompleted ? LucideIcons.checkCircle : LucideIcons.circle,
                                      size: 18,
                                      color: step.isCompleted ? AstraColors.lime : AstraColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      step.name,
                                      style: TextStyle(
                                        color: step.isCompleted ? AstraColors.textSecondary : AstraColors.textPrimary,
                                        fontSize: 13,
                                        decoration: step.isCompleted ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(LucideIcons.trash2, size: 16, color: AstraColors.red),
                                    onPressed: () => _deleteStep(index),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              key: const Key('task_detail_add_step_field'),
                              controller: _newStepController,
                              style: const TextStyle(color: AstraColors.textPrimary, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Add a subtask step...',
                                hintStyle: const TextStyle(color: AstraColors.textSecondary, fontSize: 13),
                                filled: true,
                                fillColor: AstraColors.surface1,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: AstraColors.borderSubtle),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              onSubmitted: (_) => _addStep(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            key: const Key('task_detail_add_step_button'),
                            onPressed: _addStep,
                            icon: const Icon(LucideIcons.plus, size: 16),
                            style: IconButton.styleFrom(
                              backgroundColor: AstraColors.surface2,
                              foregroundColor: AstraColors.cyan,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Category & Organization
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'CATEGORY',
                                  style: TextStyle(
                                    color: AstraColors.cyan,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  key: const Key('task_detail_category_field'),
                                  controller: _categoryController,
                                  style: const TextStyle(color: AstraColors.textPrimary, fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: 'e.g. Work, Study',
                                    hintStyle: const TextStyle(color: AstraColors.textSecondary, fontSize: 13),
                                    filled: true,
                                    fillColor: AstraColors.surface1,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: AstraColors.borderSubtle),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'ORGANIZATION',
                                  style: TextStyle(
                                    color: AstraColors.cyan,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  key: const Key('task_detail_org_field'),
                                  controller: _orgController,
                                  style: const TextStyle(color: AstraColors.textPrimary, fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: 'e.g. Google, College',
                                    hintStyle: const TextStyle(color: AstraColors.textSecondary, fontSize: 13),
                                    filled: true,
                                    fillColor: AstraColors.surface1,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: AstraColors.borderSubtle),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // External Link / Source
                      const Text(
                        'LINK & SOURCE ID',
                        style: TextStyle(
                          color: AstraColors.cyan,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        key: const Key('task_detail_link_field'),
                        controller: _linkController,
                        style: const TextStyle(color: AstraColors.textPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'e.g. Calendar Event ID or URL',
                          hintStyle: const TextStyle(color: AstraColors.textSecondary, fontSize: 13),
                          filled: true,
                          fillColor: AstraColors.surface1,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AstraColors.borderSubtle),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
