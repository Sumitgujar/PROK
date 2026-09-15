import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prok_mobile/providers/course_provider.dart';
import 'package:prok_mobile/providers/attendance_provider.dart';
import 'package:prok_mobile/widgets/loading_widget.dart';
import 'package:prok_mobile/widgets/empty_state_widget.dart';
import 'package:prok_mobile/widgets/error_state_widget.dart';

class StudentCoursesScreen extends StatefulWidget {
  const StudentCoursesScreen({super.key});
  @override State<StudentCoursesScreen> createState() => _State();
}

class _State extends State<StudentCoursesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);

  @override void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().loadCourses();
      context.read<CourseProvider>().loadEnrolled();
    });
  }
  @override void dispose() { _tab.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    final prov = context.watch<CourseProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Courses'),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.white, labelColor: Colors.white, unselectedLabelColor: Colors.white60,
          tabs: const [Tab(text: 'Catalogue'), Tab(text: 'My Courses')],
        ),
      ),
      body: TabBarView(controller: _tab, children: [
        // Catalogue
        RefreshIndicator(
          onRefresh: () => context.read<CourseProvider>().loadCourses(),
          child: Builder(builder: (_) {
            if (prov.isLoading) return const LoadingWidget();
            if (prov.state == ProviderState.error)
              return ErrorStateWidget(
                  error: prov.error!, onRetry: () => context.read<CourseProvider>().loadCourses());
            if (prov.courses.isEmpty)
              return const EmptyStateWidget(
                  title: 'No courses available', icon: Icons.school_outlined);
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: prov.courses.length,
              itemBuilder: (ctx, i) {
                final course = prov.courses[i];
                final enrolled = prov.enrollments.any((e) => e.courseId == course.id);
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(course.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6)),
                          child: Text('${course.credits} cr',
                              style: const TextStyle(
                                  color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold))),
                      ]),
                      Text(course.courseCode, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      Text(course.teacherName, style: const TextStyle(fontSize: 12)),
                      if (course.tags.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          children: course.tags.take(3).map((t) => Chip(
                            label: Text(t, style: const TextStyle(fontSize: 10)),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          )).toList()),
                      ],
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: enrolled
                            ? OutlinedButton.icon(
                                onPressed: null,
                                icon: const Icon(Icons.check, size: 16),
                                label: const Text('Enrolled'))
                            : ElevatedButton(
                                onPressed: () async {
                                  try {
                                    await context.read<CourseProvider>().enroll(course.id);
                                    if (context.mounted)
                                      ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                              content: Text('Enrolled!'),
                                              backgroundColor: Colors.green));
                                  } catch (e) {
                                    if (context.mounted)
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                          content: Text(e.toString().replaceAll('Exception: ', '')),
                                          backgroundColor: Colors.red));
                                  }
                                },
                                child: const Text('Enrol')),
                      ),
                    ])),
                );
              },
            );
          }),
        ),
        // My Courses
        RefreshIndicator(
          onRefresh: () => context.read<CourseProvider>().loadEnrolled(),
          child: prov.enrollments.isEmpty
              ? const EmptyStateWidget(
                  title: 'Not enrolled in any courses', icon: Icons.library_books_outlined)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: prov.enrollments.length,
                  itemBuilder: (ctx, i) {
                    final e = prov.enrollments[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF1E3A8A),
                          child: Text(
                            e.courseCode.length >= 2 ? e.courseCode.substring(0, 2) : e.courseCode,
                            style: const TextStyle(color: Colors.white, fontSize: 12))),
                        title: Text(e.courseTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(e.courseCode),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8)),
                          child: Text(e.status.toUpperCase(),
                              style: const TextStyle(color: Colors.green, fontSize: 11))),
                      ));
                  }),
        ),
      ]),
    );
  }
}
