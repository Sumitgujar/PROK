
import 'package:flutter/material.dart';
import 'package:prok_mobile/theme/app_theme.dart';
import 'package:prok_mobile/services/api_service.dart';
import 'package:prok_mobile/widgets/loading_widget.dart';
import 'package:prok_mobile/widgets/error_state_widget.dart';
import 'package:prok_mobile/widgets/empty_state_widget.dart';
import 'package:prok_mobile/widgets/stat_card.dart';

class MarkAttendanceScreen extends StatefulWidget {
  const MarkAttendanceScreen({super.key});
  @override State<MarkAttendanceScreen> createState() => _MAState();
}

class _MAState extends State<MarkAttendanceScreen> {
  List<Map<String, dynamic>> _students = [];
  Map<String, String> _marks = {};
  bool _loading = true, _saving = false;
  String? _error;
  Map<String, dynamic>? _course;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _course = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _load();
  }

  Future<void> _load() async {
    final id = _course?['_id'] ?? _course?['course_id'] ?? _course?['id'] ?? '';
    setState(() { _loading = true; _error = null; });
    try {
      final d = await ApiService().get('/attendance/courses/\$id/students');
      final raw = d is List ? d : (d as Map)['students'] ?? [];
      _students = List<Map<String, dynamic>>.from(raw as List);
      for (final s in _students) {
        _marks[s['student_id'] ?? s['college_id'] ?? ''] = 'present';
      }
      setState(() => _loading = false);
    } catch (e) {
      setState(() { _loading = false; _error = e.toString().replaceAll('Exception: ', ''); });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final id = _course?['_id'] ?? _course?['course_id'] ?? _course?['id'] ?? '';
      final records = _marks.entries.map((e) => {'student_id': e.key, 'status': e.value}).toList();
      await ApiService().post('/attendance/mark', {'course_id': id, 'records': records});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendance saved'), backgroundColor: ProkColors.success));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: ProkColors.error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('Mark Attendance — \${_course?["course_code"] ?? ""}'),
      actions: [
        TextButton(onPressed: () { for (final s in _students) { _marks[s['student_id'] ?? s['college_id'] ?? ''] = 'present'; } setState(() {}); }, child: const Text('All P')),
        TextButton(onPressed: () { for (final s in _students) { _marks[s['student_id'] ?? s['college_id'] ?? ''] = 'absent'; } setState(() {}); }, child: const Text('All A')),
      ],
    ),
    body: _loading ? const LoadingWidget()
      : _error != null ? ErrorStateWidget(error: _error!, onRetry: _load)
      : _students.isEmpty ? const EmptyStateWidget(title: 'No students enrolled', icon: Icons.people_outline)
      : Column(children: [
          Container(color: ProkColors.primarySurface, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              const Expanded(child: Text('P = Present  L = Late  A = Absent', style: TextStyle(fontSize: 12, color: ProkColors.primary))),
              Text('\${_marks.values.where((v) => v == "present").length}/\${_students.length}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ProkColors.primary)),
            ])),
          Expanded(child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _students.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (_, i) {
              final s = _students[i];
              final sid = s['student_id'] ?? s['college_id'] ?? '';
              return ProkCard(child: Row(children: [
                CircleAvatar(radius: 16, backgroundColor: ProkColors.neutral100,
                  child: Text((s['full_name'] ?? 'S')[0].toUpperCase(),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ProkColors.neutral600))),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s['full_name'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ProkColors.neutral900)),
                  Text(s['college_id'] ?? '', style: const TextStyle(fontSize: 11, color: ProkColors.neutral400)),
                ])),
                _AttToggle(value: _marks[sid] ?? 'present', onChanged: (v) => setState(() => _marks[sid] = v)),
              ]));
            },
          )),
          Padding(padding: const EdgeInsets.all(16), child: ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save Attendance'),
          )),
        ]),
  );
}

class _AttToggle extends StatelessWidget {
  final String value; final ValueChanged<String> onChanged;
  const _AttToggle({required this.value, required this.onChanged});
  @override Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    _TBtn(label: 'P', active: value == 'present', color: ProkColors.success, onTap: () => onChanged('present')),
    const SizedBox(width: 4),
    _TBtn(label: 'L', active: value == 'late', color: ProkColors.warning, onTap: () => onChanged('late')),
    const SizedBox(width: 4),
    _TBtn(label: 'A', active: value == 'absent', color: ProkColors.error, onTap: () => onChanged('absent')),
  ]);
}

class _TBtn extends StatelessWidget {
  final String label; final bool active; final Color color; final VoidCallback onTap;
  const _TBtn({required this.label, required this.active, required this.color, required this.onTap});
  @override Widget build(BuildContext context) => GestureDetector(onTap: onTap,
    child: Container(width: 32, height: 32,
      decoration: BoxDecoration(color: active ? color : ProkColors.neutral100, borderRadius: ProkRadius.sm),
      child: Center(child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: active ? Colors.white : ProkColors.neutral400)))));
}
