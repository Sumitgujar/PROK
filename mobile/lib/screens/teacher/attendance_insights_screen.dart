import 'package:flutter/material.dart';
import 'package:prok_mobile/theme/app_theme.dart';
import 'package:prok_mobile/services/api_service.dart';
import 'package:prok_mobile/widgets/loading_widget.dart';
import 'package:prok_mobile/widgets/error_state_widget.dart';
import 'package:prok_mobile/widgets/empty_state_widget.dart';

class AttendanceInsightsScreen extends StatefulWidget {
  const AttendanceInsightsScreen({super.key});
  @override
  State<AttendanceInsightsScreen> createState() => _AttendanceInsightsScreenState();
}

class _AttendanceInsightsScreenState extends State<AttendanceInsightsScreen> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _courses = [];
  bool _loading = true;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final rawCourses = await _api.get('/attendance/teacher/courses');
      final courses = rawCourses is List
          ? List<Map<String, dynamic>>.from(rawCourses.map((item) => Map<String, dynamic>.from(item as Map)))
          : <Map<String, dynamic>>[];
      final results = <Map<String, dynamic>>[];

      for (final course in courses) {
        final id = (course['_id'] ?? course['course_id'] ?? course['id'] ?? '').toString();
        if (id.isEmpty) continue;
        final rawHistory = await _api.get('/attendance/courses/' + id + '/history');
        final sessions = rawHistory is List
            ? List<Map<String, dynamic>>.from(rawHistory.map((item) => Map<String, dynamic>.from(item as Map)))
            : <Map<String, dynamic>>[];

        final studentStats = <String, Map<String, dynamic>>{};
        var totalMarks = 0;
        var attendedMarks = 0;
        for (final session in sessions) {
          final rawRecords = session['records'];
          final records = rawRecords is List ? rawRecords : const [];
          for (final rawRecord in records) {
            if (rawRecord is! Map) continue;
            final record = Map<String, dynamic>.from(rawRecord);
            final studentId = (record['student_id'] ?? '').toString();
            if (studentId.isEmpty) continue;
            final status = (record['status'] ?? 'absent').toString().toLowerCase();
            final attended = status == 'present' || status == 'late';
            totalMarks++;
            if (attended) attendedMarks++;
            final stat = studentStats.putIfAbsent(studentId, () => <String, dynamic>{
              'student_id': studentId,
              'student_name': record['student_name'] ?? studentId,
              'present': 0,
              'total': 0,
            });
            stat['total'] = (stat['total'] as int) + 1;
            if (attended) stat['present'] = (stat['present'] as int) + 1;
          }
        }

        final students = studentStats.values.map((student) {
          final total = student['total'] as int;
          final present = student['present'] as int;
          return <String, dynamic>{
            ...student,
            'overall_attendance': total == 0 ? 0 : (present * 100 / total).round(),
          };
        }).toList()
          ..sort((a, b) => (a['overall_attendance'] as int).compareTo(b['overall_attendance'] as int));

        final atRisk = students.where((student) => (student['overall_attendance'] as int) < 75).toList();
        results.add({
          ...course,
          'course_id': id,
          'course_title': course['title'] ?? course['course_title'] ?? 'Untitled course',
          'average_attendance': totalMarks == 0 ? 0 : (attendedMarks * 100 / totalMarks).round(),
          'session_count': sessions.length,
          'record_count': totalMarks,
          'at_risk_students': atRisk,
        });
      }

      if (mounted) setState(() { _courses = results; _loading = false; });
    } catch (error) {
      if (mounted) setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final filtered = _courses.where((course) {
      final title = (course['course_title'] ?? course['title'] ?? '').toString().toLowerCase();
      final code = (course['course_code'] ?? '').toString().toLowerCase();
      return query.isEmpty || title.contains(query) || code.contains(query);
    }).toList();
    final riskCount = _courses.fold<int>(0, (sum, course) => sum + ((course['at_risk_students'] as List?)?.length ?? 0));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Insights'),
        actions: [IconButton(tooltip: 'Refresh insights', icon: const Icon(Icons.refresh_rounded), onPressed: _load)],
      ),
      body: _loading
        ? const LoadingWidget(message: 'Calculating insights from attendance records…')
        : _error != null
          ? ErrorStateWidget(error: _error!, onRetry: _load)
          : RefreshIndicator(
              color: ProkColors.primary,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [ProkColors.primary, ProkColors.primaryLight]),
                      borderRadius: ProkRadius.lg,
                    ),
                    child: Row(children: [
                      const Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Class attendance', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          SizedBox(height: 5),
                          Text('Review trends and students below 75%', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                        ],
                      )),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: ProkRadius.md),
                        child: Text(riskCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search_rounded),
                      hintText: 'Search class or course code',
                      filled: true, fillColor: ProkColors.white,
                      border: OutlineInputBorder(borderRadius: ProkRadius.md, borderSide: BorderSide(color: ProkColors.neutral200)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Courses', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: ProkColors.neutral900)),
                  const SizedBox(height: 8),
                  if (_courses.isEmpty)
                    const EmptyStateWidget(title: 'No course records', subtitle: 'Course attendance data will appear after sessions are recorded.', icon: Icons.insights_outlined)
                  else if (filtered.isEmpty)
                    const EmptyStateWidget(title: 'No matching courses', subtitle: 'Try a different search.', icon: Icons.search_off_rounded)
                  else
                    ...filtered.map((course) => _CourseCard(course: course)),
                  const SizedBox(height: 12),
                  const Text('Attendance insights are calculated from saved session records. Students below 75% may need a follow-up; confirm the context before taking action.',
                    style: TextStyle(fontSize: 12, height: 1.5, color: ProkColors.neutral400)),
                ],
              ),
            ),
    );
  }
}

