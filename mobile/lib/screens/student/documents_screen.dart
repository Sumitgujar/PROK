import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prok_mobile/theme/app_theme.dart';
import 'package:prok_mobile/providers/document_provider.dart';
import 'package:prok_mobile/providers/attendance_provider.dart';
import 'package:prok_mobile/models/document_model.dart';
import 'package:prok_mobile/widgets/loading_widget.dart';
import 'package:prok_mobile/widgets/error_state_widget.dart';
import 'package:prok_mobile/widgets/empty_state_widget.dart';

class StudentDocumentsScreen extends StatefulWidget {
  const StudentDocumentsScreen({super.key});
  @override
  State<StudentDocumentsScreen> createState() => _StudentDocumentsScreenState();
}

class _StudentDocumentsScreenState extends State<StudentDocumentsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  bool _uploading = false;
  String? _uploadError;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    Future.microtask(() => context.read<DocumentProvider>().loadDocuments());
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _upload() async {
    setState(() => _uploadError = null);
    try {
      final picked = await FilePicker.platform.pickFiles(type: FileType.any, allowMultiple: false);
      if (picked == null || picked.files.isEmpty) return;
      final file = picked.files.single;
      if (file.path == null || file.path!.isEmpty) {
        setState(() => _uploadError = 'The selected file path is unavailable on this device.');
        return;
      }
      final titleController = TextEditingController(text: file.name);
      var docType = 'OTHER';
      final form = await showDialog<Map<String, String>>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            title: const Text('Upload document'),
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(file.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: ProkColors.neutral600)),
                const SizedBox(height: 14),
                const Text('Document title', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                TextField(controller: titleController, autofocus: true, decoration: const InputDecoration(hintText: 'e.g. Semester transcript')),
                const SizedBox(height: 14),
                const Text('Document type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: docType,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'ID_PROOF', child: Text('Identity proof')),
                    DropdownMenuItem(value: 'TRANSCRIPT', child: Text('Transcript / marksheet')),
                    DropdownMenuItem(value: 'INCOME_CERTIFICATE', child: Text('Income certificate')),
                    DropdownMenuItem(value: 'CASTE_CERTIFICATE', child: Text('Caste certificate')),
                    DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                  ],
                  onChanged: (value) => setDialogState(() => docType = value ?? 'OTHER'),
                ),
              ]),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
              ElevatedButton(onPressed: () {
                final title = titleController.text.trim();
                if (title.isNotEmpty) Navigator.pop(dialogContext, {'title': title, 'doc_type': docType});
              }, child: const Text('Continue')),
            ],
          ),
        ),
      );
      titleController.dispose();
      if (form == null || !mounted) return;
      setState(() => _uploading = true);
      await context.read<DocumentProvider>().uploadDocument(
        filePath: file.path!, docType: form['doc_type']!, title: form['title']!,
      );
      if (!mounted) return;
      final provider = context.read<DocumentProvider>();
      if (provider.state == ProviderState.error) throw Exception(provider.error ?? 'Upload could not be confirmed.');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Document uploaded and sent for review.'), backgroundColor: ProkColors.success,
      ));
      _tabs.animateTo(0);
    } catch (error) {
      if (mounted) setState(() => _uploadError = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _details(DocumentModel doc) {
    showModalBottomSheet<void>(
      context: context, showDragHandle: true,
      builder: (context) => SafeArea(child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(doc.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: ProkColors.neutral900)),
          const SizedBox(height: 8),
          StatusBadge(status: doc.status),
          const SizedBox(height: 14),
          _InfoRow(label: 'Type', value: doc.docType),
          _InfoRow(label: 'Uploaded', value: doc.uploadedAt.isEmpty ? 'Date unavailable' : doc.uploadedAt.substring(0, 10)),
          if ((doc.reviewNote ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Review note', style: TextStyle(fontWeight: FontWeight.w700, color: ProkColors.neutral800)),
            const SizedBox(height: 4),
            Text(doc.reviewNote!, style: const TextStyle(fontSize: 13, height: 1.5, color: ProkColors.neutral600)),
          ],
          const SizedBox(height: 8),
          const Text('If a document is rejected, follow the review note and upload a corrected file.', style: TextStyle(fontSize: 12, height: 1.5, color: ProkColors.neutral400)),
        ]),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<DocumentProvider>();
    final docs = p.docs;
    final verified = docs.where((doc) => doc.status == 'VERIFIED').toList();
    final waiting = docs.where((doc) => doc.status == 'UNDER_REVIEW').toList();
    final rejected = docs.where((doc) => doc.status == 'REJECTED').toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents'),
        actions: [IconButton(tooltip: 'Refresh documents', icon: const Icon(Icons.refresh_rounded), onPressed: () => context.read<DocumentProvider>().loadDocuments())],
        bottom: TabBar(
          controller: _tabs,
          labelColor: ProkColors.primary, unselectedLabelColor: ProkColors.neutral400, indicatorColor: ProkColors.primary,
          tabs: [
            Tab(text: 'All (' + docs.length.toString() + ')'),
            Tab(text: 'Verified (' + verified.length.toString() + ')'),
            Tab(text: 'In review (' + waiting.length.toString() + ')'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _uploading ? null : _upload,
        backgroundColor: ProkColors.primary,
        icon: _uploading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.upload_file_rounded, color: Colors.white),
        label: Text(_uploading ? 'Uploading…' : 'Upload document', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: p.state == ProviderState.loading && docs.isEmpty
        ? const LoadingWidget(message: 'Loading documents…')
        : p.state == ProviderState.error && docs.isEmpty
          ? ErrorStateWidget(error: p.error ?? 'Documents could not be loaded.', onRetry: () => context.read<DocumentProvider>().loadDocuments())
          : Column(children: [
              if (_uploadError != null)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0), padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: ProkColors.errorSurface, borderRadius: ProkRadius.md),
                  child: Row(children: [
                    const Icon(Icons.error_outline_rounded, color: ProkColors.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_uploadError!, style: const TextStyle(fontSize: 12, color: ProkColors.error))),
                    IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => setState(() => _uploadError = null)),
                  ]),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Row(children: [
                  _Count(label: 'Verified', count: verified.length, color: ProkColors.success),
                  const SizedBox(width: 8),
                  _Count(label: 'In review', count: waiting.length, color: ProkColors.warning),
                  const SizedBox(width: 8),
                  _Count(label: 'Rejected', count: rejected.length, color: ProkColors.error),
                ]),
              ),
              Expanded(child: TabBarView(controller: _tabs, children: [
                _DocumentList(documents: docs, onTap: _details),
                _DocumentList(documents: verified, onTap: _details),
                _DocumentList(documents: waiting, onTap: _details),
              ])),
            ]),
    );
  }
}

