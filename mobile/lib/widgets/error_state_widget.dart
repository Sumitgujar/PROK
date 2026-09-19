
import 'package:flutter/material.dart';
import 'package:prok_mobile/theme/app_theme.dart';

class ErrorStateWidget extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;
  const ErrorStateWidget({super.key, required this.error, this.onRetry});
  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.all(40),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 56, height: 56,
        decoration: const BoxDecoration(color: ProkColors.errorSurface, shape: BoxShape.circle),
        child: const Icon(Icons.error_outline_rounded, color: ProkColors.error, size: 26)),
      const SizedBox(height: 14),
      const Text('Something went wrong', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: ProkColors.neutral900)),
      const SizedBox(height: 6),
      Text(error, style: const TextStyle(fontSize: 13, color: ProkColors.neutral400), textAlign: TextAlign.center),
      if (onRetry != null) ...[
        const SizedBox(height: 20),
        SizedBox(width: 140, child: ElevatedButton(onPressed: onRetry, child: const Text('Try Again'))),
      ],
    ]),
  ));
}
