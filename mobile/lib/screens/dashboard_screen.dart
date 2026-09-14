import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../core/constants.dart';

class _Module {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;
  const _Module(this.title, this.subtitle, this.icon, this.color, this.route);
}

const _modules = [
  _Module('Attendance', 'Track student & teacher attendance',
      Icons.checklist_rtl, Color(0xFF6c63ff), AppRoutes.attendance),
  _Module('Documents', 'Upload & manage academic docs',
      Icons.folder_open, Color(0xFF2196F3), AppRoutes.documents),
  _Module('Scholarships', 'AI-matched scholarship finder',
      Icons.school, Color(0xFF4CAF50), AppRoutes.scholarships),
  _Module('Courses', 'Personalised course recommendations',
      Icons.menu_book, Color(0xFFFF9800), AppRoutes.courses),
  _Module('AI Guide', 'Your college personal assistant',
      Icons.smart_toy, Color(0xFFE91E63), AppRoutes.dashboard),
  _Module('Analytics', 'Admin dashboard & verification',
      Icons.bar_chart, Color(0xFF009688), AppRoutes.dashboard),
];

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a1a2e),
        foregroundColor: Colors.white,
        title: const Text('PROK', style: TextStyle(letterSpacing: 2)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle, color: Colors.white),
            onSelected: (v) async {
              if (v == 'logout') {
                await auth.logout();
                if (context.mounted) context.go(AppRoutes.login);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Text(user?.email ?? '', style: const TextStyle(fontSize: 12)),
              ),
              const PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome, \${user?.name ?? "User"} 👋',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text('Role: \${user?.role ?? ""}',
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                itemCount: _modules.length,
                itemBuilder: (context, i) {
                  final m = _modules[i];
                  return InkWell(
                    onTap: () => context.go(m.route),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
                        ],
                        border: Border(left: BorderSide(color: m.color, width: 4)),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(m.icon, color: m.color, size: 30),
                          const Spacer(),
                          Text(m.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(m.subtitle,
                              style: const TextStyle(color: Colors.grey, fontSize: 11),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
