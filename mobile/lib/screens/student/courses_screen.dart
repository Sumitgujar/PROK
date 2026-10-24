import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prok_mobile/theme/app_theme.dart';
import 'package:prok_mobile/providers/course_provider.dart';
import 'package:prok_mobile/providers/attendance_provider.dart';
import 'package:prok_mobile/models/course_model.dart';
import 'package:prok_mobile/widgets/loading_widget.dart';
import 'package:prok_mobile/widgets/error_state_widget.dart';
import 'package:prok_mobile/widgets/empty_state_widget.dart';

class StudentCoursesScreen extends StatefulWidget {
  const StudentCoursesScreen({super.key});
  @override
  State<StudentCoursesScreen> createState() => _StudentCoursesScreenState();
}

class _StudentCoursesScreenState extends State<StudentCoursesScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  String _query = '';
  String? _enrollingId;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    Future.microtask(_load);
  }

  Future<void> _load() async {
    final provider = context.read<CourseProvider>();
    await provider.loadCourses();
    await provider.loadEnrolled();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _enroll(CourseModel course) async {
    setState(() => _enrollingId = course.id);
    try {
      await context.read<CourseProvider>().enroll(course.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Enrolled in ' + course.courseCode + '.'),
        backgroundColor: ProkColors.success,
      ));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error.toString().replaceFirst('Exception: ', '')),
        backgroundColor: ProkColors.error,
      ));
    } finally {
      if (mounted) setState(() => _enrollingId = null);
    }
  }

  void _showDetails(CourseModel course) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(course.courseCode, style: const TextStyle(color: ProkColors.primary, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.1)),
              const SizedBox(height: 8),
              Text(course.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: ProkColors.neutral900)),
              const SizedBox(height: 14),
              _DetailRow(label: 'Department', value: course.department),
              _DetailRow(label: 'Credits', value: course.credits.toString()),
              _DetailRow(label: 'Instructor', value: course.teacherName),
              if (course.tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text('Topics', style: TextStyle(fontWeight: FontWeight.w700, color: ProkColors.neutral800)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: course.tags.map((tag) => Chip(label: Text(tag), visualDensity: VisualDensity.compact)).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CourseProvider>();
    final enrolledIds = provider.enrollments.map((item) => item.courseId).toSet();
    final query = _query.trim().toLowerCase();
    final discover = provider.courses.where((course) =>
      !enrolledIds.contains(course.id) &&
      (query.isEmpty ||
        course.title.toLowerCase().contains(query) ||
        course.courseCode.toLowerCase().contains(query) ||
        course.department.toLowerCase().contains(query) ||
        course.tags.any((tag) => tag.toLowerCase().contains(query)))).toList();
    final enrolled = provider.enrollments.where((item) =>
      query.isEmpty ||
      item.courseTitle.toLowerCase().contains(query) ||
      item.courseCode.toLowerCase().contains(query)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Courses'),
        actions: [
          IconButton(tooltip: 'Refresh courses', icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: ProkColors.primary,
          unselectedLabelColor: ProkColors.neutral400,
          indicatorColor: ProkColors.primary,
          tabs: [
            const Tab(text: 'Discover'),
            Tab(text: 'My Courses (' + provider.enrollments.length.toString() + ')'),
          ],
        ),
      ),
      body: provider.state == ProviderState.loading && provider.courses.isEmpty
          ? const LoadingWidget(message: 'Loading course catalogue…')
          : provider.state == ProviderState.error && provider.courses.isEmpty
              ? ErrorStateWidget(error: provider.error ?? 'Courses could not be loaded.', onRetry: _load)
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                      child: TextField(
                        onChanged: (value) => setState(() => _query = value),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search_rounded),
                          hintText: 'Search courses, departments or tags',
                          filled: true,
                          fillColor: ProkColors.white,
                          border: OutlineInputBorder(borderRadius: ProkRadius.md, borderSide: BorderSide(color: ProkColors.neutral200)),
                        ),
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabs,
                        children: [
                          discover.isEmpty
                              ? ListView(children: const [
                                  SizedBox(height: 60),
                                  EmptyStateWidget(title: 'No courses match', subtitle: 'Try another search or check My Courses.', icon: Icons.menu_book_outlined),
                                ])
                              : RefreshIndicator(
                                  color: ProkColors.primary,
                                  onRefresh: () => context.read<CourseProvider>().loadCourses(),
                                  child: ListView.separated(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: discover.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                                    itemBuilder: (context, index) {
                                      final course = discover[index];
                                      return _CourseCard(
                                        course: course,
                                        busy: _enrollingId == course.id,
                                        onDetails: () => _showDetails(course),
                                        onEnroll: () => _enroll(course),
                                      );
                                    },
                                  ),
                                ),
                          enrolled.isEmpty
                              ? ListView(children: const [
                                  SizedBox(height: 60),
                                  EmptyStateWidget(title: 'No enrolled courses', subtitle: 'Discover a course and enrol to see it here.', icon: Icons.school_outlined),
                                ])
                              : RefreshIndicator(
                                  color: ProkColors.primary,
                                  onRefresh: () => context.read<CourseProvider>().loadEnrolled(),
                                  child: ListView.separated(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: enrolled.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                                    itemBuilder: (context, index) {
                                      final item = enrolled[index];
                                      return ProkCard(
                                        child: Row(
                                          children: [
                                            const CircleAvatar(backgroundColor: ProkColors.successSurface, child: Icon(Icons.check_rounded, color: ProkColors.success)),
                                            const SizedBox(width: 12),
                                            Expanded(child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(item.courseTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ProkColors.neutral900)),
                                                const SizedBox(height: 3),
                                                Text(item.courseCode, style: const TextStyle(fontSize: 12, color: ProkColors.neutral400)),
                                              ],
                                            )),
                                            StatusBadge(status: item.status),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final CourseModel course;
  final bool busy;
  final VoidCallback onDetails;
  final VoidCallback onEnroll;
  const _CourseCard({required this.course, required this.busy, required this.onDetails, required this.onEnroll});

  @override
  Widget build(BuildContext context) => ProkCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            width: 42, height: 42,
            decoration: const BoxDecoration(color: ProkColors.primarySurface, borderRadius: ProkRadius.md),
            child: const Icon(Icons.menu_book_rounded, color: ProkColors.primary, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(course.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ProkColors.neutral900)),
              const SizedBox(height: 3),
              Text(course.courseCode, style: const TextStyle(fontSize: 12, color: ProkColors.neutral400)),
            ],
          )),
          Text(course.credits.toString() + ' cr', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ProkColors.primary)),
        ]),
        const SizedBox(height: 10),
        Text(course.department, style: const TextStyle(fontSize: 12, color: ProkColors.neutral600)),
        if (course.tags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6, runSpacing: 2,
            children: course.tags.take(3).map((tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: ProkColors.neutral100, borderRadius: ProkRadius.full),
              child: Text(tag, style: const TextStyle(fontSize: 10, color: ProkColors.neutral600)),
            )).toList(),
          ),
        ],
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: onDetails, child: const Text('Details'))),
          const SizedBox(width: 8),
          Expanded(child: ElevatedButton(onPressed: busy ? null : onEnroll, child: Text(busy ? 'Enrolling…' : 'Enrol'))),
        ]),
      ],
    ),
  );
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      SizedBox(width: 110, child: Text(label, style: const TextStyle(fontSize: 12, color: ProkColors.neutral400))),
      Expanded(child: Text(value.isEmpty ? 'Not provided' : value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ProkColors.neutral800))),
    ]),
  );
}
