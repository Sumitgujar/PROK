import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prok_mobile/core/constants.dart';
import 'package:prok_mobile/providers/auth_provider.dart';
import 'package:prok_mobile/providers/course_provider.dart';
import 'package:prok_mobile/widgets/loading_widget.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});
  @override State<StudentProfileScreen> createState() => _State();
}

class _State extends State<StudentProfileScreen> {
  @override void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<CourseProvider>().loadProfile());
  }

  @override Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final prov = context.watch<CourseProvider>();
    final user = auth.user;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              if (context.mounted)
                Navigator.pushReplacementNamed(context, AppRoutes.login);
            }),
        ],
      ),
      body: prov.isLoading
          ? const LoadingWidget()
          : ListView(padding: const EdgeInsets.all(16), children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: const Color(0xFF1E3A8A),
                      child: Text(
                          user?.fullName.isNotEmpty == true
                              ? user!.fullName[0].toUpperCase()
                              : 'S',
                          style: const TextStyle(fontSize: 32, color: Colors.white))),
                    const SizedBox(height: 12),
                    Text(user?.fullName ?? '',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(user?.email ?? '', style: const TextStyle(color: Colors.grey)),
                    if (user?.collegeId != null)
                      Text('ID: ${user!.collegeId}',
                          style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ]))),
              const SizedBox(height: 12),
              if (prov.profile != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Academic Info',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      _InfoRow('Department', prov.profile!.department),
                      _InfoRow('Semester', '${prov.profile!.semester}'),
                      _InfoRow('Year', '${prov.profile!.year}'),
                      if (prov.profile!.cgpa != null)
                        _InfoRow('CGPA', prov.profile!.cgpa!.toStringAsFixed(2)),
                    ]))),
                const SizedBox(height: 8),
                if (prov.profile!.skills.isNotEmpty)
                  _ChipsCard('Skills', prov.profile!.skills, Colors.blue),
                if (prov.profile!.interests.isNotEmpty)
                  _ChipsCard('Interests', prov.profile!.interests, Colors.green),
                if (prov.profile!.careerGoals.isNotEmpty)
                  _ChipsCard('Career Goals', prov.profile!.careerGoals, Colors.purple),
              ],
            ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow(this.label, this.value);
  @override Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      Text('$label: ', style: const TextStyle(color: Colors.grey)),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
    ]));
}

Widget _ChipsCard(String title, List<String> items, Color color) => Card(
  margin: const EdgeInsets.only(bottom: 8),
  child: Padding(
    padding: const EdgeInsets.all(14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 6, runSpacing: 4,
        children: items.map((s) => Chip(
          label: Text(s, style: const TextStyle(fontSize: 12)),
          backgroundColor: color.withOpacity(0.1),
          side: BorderSide(color: color.withOpacity(0.3)),
        )).toList()),
    ])));
