
import "package:flutter/material.dart";

class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;
  const EmptyStateWidget({super.key, required this.title, this.subtitle,
      required this.icon, this.onAction, this.actionLabel});
  @override Widget build(BuildContext context) => Center(
    child: Padding(padding: const EdgeInsets.all(32), child: Column(
      mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 64, color: Colors.grey[300]),
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey), textAlign: TextAlign.center),
        if (subtitle != null) Padding(padding: const EdgeInsets.only(top: 8),
            child: Text(subtitle!, style: const TextStyle(color: Colors.grey, fontSize: 13), textAlign: TextAlign.center)),
        if (onAction != null) Padding(padding: const EdgeInsets.only(top: 16),
            child: ElevatedButton(onPressed: onAction, child: Text(actionLabel ?? "Get Started"))),
      ])));
}
