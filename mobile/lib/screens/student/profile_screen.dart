import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prok_mobile/core/constants.dart';
import 'package:prok_mobile/theme/app_theme.dart';
import 'package:prok_mobile/providers/auth_provider.dart';
import 'package:prok_mobile/providers/course_provider.dart';
import 'package:prok_mobile/providers/attendance_provider.dart';
import 'package:prok_mobile/models/course_model.dart';
import 'package:prok_mobile/widgets/loading_widget.dart';
import 'package:prok_mobile/widgets/error_state_widget.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});
  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<CourseProvider>().loadProfile());
  }

  Future<void> _editAcademicInterests(StudentProfile? profile) async {
    final skills = TextEditingController(text: (profile?.skills ?? []).join(', '));
    final interests = TextEditingController(text: (profile?.interests ?? []).join(', '));
    final goals = TextEditingController(text: (profile?.careerGoals ?? []).join(', '));
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Academic interests'),
        content: SingleChildScrollView(child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Separate items with commas. These details help PROK personalize course and scholarship guidance.',
              style: TextStyle(fontSize: 12, height: 1.5, color: ProkColors.neutral600)),
            const SizedBox(height: 14),
            _ProfileField(label: 'Skills', hint: 'Python, communication', controller: skills),
            const SizedBox(height: 12),
            _ProfileField(label: 'Interests', hint: 'AI, cloud computing', controller: interests),
            const SizedBox(height: 12),
            _ProfileField(label: 'Career goals', hint: 'Cloud engineer, data analyst', controller: goals),
          ],
        )),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, {
              'skills': skills.text,
              'interests': interests.text,
              'goals': goals.text,
            }),
            child: const Text('Save profile'),
          ),
        ],
      ),
    );
    skills.dispose();
    interests.dispose();
    goals.dispose();
    if (result == null || !mounted) return;

    List<String> parse(String value) => value.split(',').map((item) => item.trim()).where((item) => item.isNotEmpty).toSet().toList();
    setState(() => _saving = true);
    try {
      await context.read<CourseProvider>().updateProfile(
        skills: parse(result['skills'] ?? ''),
        interests: parse(result['interests'] ?? ''),
        careerGoals: parse(result['goals'] ?? ''),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Profile interests saved.'),
        backgroundColor: ProkColors.success,
      ));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error.toString().replaceFirst('Exception: ', '')),
        backgroundColor: ProkColors.error,
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to sign in again to access PROK.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sign out')),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final provider = context.watch<CourseProvider>();
    final profile = provider.profile;
    final name = user?.fullName.isNotEmpty == true ? user!.fullName : 'Student';
    final initials = name.trim().isEmpty ? 'S' : name.trim()[0].toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(tooltip: 'Refresh profile', icon: const Icon(Icons.refresh_rounded), onPressed: () => context.read<CourseProvider>().loadProfile()),
        ],
      ),
      body: provider.state == ProviderState.loading && profile == null
        ? const LoadingWidget(message: 'Loading your profile…')
        : provider.state == ProviderState.error && profile == null
          ? ErrorStateWidget(error: provider.error ?? 'Profile could not be loaded.', onRetry: () => context.read<CourseProvider>().loadProfile())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ProkCard(child: Column(children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: ProkColors.primarySurface,
                    child: Text(initials, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: ProkColors.primary)),
                  ),
                  const SizedBox(height: 12),
                  Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: ProkColors.neutral900)),
                  const SizedBox(height: 4),
                  Text(user?.email ?? '', style: const TextStyle(fontSize: 13, color: ProkColors.neutral400)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: const BoxDecoration(color: ProkColors.primarySurface, borderRadius: ProkRadius.full),
                    child: const Text('STUDENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: ProkColors.primary, letterSpacing: 1)),
                  ),
                ])),
                const SizedBox(height: 14),
                const SectionHeader(title: 'Academic details'),
                const SizedBox(height: 8),
                ProkCard(child: Column(children: [
                  _InfoRow(label: 'College ID', value: user?.collegeId ?? 'Not provided'),
                  const Divider(height: 18),
                  _InfoRow(label: 'Department', value: profile?.department ?? user?.department ?? 'Not provided'),
                  const Divider(height: 18),
                  _InfoRow(label: 'Semester', value: (profile?.semester ?? user?.semester)?.toString() ?? 'Not provided'),
                  const Divider(height: 18),
                  _InfoRow(label: 'Academic year', value: profile?.year.toString() ?? 'Not provided'),
                  const Divider(height: 18),
                  _InfoRow(label: 'CGPA', value: profile?.cgpa?.toStringAsFixed(2) ?? 'Not provided'),
                ])),
                const SizedBox(height: 14),
                const SectionHeader(title: 'Personalized guidance'),
                const SizedBox(height: 8),
                ProkCard(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Skills, interests and career goals', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: ProkColors.neutral900)),
                    const SizedBox(height: 5),
                    const Text('Keep these details current so PROK can use them when suggesting courses and scholarship opportunities.',
                      style: TextStyle(fontSize: 12, height: 1.5, color: ProkColors.neutral600)),
                    const SizedBox(height: 12),
                    _TagSection(label: 'Skills', values: profile?.skills ?? const []),
                    _TagSection(label: 'Interests', values: profile?.interests ?? const []),
                    _TagSection(label: 'Career goals', values: profile?.careerGoals ?? const []),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _saving ? null : () => _editAcademicInterests(profile),
                      icon: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.edit_outlined),
                      label: Text(_saving ? 'Saving…' : 'Edit personalized profile'),
                    ),
                  ],
                )),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ProkColors.error,
                    side: const BorderSide(color: ProkColors.error),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
                const SizedBox(height: 12),
                const Center(child: Text('PROK · MANAGE · GUIDE · SUPPORT · GROW', style: TextStyle(fontSize: 10, color: ProkColors.neutral400, letterSpacing: 0.6))),
              ],
            ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final String label, hint;
  final TextEditingController controller;
  const _ProfileField({required this.label, required this.hint, required this.controller});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      const SizedBox(height: 5),
      TextField(controller: controller, maxLines: 2, decoration: InputDecoration(hintText: hint)),
    ],
  );
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      SizedBox(width: 110, child: Text(label, style: const TextStyle(fontSize: 12, color: ProkColors.neutral400))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ProkColors.neutral800))),
    ]),
  );
}

class _TagSection extends StatelessWidget {
  final String label;
  final List<String> values;
  const _TagSection({required this.label, required this.values});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: ProkColors.neutral400)),
        const SizedBox(height: 5),
        if (values.isEmpty) const Text('Not added yet', style: TextStyle(fontSize: 12, color: ProkColors.neutral400))
        else Wrap(spacing: 6, runSpacing: 2, children: values.map((value) => Chip(label: Text(value), visualDensity: VisualDensity.compact)).toList()),
      ],
    ),
  );
}
