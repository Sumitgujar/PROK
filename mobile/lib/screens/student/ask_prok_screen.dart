import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prok_mobile/models/ai_chat_model.dart';
import 'package:prok_mobile/providers/ai_chat_provider.dart';
import 'package:prok_mobile/theme/app_theme.dart';
class AskProkScreen extends StatefulWidget {
  const AskProkScreen({super.key});
  @override State<AskProkScreen> createState() => _Q();
}
class _Q extends State<AskProkScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  @override void dispose() { _ctrl.dispose(); _scroll.dispose(); super.dispose(); }
  Future<void> _send([String? preset]) async {
    final q = (preset ?? _ctrl.text).trim();
    if (q.isEmpty) return;
    _ctrl.clear();
    await context.read<AiChatProvider>().sendQuestion(q);
    await Future.delayed(const Duration(milliseconds: 100));
    if (_scroll.hasClients) _scroll.animateTo(_scroll.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }
  @override Widget build(BuildContext context) {
    final p = context.watch<AiChatProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 28, height: 28, decoration: const BoxDecoration(color: ProkColors.primarySurface, shape: BoxShape.circle),
            child: const Icon(Icons.auto_awesome_rounded, color: ProkColors.primary, size: 14)),
          const SizedBox(width: 8), const Text('Ask PROK'),
        ]),
        actions: [if (p.messages.isNotEmpty) IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 20), onPressed: () async {
          final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
            title: const Text('Clear conversation?'), content: const Text('All messages will be removed.'),
            actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear'))]));
          if (ok == true && context.mounted) context.read<AiChatProvider>().clearConversation();
        })]),
      ),
      body: Column(children: [
        Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), color: ProkColors.primarySurface,
          child: const Text('PROK guides you using your real college data. It will not invent facts.', style: TextStyle(fontSize: 12, color: ProkColors.primary, height: 1.4))),
        Expanded(child: p.messages.isEmpty ? _welcome(p) : ListView.builder(
          controller: _scroll, padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          itemCount: p.messages.length + (p.isLoading ? 1 : 0),
          itemBuilder: (_, i) {
            if (i >= p.messages.length) return const Padding(padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(children: [CircleAvatar(radius: 14, backgroundColor: ProkColors.primarySurface,
                child: Icon(Icons.auto_awesome_rounded, color: ProkColors.primary, size: 12)), SizedBox(width: 10),
                SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: ProkColors.primary))]));
            return _Bubble(message: p.messages[i], onAction: _send);
          })),
        _inputBar(p),
      ]),
    );
  }
  Widget _welcome(AiChatProvider p) => ListView(padding: const EdgeInsets.all(24), children: [
    const SizedBox(height: 24),
    Center(child: Container(width: 64, height: 64, decoration: const BoxDecoration(color: ProkColors.primarySurface, shape: BoxShape.circle),
      child: const Icon(Icons.auto_awesome_rounded, color: ProkColors.primary, size: 30))),
    const SizedBox(height: 16),
    const Center(child: Text('Ask PROK', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: ProkColors.neutral900))),
    const SizedBox(height: 6),
    const Center(child: Text('Personalised guidance based on your real academic data', style: TextStyle(fontSize: 13, color: ProkColors.neutral400), textAlign: TextAlign.center)),
    const SizedBox(height: 24),
    ...p.suggestions.map((q) => Padding(padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(onTap: () => _send(q),
        child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: ProkColors.white, borderRadius: ProkRadius.lg, border: Border.all(color: ProkColors.neutral200)),
          child: Row(children: [Expanded(child: Text(q, style: const TextStyle(fontSize: 14, color: ProkColors.neutral800, fontWeight: FontWeight.w500))),
            const Icon(Icons.chevron_right_rounded, color: ProkColors.neutral400, size: 18)]))))),
  ]);
  Widget _inputBar(AiChatProvider p) => Container(
    decoration: const BoxDecoration(color: ProkColors.white, border: Border(top: BorderSide(color: ProkColors.neutral200))),
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
    child: SafeArea(top: false, child: Row(children: [
      Expanded(child: TextField(controller: _ctrl, minLines: 1, maxLines: 4, textInputAction: TextInputAction.send, onSubmitted: (_) => _send(),
        decoration: InputDecoration(hintText: 'Ask a question...', filled: true, fillColor: ProkColors.neutral100,
          border: OutlineInputBorder(borderRadius: ProkRadius.lg, borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)))),
      const SizedBox(width: 10),
      GestureDetector(onTap: p.isLoading ? null : _send, child: Container(width: 44, height: 44,
        decoration: BoxDecoration(color: p.isLoading ? ProkColors.neutral200 : ProkColors.primary, borderRadius: ProkRadius.md),
        child: Icon(Icons.arrow_upward_rounded, color: p.isLoading ? ProkColors.neutral400 : Colors.white, size: 20))),
    ])),
  );
}
class _Bubble extends StatelessWidget {
  final ChatMessageModel message;
  final Future<void> Function(String) onAction;
  const _Bubble({required this.message, required this.onAction});
  @override Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    return Padding(padding: const EdgeInsets.only(bottom: 16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start, children: [
        if (!isUser) ...[ const CircleAvatar(radius: 14, backgroundColor: ProkColors.primarySurface, child: Icon(Icons.auto_awesome_rounded, color: ProkColors.primary, size: 12)), const SizedBox(width: 8)],
        Flexible(child: Container(padding: const EdgeInsets.all(14),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
          decoration: BoxDecoration(color: isUser ? ProkColors.primary : ProkColors.white, borderRadius: ProkRadius.lg, border: isUser ? null : Border.all(color: ProkColors.neutral200)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(message.text, style: TextStyle(color: isUser ? Colors.white : ProkColors.neutral900, fontSize: 14, height: 1.5)),
            if (!isUser && message.response?.actions.isNotEmpty == true) ...[
              const SizedBox(height: 10),
              Wrap(spacing: 6, runSpacing: 6, children: message.response!.actions.take(3).map((a) =>
                GestureDetector(onTap: () => Navigator.pushNamed(context, a.route),
                  child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(color: ProkColors.primarySurface, borderRadius: ProkRadius.full, border: Border.all(color: ProkColors.primary.withOpacity(0.3))),
                    child: Text(a.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ProkColors.primary))))).toList()),
            ],
          ])),
        ),
        if (isUser) const SizedBox(width: 8),
      ]));
  }
}
