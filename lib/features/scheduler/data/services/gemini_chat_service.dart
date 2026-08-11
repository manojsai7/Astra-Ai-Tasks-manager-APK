import '../../../../core/network/astra_ai_gateway.dart';

/// Backwards-compatible service name while AI execution has moved to the
/// secure ASTRA gateway. No provider API key is read or stored by the app.
class GeminiChatService {
  static final GeminiChatService _instance = GeminiChatService._internal();
  factory GeminiChatService() => _instance;
  GeminiChatService._internal();

  final AstraAiGateway _gateway = AstraAiGateway();

  Future<void> initialize() async {
    if (!_gateway.isConfigured) {
      throw const AstraAiGatewayException(
        'AI is not configured. Set ASTRA_API_BASE_URL when building the app.',
      );
    }
  }

  Future<String> chat(String userMessage) async {
    try {
      return await _gateway.chat(userMessage);
    } on AstraAiGatewayException catch (error) {
      return 'AI connection issue: ${error.message}';
    } catch (_) {
      return 'AI connection issue: Please check your internet connection and try again.';
    }
  }
}
