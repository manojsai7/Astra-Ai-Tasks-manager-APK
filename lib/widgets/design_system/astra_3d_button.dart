import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';

/// A physical tactile button used for primary and secondary actions across ASTRA.
/// Features stacked depth layers, physical surface sinking on press, and tactile haptic feedback.
class Astra3DButton extends StatefulWidget {
  const Astra3DButton({
    super.key,
    this.label,
    this.child,
    this.onPressed,
    this.onTap,
    this.icon,
    this.expand = false,
    this.width,
    this.height = 56,
    this.depth = AstraDepth.medium,
    this.color = AstraColors.lime,
    this.depthColor,
    this.foregroundColor,
    this.textColor,
    this.borderRadius = 16.0,
  });

  final String? label;
  final Widget? child;
  final VoidCallback? onPressed;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool expand;
  final double? width;
  final double height;
  final double depth;
  final Color color;
  final Color? depthColor;
  final Color? foregroundColor;
  final Color? textColor;
  final double borderRadius;

  @override
  State<Astra3DButton> createState() => _Astra3DButtonState();
}

class _Astra3DButtonState extends State<Astra3DButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final action = widget.onPressed ?? widget.onTap;
    final enabled = action != null;
    final fgColor = widget.textColor ?? widget.foregroundColor ?? (widget.color == AstraColors.lime ? Colors.black : AstraColors.textPrimary);
    final effectiveDepthColor = widget.depthColor ?? widget.color.withValues(alpha: .55);

    final Widget content = widget.child ??
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, color: fgColor, size: 18),
              const SizedBox(width: 8),
            ],
            if (widget.label != null)
              Text(
                widget.label!.toUpperCase(),
                style: AstraText.label(color: fgColor, size: 11),
              ),
          ],
        );

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _pressed = false);
              HapticFeedback.lightImpact();
              action();
            }
          : null,
      child: SizedBox(
        width: widget.expand ? double.infinity : widget.width,
        height: widget.height + widget.depth,
        child: Stack(
          fit: widget.expand ? StackFit.expand : StackFit.passthrough,
          children: [
            // Physical Extrusion Layer (Base)
            Positioned(
              top: widget.depth,
              left: 0,
              right: 0,
              height: widget.height,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: enabled ? effectiveDepthColor : AstraColors.surface0,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                ),
              ),
            ),
            // Physical Face Layer (Sinks on press)
            AnimatedPositioned(
              duration: AstraMotion.fast,
              curve: AstraMotion.pressCurve,
              top: _pressed ? widget.depth : 0,
              left: 0,
              right: 0,
              height: widget.height,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: enabled ? widget.color : AstraColors.surface2,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  border: Border.all(
                    color: enabled ? widget.color.withValues(alpha: .95) : AstraColors.borderSoft,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: IconTheme(
                    data: IconThemeData(color: fgColor),
                    child: content,
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

