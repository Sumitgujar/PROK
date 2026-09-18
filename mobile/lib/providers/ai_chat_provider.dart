import 'package:flutter/material.dart';
import 'package:prok_mobile/models/ai_chat_model.dart';
import 'package:prok_mobile/providers/attendance_provider.dart';
import 'package:prok_mobile/services/api_service.dart';

class AiChatProvider extends ChangeNotifier {
  final _api = ApiService();
  final List<ChatMessageModel> _messages = [];
  ProviderState _state = ProviderState.initial;
  String? _error;

  List<ChatMessageModel> get messages => List.unmodifiable(_messages);
  ProviderState get state => _state;
  String? get error => _error;
  bool get isLoading => _state == ProviderState.loading;

  List<String> get suggestions => const [
        'What should I focus on this month?',
        'Why is my attendance at risk?',
        'What documents am I missing?',
        'Which scholarships should I check?',
        'Which courses are suitable for me?',
      ];

  Future<void> sendQuestion(String question) async {
    final trimmed = question.trim();
    if (trimmed.isEmpty) return;
    _error = null;
    _messages.add(ChatMessageModel(
      role: 'user',
      text: trimmed,
      createdAt: DateTime.now(),
    ));
    _state = ProviderState.loading;
    notifyListeners();

    try {
      final data = await _api.post('/ai/chat', {'question': trimmed});
      final response = AiChatResponseModel.fromJson(Map<String, dynamic>.from(data));
      _messages.add(ChatMessageModel(
        role: 'assistant',
        text: response.answer,
        createdAt: DateTime.now(),
        response: response,
      ));
      _state = ProviderState.loaded;
    } catch (e) {
      _state = ProviderState.error;
      _error = e.toString().replaceAll('Exception: ', '');
      _messages.add(ChatMessageModel(
        role: 'assistant',
        text: 'Ask PROK could not complete that request right now. Please try again, or open the relevant section directly.',
        createdAt: DateTime.now(),
      ));
    }
    notifyListeners();
  }

  void clearConversation() {
    _messages.clear();
    _state = ProviderState.initial;
    _error = null;
    notifyListeners();
  }
}
