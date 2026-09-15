
import "package:flutter/material.dart";

class ErrorStateWidget extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;
  const ErrorStateWidget({super.key, required this.error, this.onRetry});
  @override Widget build(BuildContext context) => Center(
    child: Padding(padding: const EdgeInsets.all(32), child: Column(
      mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, size: 56, color: Colors.red),
        const SizedBox(height: 12),
        Text(error, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
        if (onRetry != null) Padding(padding: const EdgeInsets.only(top: 16),
            child: ElevatedButton.icon(onPressed: onRetry,
                icon: const Icon(Icons.refresh), label: const Text("Retry"))),
      ])));
}
