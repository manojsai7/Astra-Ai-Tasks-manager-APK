import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';

/// The single physical-material primitive used across all ASTRA 3D components.
///
/// Renders two opaque layers:
///   - A fixed depth/extrusion layer (always [depthOffset]px below the face)
///   - An animated face layer that sinks into the extrusion on press
///
/// Animation spec:
///   Press:   face moves down [depthOffset]px — 110ms easeOutCubic + light haptic
///   Release: spring back — 160ms easeOutCubic
///
/// Composition hierarchy:
///   Astra3DButton     → Astra3DSurface
///   AstraFilterPill   → Astra3DSurface
///   Astra3DIconButton → Astra3DSurface
///   AstraMessageBubble→ Astra3DSurface (non-interactive, enabled: false)
class Astra3DSurface extends StatefulWidget {
  const Astra3DSurface({
    super.key,
    required this.child,
    this.faceColor = AstraDepthColors.neutralFace,
    this.depthColor = AstraDepthColors.neutralDepth,
    this.borderColor = AstraDepthColors.neutralBorder,
    this.depthOffset = AstraDepth.medium,
    this.borderRadius = AstraRadii.md,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
    this.hapticOnPress = true,
  });

  final Widget child;
  final Color faceColor;
  final Color depthColor;
  final Color borderColor;

  /// Physical depth of the extrusion in logical pixels. 0 = flat.
  final double depthOffset;
  final double borderRadius;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// When false the surface renders as a disabled charcoal slab with no press.
  final bool enabled;

  /// Whether to emit a light haptic impulse on press-down.
  final bool hapticOnPress;

  @override
  State<Astra3DSurface> createState() => _Astra3DSurfaceState();
}

class _Astra3DSurfaceState extends State<Astra3DSurface> {
  bool _pressed = false;

  bool get _hasAction => widget.enabled && widget.onTap != null;

  void _setPressed(bool value) {
    if (!mounted || _pressed == value) return;
    setState(() => _pressed = value);
  }

  void _handleTapDown(TapDownDetails _) {
    if (!_hasAction) return;
    _setPressed(true);
    if (widget.hapticOnPress) HapticFeedback.lightImpact();
  }

  void _handleTapUp(TapUpDetails _) {
    if (!_hasAction) return;
    _setPressed(false);
    widget.onTap?.call();
  }

  void _handleTapCancel() => _setPressed(false);

  @override
  Widget build(BuildContext context) {
    final effectiveDepth = widget.enabled ? widget.depthOffset : 0.0;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onLongPress: widget.enabled ? widget.onLongPress : null,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        // Bottom padding reserves space for the extrusion layer
        padding: EdgeInsets.only(bottom: effectiveDepth),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ── Extrusion / depth layer ────────────────────────────────
            Positioned(
              left: 0,
              right: 0,
              top: effectiveDepth,
              bottom: -effectiveDepth,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: widget.enabled
                      ? widget.depthColor
                      : AstraColors.surface0,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                ),
              ),
            ),

            // ── Face layer (sinks on press, springs back on release) ────
            AnimatedContainer(
              duration: _pressed
                  ? AstraMotion.fast               // 110ms sink
                  : const Duration(milliseconds: 160), // spring return
              curve: AstraMotion.pressCurve,
              transform: Matrix4.translationValues(
                0,
                _pressed ? effectiveDepth : 0.0,
                0,
              ),
              decoration: BoxDecoration(
                color: widget.enabled
                    ? widget.faceColor
                    : AstraColors.surface2,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: Border.all(
                  color: widget.enabled
                      ? widget.borderColor
                      : AstraColors.borderSoft,
                  width: 1.0,
                ),
              ),
              child: widget.child,
            ),
          ],
        ),
      ),
    );
  }
}
