import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ClaudeService {
  static const String _baseUrl =
      'https://api.anthropic.com/v1/messages';
  static const String _model =
      'claude-sonnet-4-6';

  static Future<String> sendMessage({
    required String systemPrompt,
    required List<Map<String, String>> messages,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': ApiConfig.claudeApiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': _model,
          'max_tokens': 4096,
          'system': systemPrompt,
          'messages': messages,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['content'][0]['text'];
      } else {
        return 'Error: ${response.statusCode} — ${response.body}';
      }
    } catch (e) {
      return 'Connection error: $e';
    }
  }

  /// Sends a single-turn message with an image attached (vision / multimodal).
  /// Used for AI product description generation from uploaded product photos.
  static Future<String> sendMessageWithImage({
    required String systemPrompt,
    required String userText,
    required Uint8List imageBytes,
    String mediaType = 'image/jpeg',
  }) async {
    try {
      final base64Image = base64Encode(imageBytes);

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': ApiConfig.claudeApiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': _model,
          'max_tokens': 1024,
          'system': systemPrompt,
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'image',
                  'source': {
                    'type': 'base64',
                    'media_type': mediaType,
                    'data': base64Image,
                  },
                },
                {
                  'type': 'text',
                  'text': userText,
                },
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['content'][0]['text'];
      } else {
        return 'Error: ${response.statusCode} — ${response.body}';
      }
    } catch (e) {
      return 'Connection error: $e';
    }
  }
}
