
import 'package:flutter/material.dart';
import 'package:prok_mobile/theme/app_theme.dart';

class ProkCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  const ProkCard({super.key, required this.child, this.padding, this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ProkColors.white,
        borderRadius: ProkRadius.lg,
        border: Border.all(color: ProkColors.neutral200),
      ),
      child: child,
    ),
  );
}

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? sub;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const StatCard({super.key, required this.label, required this.value, this.sub, required this.icon, required this.color, this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: ProkColors.white, borderRadius: ProkRadius.lg, border: Border.all(color: ProkColors.neutral200)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 36, height: 36,
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: ProkRadius.sm),
          child: Icon(icon, size: 18, color: color)),
        const SizedBox(height: 10),
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color, letterSpacing: -0.5)),
        Text(label, style: const TextStyle(fontSize: 12, color: ProkColors.neutral400, fontWeight: FontWeight.w500)),
        if (sub != null) Text(sub!, style: const TextStyle(fontSize: 11, color: ProkColors.neutral400)),
      ]),
    ),
  );
}

class RiskBadge extends StatelessWidget {
  final String level;
  const RiskBadge({super.key, required this.level});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: ProkColors.riskSurface(level), borderRadius: ProkRadius.full),
    child: Text(level.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: ProkColors.riskColor(level), letterSpacing: 0.5)),
  );
}

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});
  Color get _bg {
    switch (status.toUpperCase()) {
      case 'VERIFIED': case 'APPROVED': case 'PRESENT': return ProkColors.successSurface;
      case 'REJECTED': case 'ABSENT': return ProkColors.errorSurface;
      case 'UNDER_REVIEW': case 'PENDING': case 'LATE': return ProkColors.warningSurface;
      default: return ProkColors.neutral100;
    }
  }
  Color get _fg {
    switch (status.toUpperCase()) {
      case 'VERIFIED': case 'APPROVED': case 'PRESENT': return ProkColors.success;
      case 'REJECTED': case 'ABSENT': return ProkColors.error;
      case 'UNDER_REVIEW': case 'PENDING': case 'LATE': return ProkColors.warning;
      default: return ProkColors.neutral600;
    }
  }
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: _bg, borderRadius: ProkRadius.full),
    child: Text(status.replaceAll('_', ' '), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _fg, letterSpacing: 0.3)),
  );
}

class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({super.key, required this.title});
  @override
  Widget build(BuildContext context) => Text(title,
    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ProkColors.neutral800, letterSpacing: 0.1));
}

class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const InfoRow({super.key, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(width: 110, child: Text(label, style: const TextStyle(fontSize: 13, color: ProkColors.neutral400, fontWeight: FontWeight.w500))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ProkColors.neutral900))),
    ],
  );
}
