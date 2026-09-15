import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prok_mobile/providers/attendance_provider.dart';
import 'package:prok_mobile/widgets/loading_widget.dart';
import 'package:prok_mobile/widgets/empty_state_widget.dart';
import 'package:prok_mobile/widgets/error_state_widget.dart';

class StudentAttendanceScreen extends StatefulWidget {
  const StudentAttendanceScreen({super.key});
  @override State<StudentAttendanceScreen> createState() => _State();
}

class _State extends State<StudentAttendanceScreen> {
  @override void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<AttendanceProvider>().loadSummary());
  }

  Color _col(int p) => p >= 75 ? Colors.green : p >= 60 ? Colors.orange : Colors.red;

  @override Widget build(BuildContext context) {
    final prov = context.watch<AttendanceProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
      body: RefreshIndicator(
        onRefresh: () => context.read<AttendanceProvider>().loadSummary(),
        child: Builder(builder: (_) {
          if (prov.isLoading) return const LoadingWidget();
          if (prov.state == ProviderState.error)
            return ErrorStateWidget(error: prov.error!,
                onRetry: () => context.read<AttendanceProvider>().loadSummary());
          if (prov.summary.isEmpty)
            return const EmptyStateWidget(
                title: 'No attendance records',
                subtitle: 'Enrol in courses to see attendance.',
                icon: Icons.fact_check_outlined);
          final overall = prov.summary.isEmpty ? 0
              : (prov.summary.map((s) => s.percentage).reduce((a, b) => a + b) / prov.summary.length).round();
          return ListView(padding: const EdgeInsets.all(16), children: [
            Card(
              color: const Color(0xFF1E3A8A),
              child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
                const Text('Overall Attendance', style: TextStyle(color: Colors.white70, fontSize: 13)),
                Text('$overall%',
                    style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
                Text(overall >= 75 ? 'Good Standing' : overall >= 60 ? 'At Risk' : 'Critical',
                    style: const TextStyle(color: Colors.white70)),
              ]))),
            const SizedBox(height: 16),
            ...prov.summary.map((s) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(padding: const EdgeInsets.all(16), child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Expanded(child: Text(s.courseTitle, style: const TextStyle(fontWeight: FontWeight.bold))),
                    Text('${s.percentage}%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: _col(s.percentage))),
                  ]),
                  Text(s.courseCode, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 8),
                  ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(
                    value: s.percentage / 100, minHeight: 8, backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation(_col(s.percentage)))),
                  const SizedBox(height: 4),
                  Text('${s.present} / ${s.totalSessions} attended',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ])))),
          ]);
        }),
      ),
    );
  }
}
