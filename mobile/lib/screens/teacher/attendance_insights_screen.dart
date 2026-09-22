import 'package:flutter/material.dart';
import 'package:prok_mobile/theme/app_theme.dart';
import 'package:prok_mobile/services/api_service.dart';
import 'package:prok_mobile/widgets/loading_widget.dart';
import 'package:prok_mobile/widgets/error_state_widget.dart';
import 'package:prok_mobile/widgets/empty_state_widget.dart';
import 'package:prok_mobile/widgets/stat_card.dart';
class AttendanceInsightsScreen extends StatefulWidget {
  const AttendanceInsightsScreen({super.key});
  @override State<AttendanceInsightsScreen> createState() => _AI();
}
class _AI extends State<AttendanceInsightsScreen> {
  List _courses = []; bool _loading = true; String? _error;
  @override void initState() { super.initState(); Future.microtask(_load); }
  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try { final d = await ApiService().get('/attendance/teacher/classes'); _courses = (d['courses'] ?? d['sessions'] ?? []) as List; setState(() => _loading = false); }
    catch (e) { setState(() { _loading = false; _error = e.toString().replaceAll('Exception: ', ''); }); }
  }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Attendance Insights'), actions: [IconButton(icon: const Icon(Icons.refresh_rounded, size: 20), onPressed: _load)]),
    body: _loading ? const LoadingWidget(message: 'Loading insights...')
      : _error != null ? ErrorStateWidget(error: _error!, onRetry: _load)
      : _courses.isEmpty ? const EmptyStateWidget(title: 'No class data available', icon: Icons.insights_outlined)
      : ListView(padding: const EdgeInsets.all(16), children: [
          const SectionHeader(title: 'Class Attendance Overview'), const SizedBox(height: 12),
          ..._courses.map((c) => _CourseCard(course: c as Map)),
        ]),
  );
}
class _CourseCard extends StatefulWidget {
  final Map course;
  const _CourseCard({required this.course});
  @override State<_CourseCard> createState() => _CCState();
}
class _CCState extends State<_CourseCard> {
  List _atRisk = []; bool _loaded = false, _fetching = false;
  Future<void> _fetch() async {
    if (_loaded) { setState(() => _loaded = false); return; }
    setState(() => _fetching = true);
    try {
      final cid = widget.course['course_id'] ?? widget.course['id'] ?? '';
      final d = await ApiService().get('/intelligence/course/\$cid/at-risk');
      _atRisk = (d['at_risk_students'] ?? []) as List; _loaded = true;
    } catch (_) {}
    if (mounted) setState(() => _fetching = false);
  }
  @override Widget build(BuildContext context) {
    final avg = (widget.course['average_attendance'] ?? widget.course['avg_attendance'] ?? 0) as num;
    final c = avg >= 75 ? ProkColors.success : avg >= 60 ? ProkColors.warning : ProkColors.error;
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: ProkCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.course['course_title'] ?? widget.course['course_code'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ProkColors.neutral900)),
          Text(widget.course['course_code'] ?? '', style: const TextStyle(fontSize: 12, color: ProkColors.neutral400)),
        ])),
        Text('\$avg%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c)),
      ]),
      const SizedBox(height: 8),
      ClipRRect(borderRadius: ProkRadius.full, child: LinearProgressIndicator(value: avg / 100, minHeight: 5, backgroundColor: ProkColors.neutral200, valueColor: AlwaysStoppedAnimation(c))),
      const SizedBox(height: 8),
      TextButton.icon(onPressed: _fetching ? null : _fetch, icon: Icon(_fetching ? Icons.hourglass_empty_rounded : (_loaded ? Icons.expand_less_rounded : Icons.warning_amber_rounded), size: 14),
        label: Text(_fetching ? 'Loading...' : (_loaded ? 'Hide' : 'View at-risk'), style: const TextStyle(fontSize: 12)),
        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap)),
      if (_loaded && _atRisk.isEmpty) const Text('No students at risk.', style: TextStyle(fontSize: 12, color: ProkColors.neutral400)),
      if (_loaded) ...[
        const SizedBox(height: 6),
        ..._atRisk.take(5).map((s) => Padding(padding: const EdgeInsets.only(bottom: 4),
          child: Row(children: [
            RiskBadge(level: s['risk_level'] ?? 'MEDIUM'), const SizedBox(width: 8),
            Expanded(child: Text(s['student_name'] ?? s['student_id'] ?? '', style: const TextStyle(fontSize: 13, color: ProkColors.neutral800))),
            Text('\${s['overall_attendance'] ?? 0}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ProkColors.neutral600)),
          ]))),
      ],
    ])));
  }
}
