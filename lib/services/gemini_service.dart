import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

/// Service class for interacting with Google Gemini API
/// Handles AI assistant conversations specialized in ANN, CNN, LSTM, and RAG models
class GeminiService {
  late GenerativeModel _model;
  late ChatSession _chatSession;
  static const String _systemMessage = 
      "You are an AI assistant specialized in answering questions about ANN (Artificial Neural Networks), "
      "CNN (Convolutional Neural Networks), LSTM (Long Short-Term Memory), and RAG (Retrieval-Augmented Generation) models. "
      "Provide clear, accurate, and helpful responses about these machine learning topics. "
      "Explain concepts in a way that is easy to understand while maintaining technical accuracy.";

  /// Initialize the Gemini service with API key from .env file
  Future<void> initialize() async {
    try {
      // Load .env file
      await dotenv.load(fileName: '.env');
      
      // Get API key from environment variables
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('GEMINI_API_KEY not found in .env file');
      }

      // Initialize GenerativeModel with Gemini Pro model
      _model = GenerativeModel(
        model: 'gemini-3-pro-preview',
        apiKey: apiKey,
      );

      // Start chat session with system message
      _chatSession = _model.startChat(history: [
        Content.text(_systemMessage),
      ]);
    } catch (e) {
      throw Exception('Failed to initialize Gemini service: $e');
    }
  }

  /// Send a message to Gemini and get response
  Future<String> sendMessage(String message) async {
    try {
      if (message.trim().isEmpty) {
        throw Exception('Message cannot be empty');
      }

      // Send message and get response
      final response = await _chatSession.sendMessage(Content.text(message));
      
      if (response.text == null || response.text!.isEmpty) {
        throw Exception('Received empty response from Gemini');
      }

      return response.text!;
    } catch (e) {
      throw Exception('Failed to send message to Gemini: $e');
    }
  }

  /// Reset the chat session (clear conversation history)
  void resetChat() {
    _chatSession = _model.startChat(history: [
      Content.text(_systemMessage),
    ]);
  }

  /// Get current chat history
  List<Content> getChatHistory() {
    return _chatSession.history.toList();
  }

  /// Check if service is initialized
  bool get isInitialized => _model != null && _chatSession != null;
}
