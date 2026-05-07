import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message_model.dart';
import '../models/character_model.dart';
import '../services/ai_service.dart';
import 'settings_provider.dart';
import 'character_provider.dart';

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ChatNotifier extends Notifier<ChatState> {
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

    state = const ChatState();

    if (char.firstMessage.isNotEmpty) {
      final greeting = ChatMessage(
        content: char.firstMessage,
        role: MessageRole.assistant,
      );
      state = state.copyWith(messages: [greeting]);
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

    final providersNotifier = ref.read(providersProvider.notifier);
    final apiKey = await providersNotifier.getApiKey(provider.id);

    final userMsg = ChatMessage(content: text.trim(), role: MessageRole.user);
    final updatedMessages = [...state.messages, userMsg];
    state = state.copyWith(messages: updatedMessages, isLoading: true, clearError: true);

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
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void clearChat() => state = const ChatState();

  void dismissError() => state = state.copyWith(clearError: true);
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);
