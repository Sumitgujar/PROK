import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prok_mobile/theme/app_theme.dart';
import 'package:prok_mobile/providers/scholarship_provider.dart';
import 'package:prok_mobile/widgets/loading_widget.dart';
import 'package:prok_mobile/widgets/error_state_widget.dart';
import 'package:prok_mobile/widgets/empty_state_widget.dart';
import 'package:prok_mobile/widgets/stat_card.dart';
class StudentScholarshipsScreen extends StatefulWidget {
  const StudentScholarshipsScreen({super.key});
  @override State<StudentScholarshipsScreen> createState() => _Sch();
}
class _Sch extends State<StudentScholarshipsScreen> with SingleTickerProviderStateMixin {
  late TabController _t;
  @override void initState() { super.initState(); _t = TabController(length: 2, vsync: this); Future.microtask(() { context.read<ScholarshipProvider>().fetchScholarships(); context.read<ScholarshipProvider>().fetchMyApplications(); }); }
  @override void dispose() { _t.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    final p = context.watch<ScholarshipProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Scholarships'), bottom: TabBar(controller: _t, labelColor: ProkColors.primary, unselectedLabelColor: ProkColors.neutral400, indicatorColor: ProkColors.primary,
        tabs: const [Tab(text: 'Available'), Tab(text: 'My Applications')])),
      body: p.state == ProviderState.loading ? const LoadingWidget()
        : p.state == ProviderState.error ? ErrorStateWidget(error: p.error ?? 'Error', onRetry: () => context.read<ScholarshipProvider>().fetchScholarships())
        : TabBarView(controller: _t, children: [_Catalogue(p: p), _Applications(p: p)]));
  }
}
class _Catalogue extends StatelessWidget {
  final ScholarshipProvider p;
  const _Catalogue({required this.p});
  @override Widget build(BuildContext context) {
    if (p.scholarships.isEmpty) return const EmptyStateWidget(title: 'No scholarships available', icon: Icons.school_outlined);
    return ListView.separated(padding: const EdgeInsets.all(16), itemCount: p.scholarships.length, separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) { final s = p.scholarships[i]; return ProkCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Text(s.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ProkColors.neutral900))),
          if (s.amount != null) Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: const BoxDecoration(color: ProkColors.warningSurface, borderRadius: ProkRadius.full),
            child: Text('\$${s.amount}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ProkColors.warning)))]),
        if (s.provider != null) Text(s.provider!, style: const TextStyle(fontSize: 12, color: ProkColors.neutral400)),
        if (s.description != null) ...[ const SizedBox(height: 6), Text(s.description!, style: const TextStyle(fontSize: 13, color: ProkColors.neutral600), maxLines: 2, overflow: TextOverflow.ellipsis)],
        const SizedBox(height: 10),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () async {
          await context.read<ScholarshipProvider>().applyForScholarship(s.id);
          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Application submitted')));
        }, style: ElevatedButton.styleFrom(minimumSize: const Size(0, 40)), child: const Text('Apply'))),
      ])); });
  }
}
class _Applications extends StatelessWidget {
  final ScholarshipProvider p;
  const _Applications({required this.p});
  @override Widget build(BuildContext context) {
    if (p.myApplications.isEmpty) return const EmptyStateWidget(title: 'No applications yet', subtitle: 'Apply from Available tab', icon: Icons.assignment_outlined);
    return ListView.separated(padding: const EdgeInsets.all(16), itemCount: p.myApplications.length, separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) { final a = p.myApplications[i]; return ProkCard(child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(a['scholarship_name'] ?? a['scholarship_id'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ProkColors.neutral900)),
          Text('Applied \${(a['applied_at'] ?? '').toString().substring(0, 10)}', style: const TextStyle(fontSize: 12, color: ProkColors.neutral400)),
        ])),
        StatusBadge(status: a['status'] ?? 'PENDING'),
      ])); });
  }
}
