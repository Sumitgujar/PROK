import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prok_mobile/theme/app_theme.dart';
import 'package:prok_mobile/providers/attendance_provider.dart';
import 'package:prok_mobile/widgets/loading_widget.dart';
import 'package:prok_mobile/widgets/error_state_widget.dart';
import 'package:prok_mobile/widgets/empty_state_widget.dart';
import 'package:prok_mobile/widgets/stat_card.dart';
class StudentAttendanceScreen extends StatefulWidget {
  const StudentAttendanceScreen({super.key});
  @override State<StudentAttendanceScreen> createState() => _A();
}
class _A extends State<StudentAttendanceScreen> {
  @override void initState() { super.initState(); Future.microtask(() => context.read<AttendanceProvider>().fetchStudentSummary()); }
  @override Widget build(BuildContext context) {
    final p = context.watch<AttendanceProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance'),
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded, size: 20), onPressed: () => context.read<AttendanceProvider>().fetchStudentSummary())]),
      body: p.state == ProviderState.loading ? const LoadingWidget(message: 'Loading...')
        : p.state == ProviderState.error ? ErrorStateWidget(error: p.error ?? 'Error', onRetry: () => context.read<AttendanceProvider>().fetchStudentSummary())
        : p.summary == null ? const EmptyStateWidget(title: 'No attendance data', icon: Icons.bar_chart_outlined)
        : RefreshIndicator(color: ProkColors.primary, onRefresh: () => context.read<AttendanceProvider>().fetchStudentSummary(),
          child: ListView(padding: const EdgeInsets.all(16), children: [
            _overall(p), const SizedBox(height: 16), const SectionHeader(title: 'By Subject'), const SizedBox(height: 10),
            ...((p.summary?['subject_attendance'] as List?) ?? []).map(_sub),
          ])));
  }
  Widget _overall(AttendanceProvider p) {
    final pct = (p.summary?['overall_percentage'] ?? 0) as num;
    final c = pct >= 75 ? ProkColors.success : pct >= 60 ? ProkColors.warning : ProkColors.error;
    return ProkCard(child: Column(children: [
      Row(children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Overall', style: TextStyle(fontSize: 12, color: ProkColors.neutral400)),
        Text('\$pct%', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: c)),
      ]), const Spacer(), RiskBadge(level: p.summary?['risk_level'] ?? 'LOW')]),
      const SizedBox(height: 12),
      ClipRRect(borderRadius: ProkRadius.full, child: LinearProgressIndicator(value: pct / 100, minHeight: 8, backgroundColor: ProkColors.neutral200, valueColor: AlwaysStoppedAnimation(c))),
    ]));
  }
  Widget _sub(dynamic s) {
    final pct = (s['percentage'] ?? 0) as num;
    final c = pct >= 75 ? ProkColors.success : pct >= 60 ? ProkColors.warning : ProkColors.error;
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: ProkCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(s['course_title'] ?? s['course_code'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ProkColors.neutral900))),
        Text('\$pct%', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c)),
      ]),
      Text(s['course_code'] ?? '', style: const TextStyle(fontSize: 12, color: ProkColors.neutral400)),
      const SizedBox(height: 8),
      ClipRRect(borderRadius: ProkRadius.full, child: LinearProgressIndicator(value: pct / 100, minHeight: 5, backgroundColor: ProkColors.neutral200, valueColor: AlwaysStoppedAnimation(c))),
      const SizedBox(height: 4),
      Text('\${s['attended'] ?? 0}/\${s['total'] ?? 0} classes', style: const TextStyle(fontSize: 11, color: ProkColors.neutral400)),
    ])));
  }
}
