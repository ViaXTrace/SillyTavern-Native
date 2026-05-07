import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../models/ai_provider.dart';
import '../providers/settings_provider.dart';
import '../services/tts_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value;
    final providers = ref.watch(providersProvider).value ?? [];

    if (settings == null) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Settings',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 24),

            // ── AI Provider ───────────────────────────────────────────────
            _Section(
              title: 'AI Provider',
              child: Column(
                children: providers.map((p) {
                  return _ProviderTile(
                    provider: p,
                    isActive: p.id == settings.activeProviderId,
                    onTap: () => ref
                        .read(settingsProvider.notifier)
                        .update((s) => s.copyWith(activeProviderId: p.id)),
                    onEditKey: () => _editApiKey(context, ref, p),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // ── Generation ────────────────────────────────────────────────
            _Section(
              title: 'Generation',
              child: Column(
                children: [
                  _SliderTile(
                    label: 'Temperature',
                    value: settings.temperature,
                    min: 0, max: 2, divisions: 20,
                    onChanged: (v) => ref
                        .read(settingsProvider.notifier)
                        .update((s) => s.copyWith(temperature: v)),
                  ),
                  _SliderTile(
                    label: 'Max Tokens',
                    value: settings.maxTokens.toDouble(),
                    min: 128, max: 4096, divisions: 31,
                    format: (v) => v.round().toString(),
                    onChanged: (v) => ref
                        .read(settingsProvider.notifier)
                        .update((s) => s.copyWith(maxTokens: v.round())),
                  ),
                  _SliderTile(
                    label: 'Context Messages',
                    value: settings.maxContextMessages.toDouble(),
                    min: 4, max: 100, divisions: 24,
                    format: (v) => v.round().toString(),
                    onChanged: (v) => ref
                        .read(settingsProvider.notifier)
                        .update((s) => s.copyWith(maxContextMessages: v.round())),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── TTS ───────────────────────────────────────────────────────
            _Section(
              title: 'Voice (TTS)',
              child: Column(
                children: [
                  _SwitchTile(
                    label: 'Character Voice',
                    subtitle: 'Speak AI responses aloud',
                    icon: Icons.record_voice_over_rounded,
                    value: settings.enableTTS,
                    onChanged: (v) => ref
                        .read(settingsProvider.notifier)
                        .update((s) => s.copyWith(enableTTS: v)),
                  ),
                  if (settings.enableTTS) ...[
                    _LanguageTile(
                      current: settings.ttsLanguage,
                      onChanged: (lang) => ref
                          .read(settingsProvider.notifier)
                          .update((s) => s.copyWith(ttsLanguage: lang)),
                    ),
                    _SliderTile(
                      label: 'Pitch',
                      value: settings.ttsPitch,
                      min: 0.5, max: 2.0, divisions: 15,
                      onChanged: (v) => ref
                          .read(settingsProvider.notifier)
                          .update((s) => s.copyWith(ttsPitch: v)),
                    ),
                    _SliderTile(
                      label: 'Speed',
                      value: settings.ttsRate,
                      min: 0.1, max: 1.0, divisions: 9,
                      onChanged: (v) => ref
                          .read(settingsProvider.notifier)
                          .update((s) => s.copyWith(ttsRate: v)),
                    ),
                    _SliderTile(
                      label: 'Volume',
                      value: settings.ttsVolume,
                      min: 0.0, max: 1.0, divisions: 10,
                      onChanged: (v) => ref
                          .read(settingsProvider.notifier)
                          .update((s) => s.copyWith(ttsVolume: v)),
                    ),
                    _TtsTestButton(settings: settings),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Display ───────────────────────────────────────────────────
            _Section(
              title: 'Display',
              child: Column(
                children: [
                  _SwitchTile(
                    label: 'VRM Character',
                    subtitle: 'Show 3D character viewer',
                    icon: Icons.view_in_ar_rounded,
                    value: settings.enableVRM,
                    onChanged: (v) => ref
                        .read(settingsProvider.notifier)
                        .update((s) => s.copyWith(enableVRM: v)),
                  ),
                  _SwitchTile(
                    label: 'Show Timestamps',
                    subtitle: 'Display time on each message',
                    icon: Icons.access_time_rounded,
                    value: settings.showTimestamps,
                    onChanged: (v) => ref
                        .read(settingsProvider.notifier)
                        .update((s) => s.copyWith(showTimestamps: v)),
                  ),
                  _SwitchTile(
                    label: 'Haptic Feedback',
                    subtitle: 'Vibration on send',
                    icon: Icons.vibration_rounded,
                    value: settings.hapticFeedback,
                    onChanged: (v) => ref
                        .read(settingsProvider.notifier)
                        .update((s) => s.copyWith(hapticFeedback: v)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            const Center(
              child: Column(
                children: [
                  Text('SillyTavern Native',
                      style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                  SizedBox(height: 2),
                  Text('v1.0.0',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editApiKey(BuildContext context, WidgetRef ref, AIProvider p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ApiKeySheet(provider: p, ref: ref),
    );
  }
}

// ── TTS Test Button ───────────────────────────────────────────────────────────
class _TtsTestButton extends StatefulWidget {
  final dynamic settings;
  const _TtsTestButton({required this.settings});

  @override
  State<_TtsTestButton> createState() => _TtsTestButtonState();
}

class _TtsTestButtonState extends State<_TtsTestButton> {
  bool _testing = false;

  Future<void> _test() async {
    setState(() => _testing = true);
    await TtsService().speak(
      'Hello! I am your AI companion. Voice is working.',
      language: widget.settings.ttsLanguage as String,
      pitch: widget.settings.ttsPitch as double,
      rate: widget.settings.ttsRate as double,
      volume: widget.settings.ttsVolume as double,
    );
    if (mounted) setState(() => _testing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _testing ? null : _test,
          icon: Icon(
            _testing ? Icons.stop_rounded : Icons.play_arrow_rounded,
            size: 18,
          ),
          label: Text(_testing ? 'Speaking…' : 'Test Voice'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.accent,
            side: const BorderSide(color: AppTheme.accent),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ),
    );
  }
}

// ── Language picker ───────────────────────────────────────────────────────────
class _LanguageTile extends StatefulWidget {
  final String current;
  final void Function(String) onChanged;

  const _LanguageTile({required this.current, required this.onChanged});

  @override
  State<_LanguageTile> createState() => _LanguageTileState();
}

class _LanguageTileState extends State<_LanguageTile> {
  List<String> _languages = [];

  @override
  void initState() {
    super.initState();
    TtsService().getAvailableLanguages().then((langs) {
      if (mounted) setState(() => _languages = langs);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.language_rounded,
            color: AppTheme.textSecondary, size: 18),
      ),
      title: const Text('Language',
          style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500)),
      subtitle: Text(widget.current,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right_rounded,
          color: AppTheme.textMuted, size: 20),
      onTap: _languages.isEmpty
          ? null
          : () => showModalBottomSheet(
                context: context,
                backgroundColor: AppTheme.surface,
                shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20))),
                builder: (_) => _LanguageSheet(
                  languages: _languages,
                  current: widget.current,
                  onSelect: (l) {
                    widget.onChanged(l);
                    Navigator.pop(context);
                  },
                ),
              ),
    );
  }
}

class _LanguageSheet extends StatelessWidget {
  final List<String> languages;
  final String current;
  final void Function(String) onSelect;

  const _LanguageSheet(
      {required this.languages, required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        const Text('Select Language',
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: languages.length,
            itemBuilder: (_, i) {
              final lang = languages[i];
              final isSelected = lang == current;
              return ListTile(
                onTap: () => onSelect(lang),
                title: Text(lang,
                    style: TextStyle(
                        color: isSelected
                            ? AppTheme.accent
                            : AppTheme.textPrimary,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        fontSize: 14)),
                trailing: isSelected
                    ? const Icon(Icons.check_rounded,
                        color: AppTheme.accent, size: 18)
                    : null,
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────
class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _ProviderTile extends StatelessWidget {
  final AIProvider provider;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onEditKey;

  const _ProviderTile({
    required this.provider,
    required this.isActive,
    required this.onTap,
    required this.onEditKey,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.accent.withOpacity(0.15)
              : AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.auto_awesome,
            color: isActive ? AppTheme.accent : AppTheme.textMuted, size: 18),
      ),
      title: Text(
        provider.name,
        style: TextStyle(
          color: isActive ? AppTheme.textPrimary : AppTheme.textSecondary,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          fontSize: 14,
        ),
      ),
      subtitle: Text(provider.displayModel,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onEditKey,
            icon: const Icon(Icons.key_rounded,
                size: 18, color: AppTheme.textMuted),
          ),
          if (isActive)
            const Icon(Icons.check_circle_rounded,
                color: AppTheme.accent, size: 20),
        ],
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool value;
  final void Function(bool) onChanged;

  const _SwitchTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.textSecondary, size: 18),
      ),
      title: Text(label,
          style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.accent,
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTheme.accent.withOpacity(0.3);
          }
          return AppTheme.surfaceElevated;
        }),
      ),
    );
  }
}

class _SliderTile extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String Function(double)? format;
  final void Function(double) onChanged;

  const _SliderTile({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    this.format,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = format ?? (v) => v.toStringAsFixed(1);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
              Text(fmt(value),
                  style: const TextStyle(
                      color: AppTheme.accent,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppTheme.accent,
              thumbColor: AppTheme.accent,
              inactiveTrackColor: AppTheme.border,
              overlayColor: AppTheme.accent.withOpacity(0.1),
              trackHeight: 3,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _ApiKeySheet extends StatefulWidget {
  final AIProvider provider;
  final WidgetRef ref;

  const _ApiKeySheet({required this.provider, required this.ref});

  @override
  State<_ApiKeySheet> createState() => _ApiKeySheetState();
}

class _ApiKeySheetState extends State<_ApiKeySheet> {
  final _ctrl = TextEditingController();
  bool _obscure = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    widget.ref
        .read(providersProvider.notifier)
        .getApiKey(widget.provider.id)
        .then((k) {
      if (mounted) _ctrl.text = k;
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.ref
        .read(providersProvider.notifier)
        .saveApiKey(widget.provider.id, _ctrl.text.trim());
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.provider.name} API Key',
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            'Stored securely on device. Never sent anywhere else.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            obscureText: _obscure,
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontFamily: 'monospace'),
            decoration: InputDecoration(
              hintText: 'sk-…',
              hintStyle: const TextStyle(color: AppTheme.textMuted),
              filled: true,
              fillColor: AppTheme.surfaceElevated,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.border)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.accent)),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: AppTheme.textMuted,
                  size: 18,
                ),
              ),
            ),
          ),
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
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Save Key'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
