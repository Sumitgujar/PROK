import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prok_mobile/theme/app_theme.dart';
import 'package:prok_mobile/providers/document_provider.dart';
import 'package:prok_mobile/widgets/loading_widget.dart';
import 'package:prok_mobile/widgets/error_state_widget.dart';
import 'package:prok_mobile/widgets/empty_state_widget.dart';
import 'package:prok_mobile/widgets/stat_card.dart';
class StudentDocumentsScreen extends StatefulWidget {
  const StudentDocumentsScreen({super.key});
  @override State<StudentDocumentsScreen> createState() => _D();
}
class _D extends State<StudentDocumentsScreen> with SingleTickerProviderStateMixin {
  late TabController _t;
  @override void initState() { super.initState(); _t = TabController(length: 3, vsync: this); Future.microtask(() => context.read<DocumentProvider>().fetchDocuments()); }
  @override void dispose() { _t.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    final p = context.watch<DocumentProvider>();
    final all = p.documents;
    return Scaffold(
      appBar: AppBar(title: const Text('Documents'), bottom: TabBar(controller: _t, labelColor: ProkColors.primary, unselectedLabelColor: ProkColors.neutral400, indicatorColor: ProkColors.primary,
        tabs: [Tab(text: 'All (\${all.length})'), Tab(text: 'Verified (\${all.where((d) => d.status == "VERIFIED").length})'), const Tab(text: 'Pending')])),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File picker integration required'))),
        backgroundColor: ProkColors.primary, icon: const Icon(Icons.upload_file_rounded, color: Colors.white), label: const Text('Upload', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
      body: p.state == ProviderState.loading ? const LoadingWidget()
        : p.state == ProviderState.error ? ErrorStateWidget(error: p.error ?? 'Error', onRetry: () => context.read<DocumentProvider>().fetchDocuments())
        : TabBarView(controller: _t, children: [
            _DocList(docs: all),
            _DocList(docs: all.where((d) => d.status == 'VERIFIED').toList()),
            _DocList(docs: all.where((d) => d.status != 'VERIFIED' && d.status != 'REJECTED').toList()),
          ]));
  }
}
class _DocList extends StatelessWidget {
  final List docs;
  const _DocList({required this.docs});
  @override Widget build(BuildContext context) {
    if (docs.isEmpty) return const EmptyStateWidget(title: 'No documents here', icon: Icons.folder_outlined);
    return ListView.separated(padding: const EdgeInsets.all(16), itemCount: docs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) { final d = docs[i]; return ProkCard(child: Row(children: [
        Container(width: 40, height: 40, decoration: const BoxDecoration(color: ProkColors.primarySurface, borderRadius: ProkRadius.sm),
          child: const Icon(Icons.description_outlined, color: ProkColors.primaryLight, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(d.docType ?? d.fileName ?? 'Document', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ProkColors.neutral900)),
          Text((d.createdAt ?? '').toString().substring(0, 10), style: const TextStyle(fontSize: 12, color: ProkColors.neutral400)),
        ])),
        StatusBadge(status: d.status),
      ])); });
  }
}
