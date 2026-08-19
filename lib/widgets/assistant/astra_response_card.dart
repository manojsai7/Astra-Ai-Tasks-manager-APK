import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/commands/astra_response.dart';
import '../../providers/assistant_provider.dart';
import '../../services/haptics/astra_haptics.dart';
import '../../theme/app_theme.dart';
import '../design_system/astra_3d_surface.dart';
import '../tasks/astra_task_detail_sheet.dart';

/// Renders a structured [AstraResponse] inside the existing ASTRA chat card style.
class AstraResponseCard extends ConsumerWidget {
  const AstraResponseCard({
    super.key,
    required this.response,
    required this.accent,
    required this.accentDepth,
  });

  final AstraResponse response;
  final Color accent;
  final Color accentDepth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AstraColors.surface,
        borderRadius: BorderRadius.circular(16).copyWith(bottomLeft: const Radius.circular(4)),
        border: Border.all(color: AstraColors.edgeSoft),
        boxShadow: const [
          BoxShadow(color: AstraColors.depth, offset: Offset(0, 4), blurRadius: 0),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15).copyWith(bottomLeft: const Radius.circular(3)),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [accent, accentDepth],
                    stops: const [0.6, 1.0],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            response.type == AstraResponseType.error
                                ? LucideIcons.alertTriangle
                                : response.type == AstraResponseType.taskCreated ||
                                        response.type == AstraResponseType.taskCompleted
                                    ? LucideIcons.checkCircle
                                    : Icons.auto_awesome,
                            size: 13,
                            color: accent,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              response.headline.toUpperCase(),
                              style: TextStyle(
                                color: accent,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (response.lines.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        ...response.lines.map(_lineWidget),
                      ],
                      if (response.actions.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: response.actions.map((a) {
                            final isDone = a.label.contains('DONE') || a.label.contains('COMPLETE');
                            return Astra3DSurface(
                              faceColor: isDone ? AstraDepthColors.limeFace : AstraDepthColors.neutralFace,
                              depthColor: isDone ? AstraDepthColors.limeDepth : AstraDepthColors.neutralDepth,
                              borderColor: isDone ? AstraDepthColors.limeBorder : AstraDepthColors.neutralBorder,
                              depthOffset: AstraDepth.small,
                              borderRadius: 8,
                              onTap: () {
                                AstraHaptics.light();
                                if (a.label == 'VIEW TASK' || a.id.startsWith('view_task:') || a.id.startsWith('view:')) {
                                  final tId = a.id.contains(':')
                                      ? a.id.substring(a.id.indexOf(':') + 1)
                                      : (response.data?['taskId'] as String?);
                                  if (tId != null && tId.isNotEmpty) {
                                    AstraTaskDetailSheet.show(context, taskId: tId);
                                  }
                                } else {
                                  ref.read(assistantStateProvider.notifier).handleResponseAction(a.id);
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                child: Text(
                                  a.label,
                                  style: TextStyle(
                                    color: isDone ? Colors.black : AstraColors.textPrimary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _lineWidget(AstraResponseLine line) {
    if (line.highlight) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          line.value,
          softWrap: true,
          style: const TextStyle(
            color: AstraColors.text,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        softWrap: true,
        text: TextSpan(
          style: const TextStyle(color: AstraColors.textMuted, fontSize: 13, height: 1.45),
          children: [
            if (line.label.isNotEmpty)
              TextSpan(
                text: '${line.label}: ',
                style: const TextStyle(fontWeight: FontWeight.w600, color: AstraColors.text),
              ),
            TextSpan(text: line.value),
          ],
        ),
      ),
    );
  }
}
