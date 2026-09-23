import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prok_mobile/theme/app_theme.dart';
import 'package:prok_mobile/providers/course_provider.dart';
import 'package:prok_mobile/widgets/loading_widget.dart';
import 'package:prok_mobile/widgets/error_state_widget.dart';
import 'package:prok_mobile/widgets/empty_state_widget.dart';
import 'package:prok_mobile/widgets/stat_card.dart';
class StudentCoursesScreen extends StatefulWidget {
  const StudentCoursesScreen({super.key});
  @override State<StudentCoursesScreen> createState() => _C();
}
class _C extends State<StudentCoursesScreen> with SingleTickerProviderStateMixin {
  late TabController _t;
  @override void initState() { super.initState(); _t = TabController(length: 2, vsync: this); Future.microtask(() { context.read<CourseProvider>().fetchCourses(); context.read<CourseProvider>().fetchMyCourses(); }); }
  @override void dispose() { _t.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    final p = context.watch<CourseProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Courses'), bottom: TabBar(controller: _t, labelColor: ProkColors.primary, unselectedLabelColor: ProkColors.neutral400, indicatorColor: ProkColors.primary,
        tabs: const [Tab(text: 'Discover'), Tab(text: 'My Courses')])),
      body: p.state == ProviderState.loading ? const LoadingWidget()
        : p.state == ProviderState.error ? ErrorStateWidget(error: p.error ?? 'Error', onRetry: () => context.read<CourseProvider>().fetchCourses())
        : TabBarView(controller: _t, children: [_Discover(p: p), _Mine(p: p)]));
  }
}
class _Discover extends StatelessWidget {
  final CourseProvider p;
  const _Discover({required this.p});
  @override Widget build(BuildContext context) {
    if (p.courses.isEmpty) return const EmptyStateWidget(title: 'No courses available', icon: Icons.menu_book_outlined);
    return ListView.separated(padding: const EdgeInsets.all(16), itemCount: p.courses.length, separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) { final c = p.courses[i]; return ProkCard(child: Row(children: [
        Container(width: 44, height: 44, decoration: const BoxDecoration(color: ProkColors.primarySurface, borderRadius: ProkRadius.md),
          child: const Icon(Icons.menu_book_rounded, color: ProkColors.primaryLight, size: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(c.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ProkColors.neutral900)),
          Text(c.courseCode, style: const TextStyle(fontSize: 12, color: ProkColors.neutral400)),
        ])),
        TextButton(onPressed: () async {
          await context.read<CourseProvider>().enroll(c.id);
          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enrolled')));
        }, child: const Text('Enrol')),
      ])); });
  }
}
class _Mine extends StatelessWidget {
  final CourseProvider p;
  const _Mine({required this.p});
  @override Widget build(BuildContext context) {
    if (p.myCourses.isEmpty) return const EmptyStateWidget(title: 'Not enrolled in any courses', subtitle: 'Browse Discover to enrol', icon: Icons.school_outlined);
    return ListView.separated(padding: const EdgeInsets.all(16), itemCount: p.myCourses.length, separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) { final c = p.myCourses[i]; return ProkCard(child: Row(children: [
        Container(width: 40, height: 40, decoration: const BoxDecoration(color: ProkColors.successSurface, borderRadius: ProkRadius.sm),
          child: const Icon(Icons.check_rounded, color: ProkColors.success, size: 20)),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(c['title'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ProkColors.neutral900)),
          Text(c['course_code'] ?? '', style: const TextStyle(fontSize: 12, color: ProkColors.neutral400)),
        ]),
      ])); });
  }
}
