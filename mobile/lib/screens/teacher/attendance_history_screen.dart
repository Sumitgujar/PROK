import 'package:flutter/material.dart';
import 'package:prok_mobile/theme/app_theme.dart';
import 'package:prok_mobile/services/api_service.dart';
import 'package:prok_mobile/widgets/loading_widget.dart';
import 'package:prok_mobile/widgets/error_state_widget.dart';
import 'package:prok_mobile/widgets/empty_state_widget.dart';
import 'package:prok_mobile/widgets/stat_card.dart';
class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});
  @override State<AttendanceHistoryScreen> createState() => _AH();
}
class _AH extends State<AttendanceHistoryScreen> {
  List _sessions = []; bool _loading = true; String? _error; Map? _course;
  final Set<String> _expanded = {};
  @override void didChangeDependencies() { super.didChangeDependencies(); _course = ModalRoute.of(context)?.settings.arguments as Map?; _load(); }
  Future<void> _load() async {
    final id = _course?['course_id'] ?? _course?['id'] ?? '';
    setState(() { _loading = true; _error = null; });
    try { final d = await ApiService().get('/attendance/course/\$id/history'); _sessions = (d['sessions'] ?? []) as List; setState(() => _loading = false); }
    catch (e) { setState(() { _loading = false; _error = e.toString().replaceAll('Exception: ', ''); }); }
  }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('History - \${_course?["course_code"] ?? ""}')),
    body: _loading ? const LoadingWidget() : _error != null ? ErrorStateWidget(error: _error!, onRetry: _load)
      : _sessions.isEmpty ? const EmptyStateWidget(title: 'No sessions yet', icon: Icons.history_rounded)
      : ListView.separated(padding: const EdgeInsets.all(16), itemCount: _sessions.length, separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final s = _sessions[i]; final sid = (s['session_id'] ?? s['_id'] ?? i).toString();
          final records = (s['records'] ?? []) as List; final isOpen = _expanded.contains(sid);
          return ProkCard(padding: EdgeInsets.zero, child: Column(children: [
            ListTile(contentPadding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
              title: Text(s['date']?.toString().substring(0, 10) ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ProkColors.neutral900)),
              subtitle: Text('\${records.length} students - \${records.where((r) => r["status"] == "PRESENT").length} present', style: const TextStyle(fontSize: 12, color: ProkColors.neutral400)),
              trailing: Icon(isOpen ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: ProkColors.neutral400),
              onTap: () => setState(() => isOpen ? _expanded.remove(sid) : _expanded.add(sid))),
            if (isOpen) ...[ const Divider(height: 1), ...records.map((r) => ListTile(dense: true,
              leading: StatusBadge(status: r['status'] ?? 'ABSENT'),
              title: Text(r['student_name'] ?? r['student_id'] ?? '', style: const TextStyle(fontSize: 13, color: ProkColors.neutral800))))],
          ]));
        }),
  );
}
