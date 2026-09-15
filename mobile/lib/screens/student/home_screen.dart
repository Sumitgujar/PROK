import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prok_mobile/core/constants.dart';
import 'package:prok_mobile/providers/auth_provider.dart';
import 'package:prok_mobile/services/api_service.dart';
import 'package:prok_mobile/widgets/loading_widget.dart';
import 'package:prok_mobile/widgets/error_state_widget.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});
  @override State<StudentHomeScreen> createState() => _State();
}

class _State extends State<StudentHomeScreen> {
  Map<String, dynamic>? _d;
  bool _loading = true;
  String? _error;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      _d = await ApiService().get('/dashboard/student');
      setState(() => _loading = false);
    } catch (e) {
      setState(() { _loading = false; _error = e.toString().replaceAll('Exception: ', ''); });
    }
  }

  @override Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      body: SafeArea(
        child: _loading
            ? const LoadingWidget(message: 'Loading dashboard...')
            : _error != null
                ? ErrorStateWidget(error: _error!, onRetry: _load)
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(padding: const EdgeInsets.all(16), children: [
                      Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Hello, ${user?.fullName.split(' ').first ?? 'Student'}!',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          const Text('Your academic overview', style: TextStyle(color: Colors.grey)),
                        ])),
                        Stack(children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_outlined),
                            onPressed: () => Navigator.pushNamed(context, AppRoutes.studentNotifications)),
                          if ((_d?['notifications']?['unread_count'] ?? 0) > 0)
                            Positioned(right: 6, top: 6, child: Container(width: 8, height: 8,
                                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))),
                        ]),
                      ]),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Ask PROK AI -- coming soon!'))),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)]),
                            borderRadius: BorderRadius.circular(12)),
                          child: const Row(children: [
                            Icon(Icons.auto_awesome, color: Colors.white, size: 28),
                            SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Ask PROK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              Text('AI-powered academic help', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            ])),
                            Icon(Icons.chevron_right, color: Colors.white),
                          ])),
                      ),
                      const SizedBox(height: 16),
                      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Row(children: [
                            Icon(Icons.fact_check_outlined, color: Color(0xFF1E3A8A)),
                            SizedBox(width: 6),
                            Text('Attendance', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                          ]),
                          const SizedBox(height: 8),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            const Text('Overall'),
                            Text('${_d?['attendance']?['overall_percentage'] ?? 0}%',
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                          ]),
                          ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(
                            value: ((_d?['attendance']?['overall_percentage'] ?? 0) as num) / 100,
                            minHeight: 8, backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation(
                              ((_d?['attendance']?['overall_percentage'] ?? 0) as num) >= 75 ? Colors.green : Colors.red))),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, AppRoutes.studentAttendance),
                            child: const Text('View details ->', style: TextStyle(color: Color(0xFF1E3A8A), fontSize: 12))),
                        ]))),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: _MiniCard(
                          title: 'Documents',
                          value: '${_d?['documents']?['verified'] ?? 0}/${_d?['documents']?['total'] ?? 0}',
                          subtitle: 'verified',
                          icon: Icons.folder_outlined, color: Colors.green,
                          onTap: () => Navigator.pushNamed(context, AppRoutes.studentDocuments))),
                        const SizedBox(width: 10),
                        Expanded(child: _MiniCard(
                          title: 'Scholarships',
                          value: '${_d?['scholarships']?['available'] ?? 0}',
                          subtitle: 'available',
                          icon: Icons.monetization_on_outlined, color: Colors.amber,
                          onTap: () => Navigator.pushNamed(context, AppRoutes.studentScholarships))),
                      ]),
                      const SizedBox(height: 10),
                      if ((_d?['courses']?['recommendations'] as List?)?.isNotEmpty == true) ...[
                        const Text('Recommended Courses', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 8),
                        ...(_d!['courses']['recommendations'] as List).take(3).map((c) =>
                          Card(margin: const EdgeInsets.only(bottom: 6), child: ListTile(
                            leading: const CircleAvatar(backgroundColor: Color(0xFFEEF2FF),
                              child: Icon(Icons.school, color: Color(0xFF1E3A8A), size: 18)),
                            title: Text(c['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            subtitle: Text(c['course_code'] ?? ''),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.pushNamed(context, AppRoutes.studentCourses)))),
                      ],
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: _QuickBtn(label: 'Profile', icon: Icons.person_outline, route: AppRoutes.studentProfile)),
                        const SizedBox(width: 10),
                        Expanded(child: _QuickBtn(label: 'Notifications', icon: Icons.notifications_outlined, route: AppRoutes.studentNotifications)),
                      ]),
                      const SizedBox(height: 16),
                    ]),
                  ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: const Color(0xFF1E3A8A),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.fact_check), label: 'Attendance'),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Docs'),
          BottomNavigationBarItem(icon: Icon(Icons.monetization_on), label: 'Scholarships'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Courses'),
        ],
        onTap: (i) {
          final routes = ['', AppRoutes.studentAttendance, AppRoutes.studentDocuments,
              AppRoutes.studentScholarships, AppRoutes.studentCourses];
          if (i > 0) Navigator.pushNamed(context, routes[i]);
        },
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final String title, value, subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _MiniCard({required this.title, required this.value, required this.subtitle,
      required this.icon, required this.color, required this.onTap});
  @override Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ]))));
}

class _QuickBtn extends StatelessWidget {
  final String label, route;
  final IconData icon;
  const _QuickBtn({required this.label, required this.icon, required this.route});
  @override Widget build(BuildContext context) => GestureDetector(
    onTap: () => Navigator.pushNamed(context, route),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: const Color(0xFF1E3A8A), size: 18),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.w600)),
      ])));
}
