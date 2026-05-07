import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../models/ai_provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value;
    final providers = ref.watch(providersProvider).value ?? [];

    if (settings == null) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
    }

    final active = providers.firstWhere(
      (p) => p.id == settings.activeProviderId,
      orElse: () => providers.isNotEmpty ? providers.first : AIProvider.defaults.first,
    );

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Settings', style: TextStyle(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
            const SizedBox(height: 24),

            // AI Provider
            _Section(
              title: 'AI Provider',
              child: Column(
                children: providers.map((p) {
                  final isActive = p.id == settings.activeProviderId;
                  return _ProviderTile(
                    provider: p,
                    isActive: isActive,
                    onTap: () => _selectProvider(context, ref, p),
                    onEditKey: () => _editApiKey(context, ref, p),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // Model settings
            _Section(
              title: 'Generation',
              child: Column(
                children: [
                  _SliderTile(
                    label: 'Temperature',
                    value: settings.temperature,
                    min: 0, max: 2, divisions: 20,
                    onChanged: (v) => ref.read(settingsProvider.notifier).update((s) => s.copyWith(temperature: v)),
                  ),
                  _SliderTile(
                    label: 'Max Tokens',
                    value: settings.maxTokens.toDouble(),
                    min: 128, max: 4096, divisions: 31,
                    format: (v) => v.round().toString(),
                    onChanged: (v) => ref.read(settingsProvider.notifier).update((s) => s.copyWith(maxTokens: v.round())),
                  ),
                  _SliderTile(
                    label: 'Context Messages',
                    value: settings.maxContextMessages.toDouble(),
                    min: 4, max: 100, divisions: 24,
                    format: (v) => v.round().toString(),
                    onChanged: (v) => ref.read(settingsProvider.notifier).update((s) => s.copyWith(maxContextMessages: v.round())),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Display
            _Section(
              title: 'Display',
              child: Column(
                children: [
                  _SwitchTile(
                    label: 'VRM Character',
                    subtitle: 'Show 3D character viewer',
                    icon: Icons.view_in_ar_rounded,
                    value: settings.enableVRM,
                    onChanged: (v) => ref.read(settingsProvider.notifier).update((s) => s.copyWith(enableVRM: v)),
                  ),
                  _SwitchTile(
                    label: 'Show Timestamps',
                    subtitle: 'Display time on each message',
                    icon: Icons.access_time_rounded,
                    value: settings.showTimestamps,
                    onChanged: (v) => ref.read(settingsProvider.notifier).update((s) => s.copyWith(showTimestamps: v)),
                  ),
                  _SwitchTile(
                    label: 'Haptic Feedback',
                    subtitle: 'Vibration on send',
                    icon: Icons.vibration_rounded,
                    value: settings.hapticFeedback,
                    onChanged: (v) => ref.read(settingsProvider.notifier).update((s) => s.copyWith(hapticFeedback: v)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // App info
            const Center(
              child: Column(
                children: [
                  Text('SillyTavern Native', style: TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
                  SizedBox(height: 2),
                  Text('v1.0.0', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectProvider(BuildContext context, WidgetRef ref, AIProvider p) {
    ref.read(settingsProvider.notifier).update((s) => s.copyWith(activeProviderId: p.id));
  }

  void _editApiKey(BuildContext context, WidgetRef ref, AIProvider p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ApiKeySheet(provider: p, ref: ref),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
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

  const _ProviderTile({required this.provider, required this.isActive, required this.onTap, required this.onEditKey});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: isActive ? AppTheme.accent.withOpacity(0.15) : AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.auto_awesome, color: isActive ? AppTheme.accent : AppTheme.textMuted, size: 18),
      ),
      title: Text(provider.name, style: TextStyle(color: isActive ? AppTheme.textPrimary : AppTheme.textSecondary, fontWeight: isActive ? FontWeight.w600 : FontWeight.w400, fontSize: 14)),
      subtitle: Text(provider.displayModel, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(onPressed: onEditKey, icon: const Icon(Icons.key_rounded, size: 18, color: AppTheme.textMuted)),
          if (isActive) const Icon(Icons.check_circle_rounded, color: AppTheme.accent, size: 20),
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

  const _SwitchTile({required this.label, required this.subtitle, required this.icon, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: AppTheme.surfaceElevated, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppTheme.textSecondary, size: 18),
      ),
      title: Text(label, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.accent,
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppTheme.accent.withOpacity(0.3);
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

  const _SliderTile({required this.label, required this.value, required this.min, required this.max, required this.divisions, this.format, required this.onChanged});

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
              Text(label, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
              Text(fmt(value), style: const TextStyle(color: AppTheme.accent, fontSize: 14, fontWeight: FontWeight.w600)),
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
            child: Slider(value: value.clamp(min, max), min: min, max: max, divisions: divisions, onChanged: onChanged),
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
    widget.ref.read(providersProvider.notifier).getApiKey(widget.provider.id).then((k) {
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
    await widget.ref.read(providersProvider.notifier).saveApiKey(widget.provider.id, _ctrl.text.trim());
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${widget.provider.name} API Key', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Stored securely on device. Never sent anywhere else.', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            obscureText: _obscure,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontFamily: 'monospace'),
            decoration: InputDecoration(
              hintText: 'sk-...',
              hintStyle: const TextStyle(color: AppTheme.textMuted),
              filled: true,
              fillColor: AppTheme.surfaceElevated,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.accent)),
              suffixIcon: IconButton(onPressed: () => setState(() => _obscure = !_obscure), icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: AppTheme.textMuted, size: 18)),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save Key'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
