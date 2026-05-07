import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message_model.dart';
import '../models/character_model.dart';
import '../services/ai_service.dart';
import '../services/tts_service.dart';
import 'settings_provider.dart';
import 'character_provider.dart';

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isSpeaking;
  final String? error;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isSpeaking = false,
    this.error,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isSpeaking,
    String? error,
    bool clearError = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ChatNotifier extends Notifier<ChatState> {
  final _tts = TtsService();

  @override
  ChatState build() => const ChatState();

  Character? _getCharacter() {
    final settings = ref.read(settingsProvider).value;
    if (settings == null || settings.activeCharacterId.isEmpty) return null;
    final chars = ref.read(characterProvider).value ?? [];
    try {
      return chars.firstWhere((c) => c.id == settings.activeCharacterId);
    } catch (_) {
      return null;
    }
  }

  Future<void> startChat() async {
    final char = _getCharacter();
    if (char == null) return;

    await stopSpeaking();
    state = const ChatState();

    if (char.firstMessage.isNotEmpty) {
      final greeting = ChatMessage(
        content: char.firstMessage,
        role: MessageRole.assistant,
      );
      state = state.copyWith(messages: [greeting]);

      // Speak first message if TTS enabled
      final settings = ref.read(settingsProvider).value;
      if (settings?.enableTTS == true) {
        _speakReply(char.firstMessage, settings!);
      }
    }
  }

  Future<void> send(String text) async {
    if (text.trim().isEmpty || state.isLoading) return;

    final settings = ref.read(settingsProvider).value;
    if (settings == null) return;

    final providers = ref.read(providersProvider).value ?? [];
    final provider = providers.firstWhere(
      (p) => p.id == settings.activeProviderId,
      orElse: () => providers.first,
    );

    final apiKey = await ref.read(providersProvider.notifier).getApiKey(provider.id);

    final userMsg = ChatMessage(content: text.trim(), role: MessageRole.user);
    final updatedMessages = [...state.messages, userMsg];
    state = state.copyWith(
      messages: updatedMessages,
      isLoading: true,
      clearError: true,
    );

    // Stop any current speech when user sends a message
    if (state.isSpeaking) await stopSpeaking();

    try {
      final char = _getCharacter();
      final systemPrompt = char?.buildSystemPrompt() ?? settings.systemPromptTemplate;

      final reply = await AIService.sendMessage(
        provider: provider,
        apiKey: apiKey,
        history: updatedMessages,
        systemPrompt: systemPrompt,
        temperature: settings.temperature,
        maxTokens: settings.maxTokens,
      );

      final aiMsg = ChatMessage(content: reply, role: MessageRole.assistant);
      state = state.copyWith(
        messages: [...updatedMessages, aiMsg],
        isLoading: false,
      );

      // Auto-speak reply if TTS enabled
      if (settings.enableTTS) {
        _speakReply(reply, settings);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> speakMessage(String text) async {
    final settings = ref.read(settingsProvider).value;
    if (settings == null) return;
    if (state.isSpeaking) {
      await stopSpeaking();
      return;
    }
    _speakReply(text, settings);
  }

  void _speakReply(String text, dynamic settings) {
    state = state.copyWith(isSpeaking: true);
    _tts
        .speak(
      text,
      language: settings.ttsLanguage as String,
      pitch: settings.ttsPitch as double,
      rate: settings.ttsRate as double,
      volume: settings.ttsVolume as double,
    )
        .then((_) {
      state = state.copyWith(isSpeaking: false);
    }).catchError((_) {
      state = state.copyWith(isSpeaking: false);
    });
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
    state = state.copyWith(isSpeaking: false);
  }

  void clearChat() {
    stopSpeaking();
    state = const ChatState();
  }

  void dismissError() => state = state.copyWith(clearError: true);
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);
