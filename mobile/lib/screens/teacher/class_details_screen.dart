import 'package:flutter/material.dart';
import 'package:prok_mobile/theme/app_theme.dart';
import 'package:prok_mobile/services/api_service.dart';
import 'package:prok_mobile/widgets/loading_widget.dart';
import 'package:prok_mobile/widgets/error_state_widget.dart';
import 'package:prok_mobile/widgets/empty_state_widget.dart';
import 'package:prok_mobile/widgets/stat_card.dart';
class ClassDetailsScreen extends StatefulWidget {
  const ClassDetailsScreen({super.key});
  @override State<ClassDetailsScreen> createState() => _CD();
}
class _CD extends State<ClassDetailsScreen> {
  List _students = []; bool _loading = true; String? _error; Map? _course;
  @override void didChangeDependencies() { super.didChangeDependencies(); _course = ModalRoute.of(context)?.settings.arguments as Map?; _load(); }
  Future<void> _load() async {
    final id = _course?['course_id'] ?? _course?['id'] ?? '';
    setState(() { _loading = true; _error = null; });
    try { final d = await ApiService().get('/attendance/course/\$id/students'); _students = (d['students'] ?? []) as List; setState(() => _loading = false); }
    catch (e) { setState(() { _loading = false; _error = e.toString().replaceAll('Exception: ', ''); }); }
  }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_course?['course_title'] ?? 'Class Details')),
    body: _loading ? const LoadingWidget() : _error != null ? ErrorStateWidget(error: _error!, onRetry: _load)
      : _students.isEmpty ? const EmptyStateWidget(title: 'No students enrolled', icon: Icons.people_outline)
      : ListView.separated(padding: const EdgeInsets.all(16), itemCount: _students.length, separatorBuilder: (_, __) => const SizedBox(height: 6),
        itemBuilder: (_, i) { final s = _students[i]; return ProkCard(child: Row(children: [
          CircleAvatar(radius: 18, backgroundColor: ProkColors.primarySurface,
            child: Text((s['full_name'] ?? 'S')[0].toUpperCase(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ProkColors.primary))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s['full_name'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ProkColors.neutral900)),
            Text(s['college_id'] ?? '', style: const TextStyle(fontSize: 12, color: ProkColors.neutral400)),
          ])),
        ])); }),
  );
}
