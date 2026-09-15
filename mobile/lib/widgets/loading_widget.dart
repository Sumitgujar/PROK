
import "package:flutter/material.dart";

class LoadingWidget extends StatelessWidget {
  final String? message;
  const LoadingWidget({super.key, this.message});
  @override Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const CircularProgressIndicator(color: Color(0xFF1E3A8A)),
      if (message != null) ...[
        const SizedBox(height: 12),
        Text(message!, style: const TextStyle(color: Colors.grey)),
      ],
    ]));
}
