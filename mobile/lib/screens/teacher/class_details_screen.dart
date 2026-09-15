import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prok_mobile/providers/attendance_provider.dart';
import 'package:prok_mobile/widgets/loading_widget.dart';

class ClassDetailsScreen extends StatefulWidget {
  const ClassDetailsScreen({super.key});
  @override State<ClassDetailsScreen> createState() => _State();
}

class _State extends State<ClassDetailsScreen> {
  Map<String, dynamic>? _course;

  @override void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _course = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (_course != null)
        context.read<AttendanceProvider>().loadEnrolledStudents(_course!['_id']);
    });
  }

  @override Widget build(BuildContext context) {
    final prov = context.watch<AttendanceProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(_course?['title'] ?? 'Class Details'),
        subtitle: Text(_course?['course_code'] ?? ''),
        actions: [
          IconButton(
            icon: const Icon(Icons.how_to_reg),
            tooltip: 'Mark Attendance',
            onPressed: () => Navigator.pushNamed(
                context, '/teacher/mark-attendance', arguments: _course)),
        ],
      ),
      body: prov.isLoading
          ? const LoadingWidget()
          : ListView(padding: const EdgeInsets.all(16), children: [
              Card(
                color: const Color(0xFF1E3A8A),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_course?['title'] ?? '',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(_course?['course_code'] ?? '',
                        style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 12),
                    Row(children: [
                      _Stat('Credits', '${_course?["credits"] ?? "-"}'),
                      const SizedBox(width: 24),
                      _Stat('Students', '${prov.enrolledStudents.length}'),
                      const SizedBox(width: 24),
                      _Stat('Department', _course?['department'] ?? '-'),
                    ]),
                  ])),
              ),
              const SizedBox(height: 12),
              const Text('Enrolled Students',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              if (prov.enrolledStudents.isEmpty)
                const Center(child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('No students enrolled yet.', style: TextStyle(color: Colors.grey))))
              else
                ...prov.enrolledStudents.map((s) => Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                        backgroundColor: const Color(0xFFEEF2FF),
                        child: Text((s['full_name'] ?? 'S').substring(0, 1),
                            style: const TextStyle(color: Color(0xFF1E3A8A)))),
                    title: Text(s['full_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(s['college_id'] ?? ''),
                    trailing: Text(s['email'] ?? '', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ))),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.history),
                label: const Text('View Attendance History'),
                onPressed: () => Navigator.pushNamed(
                    context, '/teacher/attendance-history', arguments: _course),
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
              ),
            ]),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  const _Stat(this.label, this.value);
  @override Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
      Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    ]);
}
