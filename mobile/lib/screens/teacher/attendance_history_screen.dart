import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prok_mobile/providers/attendance_provider.dart';
import 'package:prok_mobile/widgets/loading_widget.dart';
import 'package:prok_mobile/widgets/empty_state_widget.dart';
import 'package:prok_mobile/widgets/error_state_widget.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});
  @override State<AttendanceHistoryScreen> createState() => _State();
}

class _State extends State<AttendanceHistoryScreen> {
  Map<String, dynamic>? _course;

  @override void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _course = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (_course != null)
        context.read<AttendanceProvider>().loadCourseHistory(_course!['_id']);
    });
  }

  Color _scol(String s) =>
      s == 'present' ? Colors.green : s == 'late' ? Colors.orange : Colors.red;

  @override Widget build(BuildContext context) {
    final prov = context.watch<AttendanceProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(_course?['title'] ?? 'Attendance History'),
        subtitle: Text(_course?['course_code'] ?? ''),
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<AttendanceProvider>()
            .loadCourseHistory(_course!['_id']),
        child: Builder(builder: (_) {
          if (prov.isLoading) return const LoadingWidget();
          if (prov.state == ProviderState.error)
            return ErrorStateWidget(
                error: prov.error!,
                onRetry: () => context
                    .read<AttendanceProvider>()
                    .loadCourseHistory(_course!['_id']));
          if (prov.courseHistory.isEmpty)
            return const EmptyStateWidget(
                title: 'No attendance sessions',
                icon: Icons.history_outlined);
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: prov.courseHistory.length,
            itemBuilder: (ctx, i) {
              final session = prov.courseHistory[i];
              final date = session['date'] as String? ?? '';
              final records = (session['records'] as List?) ?? [];
              final present = records.where((r) => r['status'] == 'present').length;
              final total = records.length;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Theme(data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    title: Text(
                        date.length >= 10 ? date.substring(0, 10) : date,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('$present/$total present'),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('${total > 0 ? (present * 100 ~/ total) : 0}%',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: total > 0 && present * 100 ~/ total >= 75
                                  ? Colors.green
                                  : Colors.red)),
                      const Icon(Icons.expand_more),
                    ]),
                    children: records.map((r) => ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                      leading: Container(
                        width: 10, height: 10,
                        margin: const EdgeInsets.only(top: 5),
                        decoration: BoxDecoration(
                            color: _scol(r['status'] ?? 'absent'),
                            shape: BoxShape.circle)),
                      title: Text(r['student_name'] ?? r['student_id'] ?? ''),
                      trailing: Text((r['status'] ?? 'absent').toString().toUpperCase(),
                          style: TextStyle(
                              color: _scol(r['status'] ?? 'absent'),
                              fontSize: 11, fontWeight: FontWeight.bold)),
                    )).toList(),
                  )),
              );
            },
          );
        }),
      ),
    );
  }
}
