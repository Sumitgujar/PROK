import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prok_mobile/providers/attendance_provider.dart';
import 'package:prok_mobile/widgets/loading_widget.dart';
import 'package:prok_mobile/widgets/empty_state_widget.dart';
import 'package:prok_mobile/widgets/error_state_widget.dart';

class TeacherTodaysClassesScreen extends StatefulWidget {
  const TeacherTodaysClassesScreen({super.key});
  @override State<TeacherTodaysClassesScreen> createState() => _State();
}

class _State extends State<TeacherTodaysClassesScreen> {
  @override void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<AttendanceProvider>().loadTeacherCourses());
  }

  @override Widget build(BuildContext context) {
    final prov = context.watch<AttendanceProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text("Today's Classes")),
      body: RefreshIndicator(
        onRefresh: () => context.read<AttendanceProvider>().loadTeacherCourses(),
        child: Builder(builder: (_) {
          if (prov.isLoading) return const LoadingWidget(message: 'Loading classes...');
          if (prov.state == ProviderState.error)
            return ErrorStateWidget(
                error: prov.error!,
                onRetry: () => context.read<AttendanceProvider>().loadTeacherCourses());
          if (prov.teacherCourses.isEmpty)
            return const EmptyStateWidget(
                title: 'No classes today',
                subtitle: 'Your scheduled classes appear here.',
                icon: Icons.class_outlined);
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: prov.teacherCourses.length,
            itemBuilder: (ctx, i) {
              final c = prov.teacherCourses[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(c['title'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(c['course_code'] ?? '',
                            style: const TextStyle(
                                color: Color(0xFF1E3A8A),
                                fontWeight: FontWeight.bold, fontSize: 12))),
                    ]),
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.people_outline, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('${c["enrolled_count"] ?? 0} enrolled',
                          style: const TextStyle(color: Colors.grey)),
                      const SizedBox(width: 16),
                      const Icon(Icons.credit_score_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('${c["credits"] ?? 0} credits',
                          style: const TextStyle(color: Colors.grey)),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.history, size: 16),
                          label: const Text('History'),
                          onPressed: () => Navigator.pushNamed(
                              context, '/teacher/attendance-history',
                              arguments: c)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.how_to_reg, size: 16),
                          label: const Text('Mark'),
                          onPressed: () => Navigator.pushNamed(
                              context, '/teacher/mark-attendance',
                              arguments: c)),
                      ),
                    ]),
                  ]),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
