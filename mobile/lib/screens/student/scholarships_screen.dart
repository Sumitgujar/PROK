import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prok_mobile/providers/scholarship_provider.dart';
import 'package:prok_mobile/providers/attendance_provider.dart';
import 'package:prok_mobile/models/scholarship_model.dart';
import 'package:prok_mobile/widgets/loading_widget.dart';
import 'package:prok_mobile/widgets/empty_state_widget.dart';
import 'package:prok_mobile/widgets/error_state_widget.dart';

class StudentScholarshipsScreen extends StatefulWidget {
  const StudentScholarshipsScreen({super.key});
  @override State<StudentScholarshipsScreen> createState() => _State();
}

class _State extends State<StudentScholarshipsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);

  @override void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<ScholarshipProvider>().load());
  }
  @override void dispose() { _tab.dispose(); super.dispose(); }

  void _showDetail(ScholarshipModel s, bool applied) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false, initialChildSize: 0.65,
        builder: (_, ctrl) => ListView(controller: ctrl, padding: const EdgeInsets.all(20), children: [
          Text(s.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('by ${s.provider}', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          Text('${s.currency} ${s.amount.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
          if (s.deadline != null)
            Text('Deadline: ${s.deadline!.length >= 10 ? s.deadline!.substring(0, 10) : s.deadline!}',
                style: const TextStyle(color: Colors.orange)),
          if (s.minCgpa != null) Text('Min CGPA: ${s.minCgpa}'),
          const SizedBox(height: 8),
          Text(s.description),
          if (s.eligibility.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('Eligibility', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(s.eligibility, style: const TextStyle(color: Colors.grey)),
          ],
          if (s.requiredDocTypes.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('Required Documents', style: TextStyle(fontWeight: FontWeight.bold)),
            ...s.requiredDocTypes.map((d) => Row(children: [
              const Icon(Icons.check_circle_outline, size: 14, color: Colors.green),
              const SizedBox(width: 4),
              Text(d),
            ])),
          ],
          const SizedBox(height: 16),
          if (!applied)
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await context.read<ScholarshipProvider>().apply(s.id);
                  if (mounted)
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Applied!'), backgroundColor: Colors.green));
                } catch (e) {
                  if (mounted)
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(e.toString().replaceAll('Exception: ', '')),
                        backgroundColor: Colors.red));
                }
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
              child: const Text('Apply Now'),
            )
          else
            const Center(child: Text('Already Applied',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
        ]),
      ),
    );
  }

  @override Widget build(BuildContext context) {
    final prov = context.watch<ScholarshipProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scholarships'),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.white, labelColor: Colors.white, unselectedLabelColor: Colors.white60,
          tabs: const [Tab(text: 'Available'), Tab(text: 'My Applications')],
        ),
      ),
      body: TabBarView(controller: _tab, children: [
        // Available tab
        RefreshIndicator(
          onRefresh: () => context.read<ScholarshipProvider>().load(),
          child: Builder(builder: (_) {
            if (prov.isLoading) return const LoadingWidget();
            if (prov.state == ProviderState.error)
              return ErrorStateWidget(
                  error: prov.error!, onRetry: () => context.read<ScholarshipProvider>().load());
            final available = prov.scholarships
                .where((s) => !prov.appliedIds.contains(s.id))
                .toList();
            if (available.isEmpty)
              return const EmptyStateWidget(
                  title: 'No scholarships available', icon: Icons.monetization_on_outlined);
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: available.length,
              itemBuilder: (ctx, i) {
                final s = available[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: const CircleAvatar(
                        backgroundColor: Color(0xFFFEF3C7),
                        child: Icon(Icons.monetization_on, color: Colors.amber)),
                    title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(s.provider),
                      Text('${s.currency} ${s.amount.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                    ]),
                    isThreeLine: true,
                    trailing: ElevatedButton(
                        onPressed: () => _showDetail(s, false), child: const Text('View')),
                  ),
                );
              },
            );
          }),
        ),
        // Applications tab
        RefreshIndicator(
          onRefresh: () => context.read<ScholarshipProvider>().load(),
          child: prov.applications.isEmpty
              ? const EmptyStateWidget(title: 'No applications yet', icon: Icons.assignment_outlined)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: prov.applications.length,
                  itemBuilder: (ctx, i) {
                    final app = prov.applications[i];
                    final color = app.status == 'approved'
                        ? Colors.green
                        : app.status == 'rejected'
                            ? Colors.red
                            : Colors.orange;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(app.scholarshipName,
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8)),
                            child: Text(app.status.toUpperCase(),
                                style: TextStyle(
                                    color: color, fontSize: 11, fontWeight: FontWeight.bold))),
                          if (app.reviewNote != null && app.reviewNote!.isNotEmpty)
                            Text('Note: ${app.reviewNote}',
                                style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          if (app.missingDocs.isNotEmpty)
                            Text('Missing: ${app.missingDocs.join(", ")}',
                                style: const TextStyle(color: Colors.red, fontSize: 12)),
                        ])),
                    );
                  }),
        ),
      ]),
    );
  }
}
