enum ChatSender {
  user,
  assistant,
}

class ChatMessage {
  final String id;
  final String text;
  final ChatSender sender;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.createdAt,
  });

  bool get isUser => sender == ChatSender.user;

  factory ChatMessage.user({
    required String id,
    required String text,
    required DateTime createdAt,
  }) {
    return ChatMessage(
      id: id,
      text: text,
      sender: ChatSender.user,
      createdAt: createdAt,
    );
  }

  factory ChatMessage.assistant({
    required String id,
    required String text,
    required DateTime createdAt,
  }) {
    return ChatMessage(
      id: id,
      text: text,
      sender: ChatSender.assistant,
      createdAt: createdAt,
    );
  }
}
