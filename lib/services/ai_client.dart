abstract class AiClient {
  Future<String> send(String userText);
}

class MockAiClient implements AiClient {
  static const String _mockResponse = 'Bu bir deneme cevabıdır 🤖';

  @override
  Future<String> send(String userText) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockResponse;
  }
}
