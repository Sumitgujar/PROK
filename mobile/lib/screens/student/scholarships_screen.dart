import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prok_mobile/theme/app_theme.dart';
import 'package:prok_mobile/providers/scholarship_provider.dart';
import 'package:prok_mobile/providers/attendance_provider.dart';
import 'package:prok_mobile/models/scholarship_model.dart';
import 'package:prok_mobile/widgets/loading_widget.dart';
import 'package:prok_mobile/widgets/error_state_widget.dart';
import 'package:prok_mobile/widgets/empty_state_widget.dart';

class StudentScholarshipsScreen extends StatefulWidget {
  const StudentScholarshipsScreen({super.key});
  @override
  State<StudentScholarshipsScreen> createState() => _StudentScholarshipsScreenState();
}

class _StudentScholarshipsScreenState extends State<StudentScholarshipsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  String _query = '';
  String? _applyingId;
  String? _actionError;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    Future.microtask(() => context.read<ScholarshipProvider>().load());
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _apply(ScholarshipModel scholarship) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apply for scholarship?'),
        content: Text('Submit an application for ' + scholarship.name + '? You can check the status in My Applications.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Submit application')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() { _applyingId = scholarship.id; _actionError = null; });
    try {
      await context.read<ScholarshipProvider>().apply(scholarship.id);
      if (!mounted) return;
      _tabs.animateTo(1);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Application submitted successfully.'),
        backgroundColor: ProkColors.success,
      ));
    } catch (error) {
      if (!mounted) return;
      setState(() => _actionError = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _applyingId = null);
    }
  }

  void _details(ScholarshipModel scholarship) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: SingleChildScrollView(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(scholarship.provider.isEmpty ? 'Scholarship' : scholarship.provider,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ProkColors.primary)),
            const SizedBox(height: 6),
            Text(scholarship.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: ProkColors.neutral900)),
            const SizedBox(height: 12),
            Text(scholarship.currency + ' ' + scholarship.amount.toStringAsFixed(0),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: ProkColors.success)),
            const SizedBox(height: 12),
            if (scholarship.description.isNotEmpty) Text(scholarship.description, style: const TextStyle(fontSize: 13, height: 1.5, color: ProkColors.neutral600)),
            if (scholarship.eligibility.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text('Eligibility', style: TextStyle(fontWeight: FontWeight.w700, color: ProkColors.neutral900)),
              const SizedBox(height: 4),
              Text(scholarship.eligibility, style: const TextStyle(fontSize: 13, height: 1.5, color: ProkColors.neutral600)),
            ],
            if (scholarship.minCgpa != null || scholarship.deadline != null) ...[
              const SizedBox(height: 14),
              if (scholarship.minCgpa != null) _InfoRow(label: 'Minimum CGPA', value: scholarship.minCgpa!.toStringAsFixed(2)),
              if (scholarship.deadline != null && scholarship.deadline!.isNotEmpty)
                _InfoRow(label: 'Deadline', value: scholarship.deadline!),
            ],
            if (scholarship.requiredDocTypes.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text('Required documents', style: TextStyle(fontWeight: FontWeight.w700, color: ProkColors.neutral900)),
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 4, children: scholarship.requiredDocTypes.map((item) => Chip(label: Text(item), visualDensity: VisualDensity.compact)).toList()),
            ],
          ],
        )),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ScholarshipProvider>();
    final query = _query.trim().toLowerCase();
    final available = p.scholarships.where((s) =>
      !p.appliedIds.contains(s.id) &&
      (query.isEmpty || s.name.toLowerCase().contains(query) ||
        s.provider.toLowerCase().contains(query) ||
        s.description.toLowerCase().contains(query) ||
        s.eligibility.toLowerCase().contains(query))).toList();
    final apps = p.applications.where((a) =>
      query.isEmpty || a.scholarshipName.toLowerCase().contains(query) ||
      a.status.toLowerCase().contains(query) ||
      a.missingDocs.any((item) => item.toLowerCase().contains(query))).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scholarships'),
        actions: [IconButton(tooltip: 'Refresh scholarships', icon: const Icon(Icons.refresh_rounded), onPressed: () => context.read<ScholarshipProvider>().load())],
        bottom: TabBar(
          controller: _tabs, labelColor: ProkColors.primary,
          unselectedLabelColor: ProkColors.neutral400, indicatorColor: ProkColors.primary,
          tabs: [
            const Tab(text: 'Explore'),
            Tab(text: 'My Applications (' + p.applications.length.toString() + ')'),
          ],
        ),
      ),
      body: p.state == ProviderState.loading && p.scholarships.isEmpty && p.applications.isEmpty
        ? const LoadingWidget(message: 'Finding scholarships…')
        : p.state == ProviderState.error && p.scholarships.isEmpty && p.applications.isEmpty
          ? ErrorStateWidget(error: p.error ?? 'Scholarships could not be loaded.', onRetry: () => context.read<ScholarshipProvider>().load())
          : Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search_rounded),
                    hintText: 'Search scholarships or eligibility',
                    filled: true, fillColor: ProkColors.white,
                    border: OutlineInputBorder(borderRadius: ProkRadius.md, borderSide: BorderSide(color: ProkColors.neutral200)),
                  ),
                ),
              ),
              if (_actionError != null) Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity, padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: ProkColors.errorSurface, borderRadius: ProkRadius.md),
                  child: Text(_actionError!, style: const TextStyle(fontSize: 12, color: ProkColors.error)),
                ),
              ),
              Expanded(child: TabBarView(controller: _tabs, children: [
                available.isEmpty
                  ? ListView(children: const [
                      SizedBox(height: 55),
                      EmptyStateWidget(title: 'No scholarships available', subtitle: 'Try another search or review My Applications.', icon: Icons.school_outlined),
                    ])
                  : RefreshIndicator(
                      color: ProkColors.primary,
                      onRefresh: () => context.read<ScholarshipProvider>().load(),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: available.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final s = available[index];
                          return _ScholarshipCard(
                            scholarship: s,
                            busy: _applyingId == s.id,
                            onDetails: () => _details(s),
                            onApply: () => _apply(s),
                          );
                        },
                      ),
                    ),
                apps.isEmpty
                  ? ListView(children: const [
                      SizedBox(height: 55),
                      EmptyStateWidget(title: 'No applications yet', subtitle: 'Open Explore to find a scholarship.', icon: Icons.assignment_outlined),
                    ])
                  : RefreshIndicator(
                      color: ProkColors.primary,
                      onRefresh: () => context.read<ScholarshipProvider>().load(),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: apps.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final app = apps[index];
                          return ProkCard(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Expanded(child: Text(app.scholarshipName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ProkColors.neutral900))),
                                StatusBadge(status: app.status),
                              ]),
                              const SizedBox(height: 5),
                              Text('Applied ' + (app.appliedAt.isEmpty ? 'date unavailable' : app.appliedAt.substring(0, 10)),
                                  style: const TextStyle(fontSize: 11, color: ProkColors.neutral400)),
                              if (app.missingDocs.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                const Text('Documents to check', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ProkColors.error)),
                                const SizedBox(height: 5),
                                Wrap(spacing: 6, runSpacing: 4, children: app.missingDocs.map((d) => Chip(label: Text(d), visualDensity: VisualDensity.compact, backgroundColor: ProkColors.errorSurface)).toList()),
                              ],
                              if ((app.reviewNote ?? '').isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text('Review note: ' + app.reviewNote!, style: const TextStyle(fontSize: 12, height: 1.5, color: ProkColors.neutral600)),
                              ],
                            ],
                          ));
                        },
                      ),
                    ),
              ])),
            ]),
    );
  }
}

