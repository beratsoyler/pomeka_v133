import 'package:flutter/foundation.dart';

import '../models/chat_message.dart';
import 'ai_client.dart';

class ChatController extends ChangeNotifier {
  ChatController({required AiClient aiClient}) : _aiClient = aiClient;

  final AiClient _aiClient;
  final List<ChatMessage> _messages = [];

  List<ChatMessage> get messages => List.unmodifiable(_messages);

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final userMessage = ChatMessage.user(
      id: _generateId(),
      text: trimmed,
      createdAt: DateTime.now(),
    );
    _messages.add(userMessage);
    notifyListeners();

    final aiText = await _aiClient.send(trimmed);
    final aiMessage = ChatMessage.assistant(
      id: _generateId(),
      text: aiText,
      createdAt: DateTime.now(),
    );
    _messages.add(aiMessage);
    notifyListeners();
  }

  String _generateId() => DateTime.now().microsecondsSinceEpoch.toString();
}
