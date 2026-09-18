import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prok_mobile/models/ai_chat_model.dart';
import 'package:prok_mobile/providers/ai_chat_provider.dart';

class AskProkScreen extends StatefulWidget {
  const AskProkScreen({super.key});

  @override
  State<AskProkScreen> createState() => _AskProkScreenState();
}

class _AskProkScreenState extends State<AskProkScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final provider = context.read<AiChatProvider>();
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty) return;
    _controller.clear();
    await provider.sendQuestion(text);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AiChatProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ask PROK'),
        actions: [
          IconButton(
            onPressed: provider.messages.isEmpty ? null : provider.clearConversation,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear conversation',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFFEEF2FF),
            padding: const EdgeInsets.all(12),
            child: const Text(
              'Ask about your real attendance, documents, scholarships, courses, and priorities. PROK uses college data and rules; it does not invent facts.',
              style: TextStyle(fontSize: 12, color: Color(0xFF1E3A8A)),
            ),
          ),
          Expanded(
            child: provider.messages.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const SizedBox(height: 24),
                      const Icon(Icons.auto_awesome, size: 56, color: Color(0xFF1E3A8A)),
                      const SizedBox(height: 12),
                      const Text(
                        'Ask PROK anything about your current academic situation.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Try one of these questions:',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: provider.suggestions
                            .map((q) => ActionChip(
                                  label: Text(q),
                                  onPressed: () => _send(q),
                                ))
                            .toList(),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.messages.length + (provider.isLoading ? 1 : 0),
                    itemBuilder: (_, index) {
                      if (index >= provider.messages.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
                          ),
                        );
                      }
                      final message = provider.messages[index];
                      return _MessageBubble(message: message);
                    },
                  ),
          ),
          if (provider.error != null && provider.messages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(provider.error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Ask PROK a question',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: provider.isLoading ? null : _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final bg = isUser ? const Color(0xFF1E3A8A) : Colors.grey.shade100;
    final fg = isUser ? Colors.white : Colors.black87;
    final align = isUser ? Alignment.centerRight : Alignment.centerLeft;

    return Align(
      alignment: align,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.84),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message.text, style: TextStyle(color: fg, height: 1.35)),
            if (!isUser && message.response != null) ...[
              if (message.response!.warnings.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: message.response!.warnings
                      .map((w) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Text(w, style: TextStyle(fontSize: 11, color: Colors.orange.shade900)),
                          ))
                      .toList(),
                ),
              ],
              if (message.response!.actions.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: message.response!.actions
                      .where((a) => a.route.isNotEmpty)
                      .map((a) => OutlinedButton(
                            onPressed: () => Navigator.pushNamed(context, a.route),
                            child: Text(a.label),
                          ))
                      .toList(),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Intent: ${message.response!.intent} • Provider: ${message.response!.provider}${message.response!.usedFallback ? ' • Fallback used' : ''}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
