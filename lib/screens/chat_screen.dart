import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../providers/chat_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/character_provider.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/message_input.dart';
import '../widgets/vrm_viewer.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final settings = ref.watch(settingsProvider).value;
    final characters = ref.watch(characterProvider).value ?? [];

    final activeChar = settings?.activeCharacterId.isNotEmpty == true
        ? characters.where((c) => c.id == settings!.activeCharacterId).firstOrNull
        : null;

    ref.listen(chatProvider, (prev, next) {
      if (next.messages.length != (prev?.messages.length ?? 0)) {
        _scrollToBottom();
      }
    });

    final showVRM = settings?.enableVRM == true && activeChar?.hasVRM == true;
    final vrmHeight = MediaQuery.of(context).size.height * 0.38;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // VRM Viewer or header
          if (showVRM)
            _VRMSection(
              vrmUrl: activeChar!.vrmPath,
              height: vrmHeight,
              characterName: activeChar.name,
            )
          else
            _ChatHeader(character: activeChar),

          // Error banner
          if (chatState.error != null)
            _ErrorBanner(
              error: chatState.error!,
              onDismiss: () => ref.read(chatProvider.notifier).dismissError(),
            ),

          // Messages
          Expanded(
            child: chatState.messages.isEmpty
                ? _EmptyState(character: activeChar)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: chatState.messages.length +
                        (chatState.isLoading ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (i == chatState.messages.length) {
                        return const _TypingIndicator();
                      }
                      final msg = chatState.messages[i];
                      return ChatBubble(
                        message: msg,
                        showTimestamp: settings?.showTimestamps ?? false,
                        characterName: msg.isAssistant ? activeChar?.name : null,
                      );
                    },
                  ),
          ),

          // Input
          MessageInput(
            onSend: (text) => ref.read(chatProvider.notifier).send(text),
            isLoading: chatState.isLoading,
          ),
        ],
      ),
    );
  }
}

class _VRMSection extends StatelessWidget {
  final String? vrmUrl;
  final double height;
  final String characterName;

  const _VRMSection({this.vrmUrl, required this.height, required this.characterName});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          VRMViewer(vrmUrl: vrmUrl, height: height),
          // Gradient fade at bottom
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: 80,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, AppTheme.background],
                ),
              ),
            ),
          ),
          // Status bar padding
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      characterName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        shadows: [Shadow(blurRadius: 8)],
                      ),
                    ),
                    const _OnlineBadge(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  final dynamic character;
  const _ChatHeader({this.character});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTheme.border, width: 1)),
        ),
        child: Row(
          children: [
            if (character != null) ...[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                  ),
                ),
                child: Center(
                  child: Text(
                    character!.initials,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(character!.name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
                  const _OnlineBadge(),
                ],
              ),
            ] else ...[
              const Icon(Icons.auto_awesome, color: AppTheme.accent, size: 22),
              const SizedBox(width: 10),
              const Text('SillyTavern', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
            ],
          ],
        ),
      ),
    );
  }
}

class _OnlineBadge extends StatelessWidget {
  const _OnlineBadge();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6, height: 6,
          decoration: const BoxDecoration(color: AppTheme.success, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        const Text('online', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final dynamic character;
  const _EmptyState({this.character});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.accent, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              character != null ? 'Say hello to ${character!.name}' : 'Start a conversation',
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              character != null
                  ? character!.description.isNotEmpty ? character!.description : 'Type a message below to begin'
                  : 'Select a character from the Characters tab to begin',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 60, top: 4, bottom: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _ctrl,
                  builder: (_, __) {
                    final offset = ((_ctrl.value * 3) - i).clamp(0.0, 1.0);
                    final bounce = offset < 0.5 ? offset * 2 : (1 - offset) * 2;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      child: Transform.translate(
                        offset: Offset(0, -4 * bounce),
                        child: Container(
                          width: 6, height: 6,
                          decoration: const BoxDecoration(color: AppTheme.textMuted, shape: BoxShape.circle),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String error;
  final VoidCallback onDismiss;

  const _ErrorBanner({required this.error, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.error.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(error, style: const TextStyle(color: AppTheme.error, fontSize: 13))),
          GestureDetector(
            onTap: onDismiss,
            child: const Icon(Icons.close_rounded, color: AppTheme.error, size: 18),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.5);
  }
}
