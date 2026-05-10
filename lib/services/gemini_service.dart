import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_functions/cloud_functions.dart';

/// Calls Gemini 2.5 Flash via Firebase Cloud Functions.
/// The API key never leaves the backend — no key exposure in the APK.
class GeminiService {
  static FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: 'asia-south1');

  /// Sends a conversation turn to the Gemini chat assistant.
  /// [messages] follows the format: List<{ 'role': 'user'|'assistant', 'content': string }>
  static Future<String> sendMessage({
    required String systemPrompt,
    required List<Map<String, String>> messages,
  }) async {
    try {
      final callable = _functions.httpsCallable('geminiChat');
      final result = await callable.call<Map>({
        'systemPrompt': systemPrompt,
        'messages': messages,
      });
      return result.data['text'] as String;
    } on FirebaseFunctionsException catch (e) {
      return 'Error: ${e.message}';
    } catch (e) {
      return 'Connection error: $e';
    }
  }

  /// Requests a structured product description. The backend owns the prompt.
  static Future<String> describeProduct({
    required String productName,
    required String categoryName,
    Uint8List? imageBytes,
    String mediaType = 'image/jpeg',
  }) async {
    try {
      final callable = _functions.httpsCallable(
        'geminiDescribeProduct',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
      );
      final result = await callable.call<Map>({
        'productName': productName,
        'categoryName': categoryName,
        if (imageBytes != null) 'imageBase64': base64Encode(imageBytes),
        'mediaType': mediaType,
      });
      return result.data['text'] as String;
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'AI generation failed.');
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }
}