class _ScholarshipCard extends StatelessWidget {
  final ScholarshipModel scholarship;
  final bool busy;
  final VoidCallback onDetails, onApply;
  const _ScholarshipCard({required this.scholarship, required this.busy, required this.onDetails, required this.onApply});

  @override
  Widget build(BuildContext context) => ProkCard(child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 42, height: 42, decoration: const BoxDecoration(color: ProkColors.warningSurface, borderRadius: ProkRadius.md),
          child: const Icon(Icons.school_outlined, color: ProkColors.warning, size: 21)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(scholarship.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: ProkColors.neutral900)),
          const SizedBox(height: 3),
          Text(scholarship.provider, style: const TextStyle(fontSize: 12, color: ProkColors.neutral400)),
        ])),
        const SizedBox(width: 8),
        Text(scholarship.currency + ' ' + scholarship.amount.toStringAsFixed(0),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: ProkColors.success)),
      ]),
      if (scholarship.description.isNotEmpty) ...[
        const SizedBox(height: 10),
        Text(scholarship.description, maxLines: 3, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, height: 1.5, color: ProkColors.neutral600)),
      ],
      if (scholarship.deadline != null && scholarship.deadline!.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text('Deadline: ' + scholarship.deadline!, style: const TextStyle(fontSize: 11, color: ProkColors.neutral400)),
      ],
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: OutlinedButton(onPressed: onDetails, child: const Text('Details'))),
        const SizedBox(width: 8),
        Expanded(child: ElevatedButton(onPressed: busy ? null : onApply, child: Text(busy ? 'Submitting…' : 'Apply'))),
      ]),
    ],
  ));
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      SizedBox(width: 110, child: Text(label, style: const TextStyle(fontSize: 12, color: ProkColors.neutral400))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ProkColors.neutral800))),
    ]),
  );
}
