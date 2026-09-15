import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:prok_mobile/providers/document_provider.dart';
import 'package:prok_mobile/providers/attendance_provider.dart';
import 'package:prok_mobile/widgets/loading_widget.dart';
import 'package:prok_mobile/widgets/empty_state_widget.dart';
import 'package:prok_mobile/widgets/error_state_widget.dart';

class StudentDocumentsScreen extends StatefulWidget {
  const StudentDocumentsScreen({super.key});
  @override State<StudentDocumentsScreen> createState() => _State();
}

class _State extends State<StudentDocumentsScreen> {
  @override void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<DocumentProvider>().loadDocuments());
  }

  Color _scol(String s) =>
      s == 'VERIFIED' ? Colors.green : s == 'REJECTED' ? Colors.red : Colors.orange;
  String _slabel(String s) =>
      s == 'VERIFIED' ? 'Verified' : s == 'REJECTED' ? 'Rejected' : 'Under Review';

  Future<void> _upload() async {
    final docTypes = ['identity', 'academic', 'income', 'address', 'certificate', 'other'];
    String selType = docTypes[0];
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
        child: StatefulBuilder(builder: (_, setS) => Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Upload Document', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title *', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selType,
              decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
              items: docTypes.map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase()))).toList(),
              onChanged: (v) => setS(() => selType = v!)),
            const SizedBox(height: 10),
            TextField(controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () =>
                  Navigator.pop(ctx, {'type': selType, 'title': titleCtrl.text, 'desc': descCtrl.text}),
              child: const Text('Pick File and Upload'))),
          ])),
      ),
    );
    if (result == null || result['title']!.trim().isEmpty) return;
    final picked = await FilePicker.platform.pickFiles(type: FileType.any);
    if (picked == null || picked.files.single.path == null) return;
    try {
      await context.read<DocumentProvider>().uploadDocument(
          filePath: picked.files.single.path!,
          docType: result['type']!,
          title: result['title']!,
          description: result['desc'] ?? '');
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Uploaded successfully!'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red));
    }
  }

  @override Widget build(BuildContext context) {
    final prov = context.watch<DocumentProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('My Documents')),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: _upload, icon: const Icon(Icons.upload_file), label: const Text('Upload')),
      body: RefreshIndicator(
        onRefresh: () => context.read<DocumentProvider>().loadDocuments(),
        child: Builder(builder: (_) {
          if (prov.isLoading) return const LoadingWidget();
          if (prov.state == ProviderState.error)
            return ErrorStateWidget(
                error: prov.error!,
                onRetry: () => context.read<DocumentProvider>().loadDocuments());
          if (prov.docs.isEmpty)
            return const EmptyStateWidget(
                title: 'No documents uploaded',
                subtitle: 'Tap Upload to add your first document.',
                icon: Icons.folder_open);
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: prov.docs.length,
            itemBuilder: (_, i) {
              final doc = prov.docs[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(doc.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: _scol(doc.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(_slabel(doc.status),
                            style: TextStyle(color: _scol(doc.status), fontSize: 11, fontWeight: FontWeight.bold))),
                    ]),
                    Text(doc.docType.toUpperCase(), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    if (doc.reviewNote != null && doc.reviewNote!.isNotEmpty)
                      Text('Note: ${doc.reviewNote}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    Text(doc.uploadedAt.length >= 10 ? doc.uploadedAt.substring(0, 10) : doc.uploadedAt,
                        style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ])));
            });
        }),
      ),
    );
  }
}
