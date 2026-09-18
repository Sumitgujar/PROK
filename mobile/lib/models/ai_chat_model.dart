class AiActionModel {
  final String label;
  final String route;
  final String actionType;

  AiActionModel({required this.label, required this.route, required this.actionType});

  factory AiActionModel.fromJson(Map<String, dynamic> j) => AiActionModel(
        label: j['label'] ?? '',
        route: j['route'] ?? '',
        actionType: j['action_type'] ?? 'navigate',
      );
}

class AiChatResponseModel {
  final String answer;
  final String intent;
  final List<AiActionModel> actions;
  final List<String> warnings;
  final bool usedFallback;
  final String provider;

  AiChatResponseModel({
    required this.answer,
    required this.intent,
    required this.actions,
    required this.warnings,
    required this.usedFallback,
    required this.provider,
  });

  factory AiChatResponseModel.fromJson(Map<String, dynamic> j) => AiChatResponseModel(
        answer: j['answer'] ?? '',
        intent: j['intent'] ?? 'general_guidance',
        actions: (j['actions'] as List? ?? [])
            .map((e) => AiActionModel.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        warnings: List<String>.from(j['warnings'] ?? []),
        usedFallback: j['used_fallback'] ?? false,
        provider: j['provider'] ?? 'unknown',
      );
}

class ChatMessageModel {
  final String role;
  final String text;
  final DateTime createdAt;
  final AiChatResponseModel? response;

  ChatMessageModel({required this.role, required this.text, required this.createdAt, this.response});
}
