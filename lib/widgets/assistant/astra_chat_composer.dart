import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../services/haptics/astra_haptics.dart';
import '../../theme/app_theme.dart';
import '../design_system/astra_3d_button.dart';

/// Bounded, resilient chat composer that vertically grows with input up to [maxHeight],
/// scrolls internally beyond it, and keeps the SEND/STOP button anchored and always visible.
class AstraChatComposer extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onStop;
  final bool isLoading;
  final String hintText;
  final double maxHeight;

  const AstraChatComposer({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onStop,
    this.isLoading = false,
    this.hintText = 'Ask ASTRA or type a command…',
    this.maxHeight = 140.0,
  });

  @override
  State<AstraChatComposer> createState() => _AstraChatComposerState();
}

class _AstraChatComposerState extends State<AstraChatComposer> {
  void _handleSubmit() {
    if (widget.isLoading) {
      AstraHaptics.medium();
      widget.onStop();
      return;
    }

    final text = widget.controller.text.trim();
    if (text.isEmpty) return;

    AstraHaptics.light();
    widget.onSend();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      decoration: const BoxDecoration(
        color: AstraColors.background,
        border: Border(
          top: BorderSide(color: AstraColors.edgeSoft, width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Bounded Multiline Text Field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AstraColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AstraColors.edgeSoft, width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: AstraColors.depth,
                    offset: Offset(0, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: 46.0,
                  maxHeight: widget.maxHeight,
                ),
                child: Scrollbar(
                  child: TextField(
                    controller: widget.controller,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    minLines: 1,
                    maxLines: null,
                    scrollPhysics: const BouncingScrollPhysics(),
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(
                      color: AstraColors.textPrimary,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w400,
                      height: 1.45,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      hintStyle: const TextStyle(
                        color: AstraColors.textMuted,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Fixed-width SEND / STOP Button
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: widget.controller,
            builder: (context, value, _) {
              final hasText = value.text.trim().isNotEmpty;

              if (widget.isLoading) {
                return SizedBox(
                  width: 46,
                  height: 46,
                  child: Astra3DIconButton(
                    key: const ValueKey('chat_stop_button'),
                    icon: LucideIcons.square,
                    iconSize: 16,
                    size: 46,
                    depth: AstraDepth.small,
                    faceColor: AstraColors.red,
                    depthColor: AstraDepthColors.redDepth,
                    borderColor: AstraDepthColors.redBorder,
                    iconColor: Colors.white,
                    borderRadius: AstraRadii.md,
                    onTap: _handleSubmit,
                  ),
                );
              }

              return SizedBox(
                width: 46,
                height: 46,
                child: Astra3DIconButton(
                  key: const ValueKey('chat_send_button'),
                  icon: LucideIcons.send,
                  iconSize: 18,
                  size: 46,
                  depth: AstraDepth.small,
                  faceColor: hasText ? AstraDepthColors.limeFace : AstraColors.surface2,
                  depthColor: hasText ? AstraDepthColors.limeDepth : AstraColors.surface1,
                  borderColor: hasText ? AstraDepthColors.limeBorder : AstraColors.edgeSoft,
                  iconColor: hasText ? Colors.black : AstraColors.textDisabled,
                  borderRadius: AstraRadii.md,
                  onTap: hasText ? _handleSubmit : null,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
