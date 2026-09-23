import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prok_mobile/core/constants.dart';
import 'package:prok_mobile/providers/auth_provider.dart';
import 'package:prok_mobile/services/api_service.dart';
import 'package:prok_mobile/theme/app_theme.dart';
import 'package:prok_mobile/widgets/loading_widget.dart';
import 'package:prok_mobile/widgets/error_state_widget.dart';
import 'package:prok_mobile/widgets/stat_card.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});
  @override State<StudentHomeScreen> createState() => _H();
}
class _H extends State<StudentHomeScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true; String? _error; int _tab = 0;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try { _data = await ApiService().get('/dashboard/student'); setState(() => _loading = false); }
    catch (e) { setState(() { _loading = false; _error = e.toString().replaceAll('Exception: ', ''); }); }
  }
  void _nav(int i) {
    if (i == 0) return;
    const r = ['', AppRoutes.studentAskProk, AppRoutes.studentAttendance, AppRoutes.studentDocuments, AppRoutes.studentCourses];
    Navigator.pushNamed(context, r[i]);
  }
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final att = (_data?['attendance']?['overall_percentage'] ?? 0) as num;
    final c = att >= 75 ? ProkColors.success : att >= 60 ? ProkColors.warning : ProkColors.error;
    return Scaffold(
      backgroundColor: ProkColors.neutral50,
      body: SafeArea(child: _loading ? const LoadingWidget(message: 'Loading dashboard...')
        : _error != null ? ErrorStateWidget(error: _error!, onRetry: _load)
        : RefreshIndicator(color: ProkColors.primary, onRefresh: _load, child: ListView(padding: EdgeInsets.zero, children: [
            _header(user, att, c), Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _askBanner(), const SizedBox(height: 16),
              const SectionHeader(title: 'Overview'), const SizedBox(height: 10),
              Row(children: [
                Expanded(child: StatCard(label: 'Documents', icon: Icons.folder_outlined, color: ProkColors.success,
                  value: '\${_data?["documents"]?["verified"] ?? 0}/\${_data?["documents"]?["total"] ?? 0}', sub: 'verified',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.studentDocuments))),
                const SizedBox(width: 10),
                Expanded(child: StatCard(label: 'Scholarships', icon: Icons.school_outlined, color: ProkColors.warning,
                  value: '\${_data?["scholarships"]?["available"] ?? 0}', sub: 'available',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.studentScholarships))),
              ]),
            ])),
          ])),
      ),
      bottomNavigationBar: Container(decoration: const BoxDecoration(border: Border(top: BorderSide(color: ProkColors.neutral200))),
        child: BottomNavigationBar(currentIndex: _tab, onTap: _nav, items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome_rounded), label: 'Ask PROK'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Attendance'),
          BottomNavigationBarItem(icon: Icon(Icons.folder_rounded), label: 'Docs'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_rounded), label: 'Courses'),
        ])),
    );
  }
  Widget _header(user, num att, Color c) => Container(
    color: ProkColors.white, padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Welcome back,', style: TextStyle(fontSize: 12, color: ProkColors.neutral400)),
          Text(user?.fullName.split(' ').first ?? 'Student', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: ProkColors.neutral900)),
        ]),
        const Spacer(),
        GestureDetector(onTap: () => Navigator.pushNamed(context, AppRoutes.studentNotifications),
          child: Stack(children: [
            Container(width: 40, height: 40, decoration: const BoxDecoration(color: ProkColors.neutral100, shape: BoxShape.circle),
              child: const Icon(Icons.notifications_outlined, color: ProkColors.neutral800, size: 20)),
            if ((_data?['notifications']?['unread_count'] ?? 0) > 0)
              Positioned(right: 8, top: 8, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: ProkColors.error, shape: BoxShape.circle))),
          ])),
      ]),
      const SizedBox(height: 20),
      Container(padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: ProkColors.neutral50, borderRadius: ProkRadius.lg, border: Border.all(color: ProkColors.neutral200)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('Overall Attendance', style: TextStyle(fontSize: 13, color: ProkColors.neutral600, fontWeight: FontWeight.w500)),
            const Spacer(),
            Text('\$att%', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: c)),
          ]),
          const SizedBox(height: 10),
          ClipRRect(borderRadius: ProkRadius.full, child: LinearProgressIndicator(value: att / 100, minHeight: 6, backgroundColor: ProkColors.neutral200, valueColor: AlwaysStoppedAnimation(c))),
          const SizedBox(height: 8),
          GestureDetector(onTap: () => Navigator.pushNamed(context, AppRoutes.studentAttendance),
            child: const Text('View details', style: TextStyle(fontSize: 12, color: ProkColors.primaryLight, fontWeight: FontWeight.w600))),
        ])),
    ]));
  Widget _askBanner() => GestureDetector(
    onTap: () => Navigator.pushNamed(context, AppRoutes.studentAskProk),
    child: Container(padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: ProkRadius.lg),
      child: Row(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: ProkRadius.md),
          child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22)),
        const SizedBox(width: 14),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Ask PROK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          SizedBox(height: 2),
          Text('Personalised guidance from your real data', style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 12)),
        ])),
        const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 20),
      ])));
}
