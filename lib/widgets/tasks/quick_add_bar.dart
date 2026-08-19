import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/app_theme.dart';

/// Clean, keyboard-safe Quick Add bar floating above the navigation shell.
class QuickAddBar extends StatefulWidget {
  final ValueChanged<String> onAddTask;
  final VoidCallback onExpand;
  final String hintText;

  const QuickAddBar({
    super.key,
    required this.onAddTask,
    required this.onExpand,
    this.hintText = 'Add a task...',
  });

  @override
  State<QuickAddBar> createState() => _QuickAddBarState();
}

class _QuickAddBarState extends State<QuickAddBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) {
        setState(() => _hasText = has);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.lightImpact();
    widget.onAddTask(text);
    _controller.clear();
    // Keep focus so user can quickly chain tasks if desired
  }

  @override
  Widget build(BuildContext context) {
    // Premium bottom nav height clearance (nav is ~76-86px + padding)
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = bottomInset > 0;
    // When keyboard is open, place right above keyboard; when closed, float above floating bottom nav
    final bottomPadding = isKeyboardOpen ? bottomInset + 10 : 96.0;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AstraColors.surfaceElevated,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _hasText ? AstraColors.lime.withAlpha(120) : AstraColors.edgeSoft,
            width: 1.2,
          ),
          boxShadow: const [
            BoxShadow(
              color: AstraColors.depth,
              offset: Offset(0, 4),
              blurRadius: 0,
            ),
            BoxShadow(
              color: Color(0x33000000),
              offset: Offset(0, 6),
              blurRadius: 16,
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            Icon(
              LucideIcons.plusCircle,
              size: 19,
              color: _hasText ? AstraColors.lime : AstraColors.textMuted,
            ),
            const SizedBox(width: 10),

            // Text Input
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                style: const TextStyle(
                  color: AstraColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: const TextStyle(
                    color: AstraColors.textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
              ),
            ),

            // Expand button (opens full detail modal)
            IconButton(
              icon: const Icon(
                LucideIcons.slidersHorizontal,
                size: 17,
                color: AstraColors.textMuted,
              ),
              tooltip: 'Detailed task options',
              onPressed: () {
                HapticFeedback.selectionClick();
                widget.onExpand();
              },
              visualDensity: VisualDensity.compact,
            ),

            // Submit Button
            if (_hasText)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: _submit,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AstraColors.lime,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: AstraDepthColors.limeDepth,
                          offset: Offset(0, 2),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: const Icon(
                      LucideIcons.arrowUp,
                      size: 18,
                      color: Colors.black,
                    ),
                  ),
                ),
              )
            else
              const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }
}
