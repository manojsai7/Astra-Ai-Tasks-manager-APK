import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';

/// A compact physical button used for primary actions across ASTRA.
class Astra3DButton extends StatefulWidget {
  const Astra3DButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  @override
  State<Astra3DButton> createState() => _Astra3DButtonState();
}

class _Astra3DButtonState extends State<Astra3DButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _pressed = false);
              HapticFeedback.selectionClick();
              widget.onPressed!();
            }
          : null,
      child: SizedBox(
        width: widget.expand ? double.infinity : null,
        height: 52,
        child: Stack(
          fit: widget.expand ? StackFit.expand : StackFit.passthrough,
          children: [
            Positioned.fill(
              top: 4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: enabled ? AppTheme.primaryDark : AppTheme.surfaceRaised,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
              top: _pressed ? 4 : 0,
              left: 0,
              right: 0,
              height: 48,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: enabled ? AppTheme.primary : AppTheme.surfaceGlass,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: enabled ? AppTheme.primaryLight : AppTheme.borderSubtle),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: Colors.black, size: 18),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.label.toUpperCase(),
                        style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: .8),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
