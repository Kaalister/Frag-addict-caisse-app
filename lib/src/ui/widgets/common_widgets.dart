import 'package:flutter/material.dart';

import '../theme.dart';

class TacticalCard extends StatelessWidget {
  const TacticalCard({
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.borderColor,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(VisualIdentity.radius),
        border: Border.all(color: borderColor ?? AppColors.border),
      ),
      child: child,
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {this.trailing, super.key});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              text.toUpperCase(),
              softWrap: true,
              style: TextStyle(
                color: context.primaryAccent,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    required this.label,
    required this.value,
    required this.color,
    this.caption,
    super.key,
  });

  final String label;
  final String value;
  final String? caption;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TacticalCard(
      borderColor: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label.toUpperCase(),
              style: const TextStyle(
                  color: AppColors.muted, fontSize: 12, letterSpacing: 1.6)),
          const SizedBox(height: 4),
          FittedBox(
              child: Text(value,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 24))),
          if (caption != null)
            Text(caption!,
                style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        ],
      ),
    );
  }
}
