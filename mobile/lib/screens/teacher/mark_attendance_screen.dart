import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prok_mobile/providers/attendance_provider.dart';
import 'package:prok_mobile/widgets/loading_widget.dart';
import 'package:prok_mobile/widgets/error_state_widget.dart';

class MarkAttendanceScreen extends StatefulWidget {
  const MarkAttendanceScreen({super.key});
  @override State<MarkAttendanceScreen> createState() => _State();
}

class _State extends State<MarkAttendanceScreen> {
  Map<String, dynamic>? _course;
  Map<String, String> _marks = {}; // studentId -> 'present'|'absent'|'late'
  bool _submitting = false;
  bool _loaded = false;

  @override void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _course = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (_course != null)
        context.read<AttendanceProvider>().loadEnrolledStudents(_course!['_id']).then((_) {
          setState(() => _loaded = true);
        });
    });
  }

  Future<void> _submit() async {
    final students = context.read<AttendanceProvider>().enrolledStudents;
    final unmarked = students.where((s) => !_marks.containsKey(s['student_id'])).toList();
    if (unmarked.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please mark attendance for all students.'),
          backgroundColor: Colors.orange));
      return;
    }
    setState(() => _submitting = true);
    try {
      final records = students
          .map((s) => {'student_id': s['student_id'], 'status': _marks[s['student_id']]})
          .toList();
      await context.read<AttendanceProvider>().submitAttendance(
          courseId: _course!['_id'], records: records);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Attendance saved!'), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _submitting = false);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red));
    }
  }

  @override Widget build(BuildContext context) {
    final prov = context.watch<AttendanceProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(_course?['title'] ?? 'Mark Attendance'),
        subtitle: Text(_course?['course_code'] ?? ''),
      ),
      body: !_loaded
          ? const LoadingWidget(message: 'Loading students...')
          : prov.state == ProviderState.error
              ? ErrorStateWidget(
                  error: prov.error!,
                  onRetry: () => context
                      .read<AttendanceProvider>()
                      .loadEnrolledStudents(_course!['_id']))
              : Column(children: [
                  // Quick all-mark actions
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(children: [
                      Expanded(child: OutlinedButton(
                          onPressed: () => setState(() {
                                for (final s in prov.enrolledStudents)
                                  _marks[s['student_id']] = 'present';
                              }),
                          child: const Text('All Present'))),
                      const SizedBox(width: 8),
                      Expanded(child: OutlinedButton(
                          onPressed: () => setState(() {
                                for (final s in prov.enrolledStudents)
                                  _marks[s['student_id']] = 'absent';
                              }),
                          child: const Text('All Absent'))),
                    ]),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: prov.enrolledStudents.isEmpty
                        ? const Center(child: Text('No students enrolled'))
                        : ListView.builder(
                            itemCount: prov.enrolledStudents.length,
                            itemBuilder: (ctx, i) {
                              final s = prov.enrolledStudents[i];
                              final sid = s['student_id'] as String;
                              final mark = _marks[sid];
                              return ListTile(
                                leading: CircleAvatar(
                                    backgroundColor: mark == 'present'
                                        ? Colors.green
                                        : mark == 'absent'
                                            ? Colors.red
                                            : mark == 'late'
                                                ? Colors.orange
                                                : Colors.grey[300],
                                    child: Text(
                                        (s['full_name'] as String? ?? 'S')
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: const TextStyle(color: Colors.white))),
                                title: Text(s['full_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text(s['college_id'] ?? ''),
                                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                  _MarkBtn('P', 'present', mark, Colors.green, () => setState(() => _marks[sid] = 'present')),
                                  const SizedBox(width: 4),
                                  _MarkBtn('L', 'late', mark, Colors.orange, () => setState(() => _marks[sid] = 'late')),
                                  const SizedBox(width: 4),
                                  _MarkBtn('A', 'absent', mark, Colors.red, () => setState(() => _marks[sid] = 'absent')),
                                ]),
                              );
                            }),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _submitting ? null : _submit,
                          child: _submitting
                              ? const SizedBox(width: 20, height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text('Save Attendance (${_marks.length}/${prov.enrolledStudents.length})'),
                        ),
                      ),
                    ),
                  ),
                ]),
    );
  }
}

class _MarkBtn extends StatelessWidget {
  final String label, value;
  final String? current;
  final Color color;
  final VoidCallback onTap;
  const _MarkBtn(this.label, this.value, this.current, this.color, this.onTap);
  @override Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 30, height: 30,
      decoration: BoxDecoration(
          color: current == value ? color : Colors.grey[200],
          borderRadius: BorderRadius.circular(6)),
      alignment: Alignment.center,
      child: Text(label, style: TextStyle(
          color: current == value ? Colors.white : Colors.grey[600],
          fontWeight: FontWeight.bold, fontSize: 12))));
}
