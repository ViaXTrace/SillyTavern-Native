import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_theme.dart';
import '../models/character_model.dart';
import '../providers/character_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/chat_provider.dart';

class CharactersScreen extends ConsumerWidget {
  const CharactersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chars = ref.watch(characterProvider);
    final settings = ref.watch(settingsProvider).value;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onAdd: () => _showAddSheet(context, ref)),
            Expanded(
              child: chars.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppTheme.accent),
                ),
                error: (e, _) => Center(
                  child: Text('Error: $e', style: const TextStyle(color: AppTheme.error)),
                ),
                data: (list) => list.isEmpty
                    ? _EmptyState(onAdd: () => _showAddSheet(context, ref))
                    : _CharacterGrid(
                        characters: list,
                        activeId: settings?.activeCharacterId ?? '',
                        onSelect: (c) => _select(context, ref, c),
                        onDelete: (c) => _delete(context, ref, c),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _select(BuildContext context, WidgetRef ref, Character c) async {
    await ref.read(settingsProvider.notifier).update(
          (s) => s.copyWith(activeCharacterId: c.id),
        );
    await ref.read(chatProvider.notifier).startChat();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${c.name} selected'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Character c) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('Delete ${c.name}?',
            style: const TextStyle(color: AppTheme.textPrimary)),
        content: const Text('This will delete the character card.',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(characterProvider.notifier).delete(c.id);
    }
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddCharacterSheet(ref: ref),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onAdd;
  const _Header({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
      child: Row(
        children: [
          const Text(
            'Characters',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, color: AppTheme.accent, size: 26),
            style: IconButton.styleFrom(
                backgroundColor: AppTheme.accent.withOpacity(0.1)),
          ),
        ],
      ),
    );
  }
}

class _CharacterGrid extends StatelessWidget {
  final List<Character> characters;
  final String activeId;
  final void Function(Character) onSelect;
  final void Function(Character) onDelete;

  const _CharacterGrid({
    required this.characters,
    required this.activeId,
    required this.onSelect,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: characters.length,
      itemBuilder: (ctx, i) {
        final c = characters[i];
        return _CharacterCard(
          character: c,
          isActive: c.id == activeId,
          onTap: () => onSelect(c),
          onLongPress: () => onDelete(c),
        )
            .animate(delay: (i * 50).ms)
            .fadeIn()
            .scale(begin: const Offset(0.95, 0.95));
      },
    );
  }
}

class _CharacterCard extends StatelessWidget {
  final Character character;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _CharacterCard({
    required this.character,
    required this.isActive,
    required this.onTap,
    required this.onLongPress,
  });

  Color _colorFromName(String name) {
    const colors = [
      Color(0xFF7C3AED),
      Color(0xFF4F46E5),
      Color(0xFF0EA5E9),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
    ];
    return colors[name.codeUnits.fold(0, (a, b) => a + b) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? AppTheme.accent : AppTheme.border,
            width: isActive ? 2 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppTheme.accent.withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _colorFromName(character.name),
                      _colorFromName(character.name).withOpacity(0.5),
                    ],
                  ),
                ),
                child: Center(
                  child: Text(
                    character.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    character.name,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (character.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        character.description,
                        style: const TextStyle(
                            color: AppTheme.textMuted, fontSize: 11),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (isActive)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                          color: AppTheme.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.person_add_outlined,
                color: AppTheme.accent, size: 36),
          ),
          const SizedBox(height: 16),
          const Text(
            'No characters yet',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add a character to start chatting',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add Character'),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

class _AddCharacterSheet extends StatefulWidget {
  final WidgetRef ref;
  const _AddCharacterSheet({required this.ref});

  @override
  State<_AddCharacterSheet> createState() => _AddCharacterSheetState();
}

class _AddCharacterSheetState extends State<_AddCharacterSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _personalityCtrl = TextEditingController();
  final _firstMsgCtrl = TextEditingController();
  final _systemCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _personalityCtrl.dispose();
    _firstMsgCtrl.dispose();
    _systemCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final char = Character(
      id: const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      personality: _personalityCtrl.text.trim(),
      firstMessage: _firstMsgCtrl.text.trim(),
      systemPrompt: _systemCtrl.text.trim(),
    );
    await widget.ref.read(characterProvider.notifier).add(char);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _importJson() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    try {
      final file = result.files.first;
      final bytes = file.bytes ?? (file.path != null ? File(file.path!).readAsBytesSync() : null);
      if (bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not read file')),
          );
        }
        return;
      }
      final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      await widget.ref
          .read(characterProvider.notifier)
          .importFromJson({...json, 'id': const Uuid().v4()});
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid JSON: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text(
                  'New Character',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _importJson,
                  icon: const Icon(Icons.upload_file, size: 16),
                  label: const Text('Import JSON'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _field('Name *', _nameCtrl),
            _field('Description', _descCtrl),
            _field('Personality', _personalityCtrl, lines: 3),
            _field('First Message', _firstMsgCtrl, lines: 2),
            _field('System Prompt', _systemCtrl, lines: 3),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Create Character'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {int lines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: ctrl,
            maxLines: lines,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppTheme.surfaceElevated,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.accent),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}
