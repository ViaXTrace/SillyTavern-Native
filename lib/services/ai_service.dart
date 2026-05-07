import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ai_provider.dart';
import '../models/message_model.dart';

class AIService {
  static Future<String> sendMessage({
    required AIProvider provider,
    required String apiKey,
    required List<ChatMessage> history,
    required String systemPrompt,
    double temperature = 0.8,
    int maxTokens = 1024,
  }) async {
    switch (provider.type) {
      case AIProviderType.anthropic:
        return _callAnthropic(
          provider: provider,
          apiKey: apiKey,
          history: history,
          systemPrompt: systemPrompt,
          temperature: temperature,
          maxTokens: maxTokens,
        );
      case AIProviderType.gemini:
        return _callGemini(
          provider: provider,
          apiKey: apiKey,
          history: history,
          systemPrompt: systemPrompt,
          temperature: temperature,
          maxTokens: maxTokens,
        );
      default:
        return _callOpenAICompat(
          provider: provider,
          apiKey: apiKey,
          history: history,
          systemPrompt: systemPrompt,
          temperature: temperature,
          maxTokens: maxTokens,
        );
    }
  }

  // OpenAI / OpenRouter / Ollama / Custom (all use OpenAI-compatible format)
  static Future<String> _callOpenAICompat({
    required AIProvider provider,
    required String apiKey,
    required List<ChatMessage> history,
    required String systemPrompt,
    required double temperature,
    required int maxTokens,
  }) async {
    final messages = <Map<String, String>>[];
    if (systemPrompt.isNotEmpty) {
      messages.add({'role': 'system', 'content': systemPrompt});
    }
    for (final m in history) {
      if (m.isSystem) continue;
      messages.add({'role': m.role.name, 'content': m.content});
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    if (provider.type == AIProviderType.openrouter) {
      headers['HTTP-Referer'] = 'https://github.com/SillyTavern/SillyTavern';
      headers['X-Title'] = 'SillyTavern Native';
    }

    final body = jsonEncode({
      'model': provider.model,
      'messages': messages,
      'temperature': temperature,
      'max_tokens': maxTokens,
      'stream': false,
    });

    final res = await http
        .post(
          Uri.parse('${provider.baseUrl}/chat/completions'),
          headers: headers,
          body: body,
        )
        .timeout(const Duration(seconds: 60));

    if (res.statusCode != 200) {
      throw Exception('API error ${res.statusCode}: ${res.body}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final choices = data['choices'] as List<dynamic>;
    final msg = (choices.first as Map)['message'] as Map<String, dynamic>;
    return msg['content'] as String? ?? '';
  }

  // Anthropic Claude
  static Future<String> _callAnthropic({
    required AIProvider provider,
    required String apiKey,
    required List<ChatMessage> history,
    required String systemPrompt,
    required double temperature,
    required int maxTokens,
  }) async {
    final messages = <Map<String, String>>[];
    for (final m in history) {
      if (m.isSystem) continue;
      messages.add({
        'role': m.isUser ? 'user' : 'assistant',
        'content': m.content,
      });
    }

    final body = <String, dynamic>{
      'model': provider.model,
      'messages': messages,
      'max_tokens': maxTokens,
      'temperature': temperature,
    };
    if (systemPrompt.isNotEmpty) body['system'] = systemPrompt;

    final res = await http
        .post(
          Uri.parse('${provider.baseUrl}/messages'),
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': apiKey,
            'anthropic-version': '2023-06-01',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 60));

    if (res.statusCode != 200) {
      throw Exception('Anthropic error ${res.statusCode}: ${res.body}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final content = data['content'] as List<dynamic>;
    final text = (content.first as Map)['text'] as String? ?? '';
    return text;
  }

  // Google Gemini
  static Future<String> _callGemini({
    required AIProvider provider,
    required String apiKey,
    required List<ChatMessage> history,
    required String systemPrompt,
    required double temperature,
    required int maxTokens,
  }) async {
    final contents = <Map<String, dynamic>>[];
    if (systemPrompt.isNotEmpty) {
      contents.add({
        'role': 'user',
        'parts': [{'text': systemPrompt}],
      });
      contents.add({
        'role': 'model',
        'parts': [{'text': 'Understood. I will follow those instructions.'}],
      });
    }
    for (final m in history) {
      if (m.isSystem) continue;
      contents.add({
        'role': m.isUser ? 'user' : 'model',
        'parts': [{'text': m.content}],
      });
    }

    final url =
        '${provider.baseUrl}/models/${provider.model}:generateContent?key=$apiKey';

    final res = await http
        .post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': contents,
            'generationConfig': {
              'temperature': temperature,
              'maxOutputTokens': maxTokens,
            },
          }),
        )
        .timeout(const Duration(seconds: 60));

    if (res.statusCode != 200) {
      throw Exception('Gemini error ${res.statusCode}: ${res.body}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final candidates = data['candidates'] as List<dynamic>;
    final content = (candidates.first as Map)['content'] as Map<String, dynamic>;
    final parts = content['parts'] as List<dynamic>;
    return (parts.first as Map)['text'] as String? ?? '';
  }
}
