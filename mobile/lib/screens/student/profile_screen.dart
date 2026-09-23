import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prok_mobile/theme/app_theme.dart';
import 'package:prok_mobile/providers/auth_provider.dart';
import 'package:prok_mobile/widgets/stat_card.dart';
class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({super.key});
  @override Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(appBar: AppBar(title: const Text('Profile')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Center(child: Column(children: [
          CircleAvatar(radius: 36, backgroundColor: ProkColors.primarySurface,
            child: Text(user?.fullName.isNotEmpty == true ? user!.fullName[0].toUpperCase() : 'S', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: ProkColors.primary))),
          const SizedBox(height: 10),
          Text(user?.fullName ?? 'Student', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: ProkColors.neutral900)),
          Text(user?.email ?? '', style: const TextStyle(fontSize: 13, color: ProkColors.neutral400)),
        ])),
        const SizedBox(height: 20),
        ProkCard(child: Column(children: [
          InfoRow(label: 'Full Name', value: user?.fullName ?? '-'), const Divider(height: 16),
          InfoRow(label: 'Email', value: user?.email ?? '-'), const Divider(height: 16),
          InfoRow(label: 'College ID', value: user?.collegeId ?? '-'), const Divider(height: 16),
          InfoRow(label: 'Department', value: user?.department ?? '-'), const Divider(height: 16),
          InfoRow(label: 'Semester', value: user?.semester?.toString() ?? '-'),
        ])),
        const SizedBox(height: 24),
        OutlinedButton(onPressed: () async {
          final ok = await showDialog<bool>(context: context,
            builder: (_) => AlertDialog(title: const Text('Sign out?'), content: const Text('You will need to sign in again.'),
              actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sign Out'))]));
          if (ok == true && context.mounted) context.read<AuthProvider>().logout();
        }, style: OutlinedButton.styleFrom(foregroundColor: ProkColors.error, side: const BorderSide(color: ProkColors.error), minimumSize: const Size(double.infinity, 48)), child: const Text('Sign Out')),
      ]));
  }
}
