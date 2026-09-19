
import 'package:flutter/material.dart';
import 'package:prok_mobile/theme/app_theme.dart';

class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;
  const EmptyStateWidget({super.key, required this.title, this.subtitle, this.icon = Icons.inbox_outlined, this.onAction, this.actionLabel});
  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(40),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 64, height: 64,
        decoration: const BoxDecoration(color: ProkColors.neutral100, shape: BoxShape.circle),
        child: Icon(icon, size: 28, color: ProkColors.neutral400)),
      const SizedBox(height: 14),
      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ProkColors.neutral800), textAlign: TextAlign.center),
      if (subtitle != null) ...[
        const SizedBox(height: 6),
        Text(subtitle!, style: const TextStyle(fontSize: 13, color: ProkColors.neutral400), textAlign: TextAlign.center),
      ],
      if (onAction != null) ...[
        const SizedBox(height: 20),
        ElevatedButton(onPressed: onAction, child: Text(actionLabel ?? 'Get Started')),
      ],
    ]),
  ));
}