class _DocumentList extends StatelessWidget {
  final List<DocumentModel> documents;
  final ValueChanged<DocumentModel> onTap;
  const _DocumentList({required this.documents, required this.onTap});
  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) return ListView(children: const [
      SizedBox(height: 55),
      EmptyStateWidget(title: 'No documents here', subtitle: 'Upload a file to start a review.', icon: Icons.folder_outlined),
    ]);
    return RefreshIndicator(
      color: ProkColors.primary,
      onRefresh: () => context.read<DocumentProvider>().loadDocuments(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 92),
        itemCount: documents.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final doc = documents[index];
          final statusColor = doc.status == 'VERIFIED' ? ProkColors.success : doc.status == 'REJECTED' ? ProkColors.error : ProkColors.warning;
          return InkWell(
            borderRadius: ProkRadius.md,
            onTap: () => onTap(doc),
            child: ProkCard(child: Row(children: [
              Container(width: 42, height: 42, decoration: const BoxDecoration(color: ProkColors.primarySurface, borderRadius: ProkRadius.md),
                child: const Icon(Icons.description_outlined, color: ProkColors.primary, size: 21)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(doc.title.isEmpty ? doc.docType : doc.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ProkColors.neutral900)),
                const SizedBox(height: 4),
                Text(doc.docType + ' · ' + (doc.uploadedAt.isEmpty ? 'Date unavailable' : doc.uploadedAt.substring(0, 10)),
                  style: const TextStyle(fontSize: 11, color: ProkColors.neutral400)),
                if ((doc.reviewNote ?? '').isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(doc.reviewNote!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: ProkColors.neutral600)),
                ],
              ])),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: statusColor),
            ])),
          );
        },
      ),
    );
  }
}

class _Count extends StatelessWidget {
  final String label; final int count; final Color color;
  const _Count({required this.label, required this.count, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
    decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: ProkRadius.md),
    child: Column(children: [
      Text(count.toString(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
      Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    ]),
  ));
}

class _InfoRow extends StatelessWidget {
  final String label; final String value;
  const _InfoRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      SizedBox(width: 85, child: Text(label, style: const TextStyle(fontSize: 12, color: ProkColors.neutral400))),
      Expanded(child: Text(value.isEmpty ? 'Not provided' : value, style: const TextStyle(fontSize: 13, color: ProkColors.neutral800, fontWeight: FontWeight.w600))),
    ]),
  );
}
