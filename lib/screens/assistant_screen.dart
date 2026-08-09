import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import '../core/motion.dart';

class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _controller.clear();
    });

    _processCommand(text);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _processCommand(String text) {
    final response = _parseCommand(text);

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          _messages.add({'role': 'assistant', 'content': response});
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
  }

  String _parseCommand(String text) {
    final lower = text.toLowerCase();

    if (lower.contains('remind me') || lower.contains('create task') || lower.contains('add task')) {
      String title = text;
      title = title.replaceAll(RegExp(r'remind me to|create task|add task|please', caseSensitive: false), '').trim();

      String priority = 'medium';
      if (lower.contains('urgent') || lower.contains('high') || lower.contains('important')) {
        priority = 'high';
      } else if (lower.contains('low') || lower.contains('later')) {
        priority = 'low';
      }

      final task = Task(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title.isNotEmpty ? title : 'Untitled Task',
        description: text,
        priority: priority,
        createdAt: DateTime.now(),
      );
      ref.read(taskNotifierProvider.notifier).addTask(task);
      ref.invalidate(taskListProvider);

      return 'Task created: "${task.title}"\nPriority: ${priority.toUpperCase()}\nAdded to your Tasks Arena.';
    }

    if (lower.contains('complete') || lower.contains('done') || lower.contains('finished')) {
      final tasksNotifier = ref.read(taskNotifierProvider);
      final tasksFuture = ref.read(taskListProvider).asData?.value ?? [];
      final tasks = tasksNotifier.isNotEmpty ? tasksNotifier : tasksFuture;
      final incomplete = tasks.where((t) => !t.isCompleted).toList();

      if (incomplete.isNotEmpty) {
        final task = incomplete.first;
        ref.read(taskNotifierProvider.notifier).toggleComplete(task.id);
        ref.invalidate(taskListProvider);
        return 'Completed: "${task.title}"\nGreat progress!';
      } else {
        return 'All tasks completed! Nothing to mark done.';
      }
    }

    if (lower.contains('list') || lower.contains('show') || lower.contains('what')) {
      final tasksNotifier = ref.read(taskNotifierProvider);
      final tasksFuture = ref.read(taskListProvider).asData?.value ?? [];
      final tasks = tasksNotifier.isNotEmpty ? tasksNotifier : tasksFuture;
      final pending = tasks.where((t) => !t.isCompleted).toList();

      if (pending.isEmpty) {
        return 'No pending tasks. Enjoy your day!';
      }
      String list = 'Pending tasks:\n';
      for (var i = 0; i < pending.length && i < 5; i++) {
        final t = pending[i];
        list += '${i + 1}. ${t.title}';
        if (t.priority == 'high') list += ' [HIGH]';
        if (t.dueDate != null) list += ' (Due: ${t.dueDate!.toLocal().toString().split(' ')[0]})';
        list += '\n';
      }
      if (pending.length > 5) list += '... and ${pending.length - 5} more';
      return list;
    }

    return 'I can help you with:\n\n'
           '• "Remind me to [task]" → Create task\n'
           '• "Complete task" → Mark first pending as done\n'
           '• "List my tasks" → Show pending tasks\n\n'
           'Try typing a command!';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('ASTRA Assistant'),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.trash2, size: 18),
            onPressed: () {
              setState(() => _messages.clear());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.bot, size: 56, color: AppTheme.textMuted),
                        const SizedBox(height: 16),
                        Text(
                          'Chat with ASTRA',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Say "Remind me to apply for Amazon"',
                          style: TextStyle(color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ).withPremiumEntry()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (ctx, index) {
                      final msg = _messages[index];
                      final isUser = msg['role'] == 'user';
                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isUser ? AppTheme.primary : AppTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(16).copyWith(
                              bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
                              bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isUser)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8, top: 2),
                                  child: Icon(
                                    LucideIcons.bot,
                                    size: 16,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              Flexible(
                                child: Text(
                                  msg['content']!,
                                  style: TextStyle(
                                    color: isUser ? Colors.white : AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ).withPremiumEntry(),
                      );
                    },
                  ),
          ),
          // Input Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(top: BorderSide(color: AppTheme.surfaceElevated)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Ask me anything...',
                      hintStyle: const TextStyle(color: AppTheme.textMuted),
                      filled: true,
                      fillColor: AppTheme.surfaceElevated,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppTheme.primary,
                  child: IconButton(
                    icon: Icon(LucideIcons.send, color: Colors.white, size: 16),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
