import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prok_mobile/theme/app_theme.dart';
import 'package:prok_mobile/providers/attendance_provider.dart';
import 'package:prok_mobile/widgets/loading_widget.dart';
import 'package:prok_mobile/widgets/error_state_widget.dart';
import 'package:prok_mobile/widgets/empty_state_widget.dart';

class StudentAttendanceScreen extends StatefulWidget {
  const StudentAttendanceScreen({super.key});
  @override
  State<StudentAttendanceScreen> createState() => _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  String _query = '';
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<AttendanceProvider>().loadSummary());
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AttendanceProvider>();
    final all = p.summary;
    final present = all.fold<int>(0, (sum, item) => sum + item.present);
    final total = all.fold<int>(0, (sum, item) => sum + item.totalSessions);
    final overall = total == 0 ? 0 : (present * 100 / total).round();
    final query = _query.trim().toLowerCase();
    final filtered = all.where((item) {
      final textMatches = query.isEmpty ||
          item.courseTitle.toLowerCase().contains(query) ||
          item.courseCode.toLowerCase().contains(query);
      final statusMatches = _filter == 'All' ||
          (_filter == 'At risk' && item.percentage < 75) ||
          (_filter == 'On track' && item.percentage >= 75);
      return textMatches && statusMatches;
    }).toList()..sort((a, b) => a.percentage.compareTo(b.percentage));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: [IconButton(
          tooltip: 'Refresh attendance',
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () => context.read<AttendanceProvider>().loadSummary(),
        )],
      ),
      body: p.state == ProviderState.loading
          ? const LoadingWidget(message: 'Loading attendance…')
          : p.state == ProviderState.error
              ? ErrorStateWidget(
                  error: p.error ?? 'Attendance could not be loaded.',
                  onRetry: () => context.read<AttendanceProvider>().loadSummary(),
                )
              : RefreshIndicator(
                  color: ProkColors.primary,
                  onRefresh: () => context.read<AttendanceProvider>().loadSummary(),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _OverallCard(percentage: overall, attended: present, total: total),
                      const SizedBox(height: 18),
                      const SectionHeader(title: 'Subject breakdown'),
                      const SizedBox(height: 10),
                      TextField(
                        onChanged: (value) => setState(() => _query = value),
                        decoration: InputDecoration(
                          hintText: 'Search course or course code',
                          prefixIcon: const Icon(Icons.search_rounded),
                          filled: true,
                          fillColor: ProkColors.white,
                          border: OutlineInputBorder(
                            borderRadius: ProkRadius.md,
                            borderSide: BorderSide(color: ProkColors.neutral200),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: ['All', 'At risk', 'On track'].map((value) => ChoiceChip(
                          label: Text(value),
                          selected: _filter == value,
                          onSelected: (_) => setState(() => _filter = value),
                          selectedColor: ProkColors.primarySurface,
                          labelStyle: TextStyle(
                            color: _filter == value ? ProkColors.primary : ProkColors.neutral600,
                            fontWeight: FontWeight.w600,
                          ),
                        )).toList(),
                      ),
                      const SizedBox(height: 12),
                      if (all.isEmpty)
                        const EmptyStateWidget(
                          title: 'No attendance data yet',
                          subtitle: 'Summaries appear after attendance is recorded.',
                          icon: Icons.bar_chart_rounded,
                        )
                      else if (filtered.isEmpty)
                        const EmptyStateWidget(
                          title: 'No matching subjects',
                          subtitle: 'Change the search text or filter.',
                          icon: Icons.search_off_rounded,
                        )
                      else
                        ...filtered.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _SubjectCard(
                            title: item.courseTitle,
                            code: item.courseCode,
                            attended: item.present,
                            total: item.totalSessions,
                            percentage: item.percentage,
                          ),
                        )),
                      const SizedBox(height: 12),
                      const Text(
                        'Attendance is calculated from sessions recorded by your college. Contact your teacher if a record looks incorrect.',
                        style: TextStyle(fontSize: 12, height: 1.5, color: ProkColors.neutral400),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _OverallCard extends StatelessWidget {
  final int percentage, attended, total;
  const _OverallCard({required this.percentage, required this.attended, required this.total});

  @override
  Widget build(BuildContext context) {
    final color = percentage >= 75 ? ProkColors.success : percentage >= 60 ? ProkColors.warning : ProkColors.error;
    return ProkCard(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Overall attendance', style: TextStyle(fontSize: 13, color: ProkColors.neutral600)),
        const SizedBox(height: 8),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('$percentage%', style: TextStyle(fontSize: 38, height: 1, fontWeight: FontWeight.w800, color: color)),
          const Spacer(),
          RiskBadge(level: percentage >= 75 ? 'LOW' : percentage >= 60 ? 'MEDIUM' : 'HIGH'),
        ]),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: ProkRadius.full,
          child: LinearProgressIndicator(
            value: (percentage / 100).clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: ProkColors.neutral200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 10),
        Text('$attended attended out of $total recorded course sessions',
            style: const TextStyle(fontSize: 12, color: ProkColors.neutral500)),
      ],
    ));
  }
}

class _SubjectCard extends StatelessWidget {
  final String title, code;
  final int attended, total, percentage;
  const _SubjectCard({
    required this.title, required this.code, required this.attended,
    required this.total, required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    final color = percentage >= 75 ? ProkColors.success : percentage >= 60 ? ProkColors.warning : ProkColors.error;
    final missed = (total - attended).clamp(0, total);
    return ProkCard(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ProkColors.neutral900)),
            const SizedBox(height: 3),
            Text(code, style: const TextStyle(fontSize: 12, color: ProkColors.neutral400)),
          ])),
          Text('$percentage%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: ProkRadius.full,
          child: LinearProgressIndicator(
            value: (percentage / 100).clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: ProkColors.neutral200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 10),
        Row(children: [
          _Pill(label: 'Present $attended', color: ProkColors.success),
          const SizedBox(width: 6),
          _Pill(label: 'Missed $missed', color: ProkColors.error),
          const Spacer(),
          Text('$total sessions', style: const TextStyle(fontSize: 11, color: ProkColors.neutral400)),
        ]),
      ],
    ));
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(color: color.withOpacity(0.09), borderRadius: ProkRadius.full),
    child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
  );
}