class _CourseCard extends StatefulWidget {
  final Map<String, dynamic> course;
  const _CourseCard({required this.course});
  @override
  State<_CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<_CourseCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final course = widget.course;
    final avg = (course['average_attendance'] ?? 0) as num;
    final color = avg >= 75 ? ProkColors.success : avg >= 60 ? ProkColors.warning : ProkColors.error;
    final students = (course['at_risk_students'] as List?) ?? const [];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ProkCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text((course['course_title'] ?? course['title'] ?? 'Untitled course').toString(),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ProkColors.neutral900)),
              const SizedBox(height: 3),
              Text((course['course_code'] ?? 'No course code').toString(),
                  style: const TextStyle(fontSize: 12, color: ProkColors.neutral400)),
            ])),
            Text(avg.toString() + '%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          ]),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: ProkRadius.full,
            child: LinearProgressIndicator(
              value: (avg / 100).clamp(0.0, 1.0), minHeight: 6,
              backgroundColor: ProkColors.neutral200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Text((course['session_count'] ?? 0).toString() + ' sessions',
                style: const TextStyle(fontSize: 11, color: ProkColors.neutral400)),
            const SizedBox(width: 12),
            Text((course['record_count'] ?? 0).toString() + ' attendance records',
                style: const TextStyle(fontSize: 11, color: ProkColors.neutral400)),
            const Spacer(),
            Text(students.length.toString() + ' at risk',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: students.isEmpty ? ProkColors.success : ProkColors.error)),
          ]),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => setState(() => _expanded = !_expanded),
            icon: Icon(_expanded ? Icons.expand_less_rounded : Icons.people_outline_rounded, size: 18),
            label: Text(_expanded ? 'Hide students' : 'View students below 75%'),
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 36), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
          ),
          if (_expanded) ...[
            const Divider(height: 14),
            if (students.isEmpty)
              const Text('No student is below 75% in the available records.', style: TextStyle(fontSize: 12, color: ProkColors.success))
            else
              ...students.take(10).map((item) {
                final student = Map<String, dynamic>.from(item as Map);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    CircleAvatar(radius: 15, backgroundColor: ProkColors.errorSurface,
                      child: Text((student['student_name'] ?? 'S').toString().isNotEmpty ? (student['student_name'] ?? 'S').toString()[0].toUpperCase() : 'S',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: ProkColors.error)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text((student['student_name'] ?? student['student_id'] ?? 'Unknown student').toString(),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ProkColors.neutral800)),
                      Text((student['student_id'] ?? '').toString(), style: const TextStyle(fontSize: 10, color: ProkColors.neutral400)),
                    ])),
                    Text((student['overall_attendance'] ?? 0).toString() + '%',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: ProkColors.error)),
                  ]),
                );
              }),
            if (students.length > 10)
              Text('Showing 10 of ' + students.length.toString() + ' students below 75%.',
                style: const TextStyle(fontSize: 11, color: ProkColors.neutral400)),
          ],
        ]),
      ),
    );
  }
}
