import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final TtsService _instance = TtsService._();
  factory TtsService() => _instance;
  TtsService._();

  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;
  bool _speaking = false;

  bool get isSpeaking => _speaking;

  Future<void> init() async {
    if (_initialized) return;

    await _tts.setSharedInstance(true);

    if (Platform.isAndroid) {
      await _tts.setQueueMode(1); // flush previous, then speak
    }

    _tts.setStartHandler(() => _speaking = true);
    _tts.setCompletionHandler(() => _speaking = false);
    _tts.setCancelHandler(() => _speaking = false);
    _tts.setErrorHandler((_) => _speaking = false);

    await _tts.setLanguage('en-US');
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);

    _initialized = true;
  }

  Future<void> speak(
    String text, {
    String language = 'en-US',
    double pitch = 1.0,
    double rate = 0.5,
    double volume = 1.0,
  }) async {
    await init();
    await _tts.stop();

    final clean = _stripMarkdown(text);
    if (clean.trim().isEmpty) return;

    await _tts.setLanguage(language);
    await _tts.setPitch(pitch);
    await _tts.setSpeechRate(rate);
    await _tts.setVolume(volume);

    await _tts.speak(clean);
  }

  Future<void> stop() async {
    await _tts.stop();
    _speaking = false;
  }

  Future<void> pause() async {
    if (Platform.isAndroid) {
      await _tts.stop();
    } else {
      await _tts.pause();
    }
    _speaking = false;
  }

  Future<List<String>> getAvailableLanguages() async {
    await init();
    final langs = await _tts.getLanguages;
    if (langs is List) return langs.cast<String>()..sort();
    return ['en-US'];
  }

  Future<List<Map<String, String>>> getAvailableVoices() async {
    await init();
    try {
      final voices = await _tts.getVoices;
      if (voices is List) {
        return voices
            .whereType<Map>()
            .map((v) => {
                  'name': v['name']?.toString() ?? '',
                  'locale': v['locale']?.toString() ?? '',
                })
            .where((v) => v['name']!.isNotEmpty)
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// Remove markdown formatting before speaking
  String _stripMarkdown(String text) {
    return text
        .replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'$1')
        .replaceAll(RegExp(r'\*(.+?)\*'), r'$1')
        .replaceAll(RegExp(r'__(.+?)__'), r'$1')
        .replaceAll(RegExp(r'_(.+?)_'), r'$1')
        .replaceAll(RegExp(r'`{1,3}[^`]*`{1,3}'), '')
        .replaceAll(RegExp(r'#{1,6}\s'), '')
        .replaceAll(RegExp(r'>\s'), '')
        .replaceAll(RegExp(r'\[(.+?)\]\(.+?\)'), r'$1')
        .replaceAll(RegExp(r'!\[.*?\]\(.*?\)'), '')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  void dispose() {
    _tts.stop();
  }
}
