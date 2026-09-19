
import 'package:flutter/material.dart';
import 'package:prok_mobile/theme/app_theme.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;
  const LoadingWidget({super.key, this.message});
  @override
  Widget build(BuildContext context) => Center(child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const CircularProgressIndicator(strokeWidth: 2, color: ProkColors.primary),
      if (message != null) ...[
        const SizedBox(height: 14),
        Text(message!, style: const TextStyle(fontSize: 13, color: ProkColors.neutral400)),
      ],
    ],
  ));
}
