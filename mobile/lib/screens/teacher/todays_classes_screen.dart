import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prok_mobile/theme/app_theme.dart';
import 'package:prok_mobile/providers/attendance_provider.dart';
import 'package:prok_mobile/widgets/loading_widget.dart';
import 'package:prok_mobile/widgets/error_state_widget.dart';
import 'package:prok_mobile/widgets/empty_state_widget.dart';
import 'package:prok_mobile/widgets/stat_card.dart';
import 'package:prok_mobile/core/constants.dart';
class TeacherTodaysClassesScreen extends StatefulWidget {
  const TeacherTodaysClassesScreen({super.key});
  @override State<TeacherTodaysClassesScreen> createState() => _TC();
}
class _TC extends State<TeacherTodaysClassesScreen> {
  int _tab = 0;
  @override void initState() { super.initState(); Future.microtask(() => context.read<AttendanceProvider>().fetchTeacherClasses()); }
  void _nav(int i) { if (i == 0) return; Navigator.pushNamed(context, [AppRoutes.teacherHome, AppRoutes.teacherAttendanceInsights, AppRoutes.teacherProfile][i]); }
  @override Widget build(BuildContext context) {
    final p = context.watch<AttendanceProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text("Today's Classes"),
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded, size: 20), onPressed: () => context.read<AttendanceProvider>().fetchTeacherClasses())]),
      body: p.state == ProviderState.loading ? const LoadingWidget(message: 'Loading classes...')
        : p.state == ProviderState.error ? ErrorStateWidget(error: p.error ?? 'Error', onRetry: () => context.read<AttendanceProvider>().fetchTeacherClasses())
        : p.teacherClasses.isEmpty ? const EmptyStateWidget(title: 'No classes today', subtitle: 'Your scheduled sessions will appear here', icon: Icons.event_note_outlined)
        : RefreshIndicator(color: ProkColors.primary, onRefresh: () => context.read<AttendanceProvider>().fetchTeacherClasses(),
          child: ListView.separated(padding: const EdgeInsets.all(16), itemCount: p.teacherClasses.length, separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) { final c = p.teacherClasses[i]; return ProkCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 40, height: 40, decoration: const BoxDecoration(color: ProkColors.primarySurface, borderRadius: ProkRadius.sm),
                  child: const Icon(Icons.class_outlined, color: ProkColors.primary, size: 20)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c['course_title'] ?? c['course_code'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ProkColors.neutral900)),
                  Text(c['course_code'] ?? '', style: const TextStyle(fontSize: 12, color: ProkColors.neutral400)),
                ])),
              ]),
              const SizedBox(height: 10), const Divider(height: 1), const SizedBox(height: 10),
              Text('Students: \${c["enrolled_count"] ?? 0}', style: const TextStyle(fontSize: 12, color: ProkColors.neutral600)),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: OutlinedButton.icon(onPressed: () => Navigator.pushNamed(context, AppRoutes.teacherMarkAttendance, arguments: c),
                  icon: const Icon(Icons.edit_rounded, size: 15), label: const Text('Mark'), style: OutlinedButton.styleFrom(minimumSize: const Size(0, 38)))),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton.icon(onPressed: () => Navigator.pushNamed(context, AppRoutes.teacherAttendanceHistory, arguments: c),
                  icon: const Icon(Icons.history_rounded, size: 15), label: const Text('History'), style: OutlinedButton.styleFrom(minimumSize: const Size(0, 38)))),
              ]),
            ])); })),
      bottomNavigationBar: Container(decoration: const BoxDecoration(border: Border(top: BorderSide(color: ProkColors.neutral200))),
        child: BottomNavigationBar(currentIndex: _tab, onTap: _nav, items: const [
          BottomNavigationBarItem(icon: Icon(Icons.today_rounded), label: 'Classes'),
          BottomNavigationBarItem(icon: Icon(Icons.insights_rounded), label: 'Insights'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ])),
    );
  }
}
