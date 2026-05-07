import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../providers/settings_provider.dart';
import 'home_screen.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  int _step = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: _step == 0 ? _WelcomeStep(onNext: () => setState(() => _step = 1)) : _ProviderStep(onDone: _finish),
      ),
    );
  }

  void _finish() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  final VoidCallback onNext;
  const _WelcomeStep({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Spacer(flex: 2),
          Container(
            width: 96, height: 96,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
              ),
              boxShadow: [BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.4), blurRadius: 32, spreadRadius: 0)],
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 48),
          ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
          const SizedBox(height: 32),
          const Text('SillyTavern', style: TextStyle(color: AppTheme.textPrimary, fontSize: 36, fontWeight: FontWeight.w700, letterSpacing: -1)).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 12),
          const Text(
            'Your AI companion with VRM characters.\nNo server needed — connects directly to AI APIs.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 16, height: 1.6),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 400.ms),
          const Spacer(flex: 3),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18)),
              child: const Text('Get Started', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
            },
            child: const Text('Skip setup', style: TextStyle(color: AppTheme.textMuted)),
          ).animate().fadeIn(delay: 700.ms),
        ],
      ),
    );
  }
}

class _ProviderStep extends ConsumerStatefulWidget {
  final VoidCallback onDone;
  const _ProviderStep({required this.onDone});

  @override
  ConsumerState<_ProviderStep> createState() => _ProviderStepState();
}

class _ProviderStepState extends ConsumerState<_ProviderStep> {
  String _selectedId = 'openrouter';
  final _keyCtrl = TextEditingController();

  @override
  void dispose() {
    _keyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_keyCtrl.text.trim().isNotEmpty) {
      await ref.read(providersProvider.notifier).saveApiKey(_selectedId, _keyCtrl.text.trim());
    }
    await ref.read(settingsProvider.notifier).save((s) => s.copyWith(activeProviderId: _selectedId));
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final providers = ref.watch(providersProvider).value ?? [];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Choose AI Provider', style: TextStyle(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
          const SizedBox(height: 6),
          const Text('You can change this anytime in Settings.', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
          const SizedBox(height: 24),
          ...providers.map((p) => _ProviderOption(
            provider: p,
            isSelected: _selectedId == p.id,
            onTap: () => setState(() => _selectedId = p.id),
          )),
          const SizedBox(height: 24),
          const Text('API Key', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          TextField(
            controller: _keyCtrl,
            obscureText: true,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontFamily: 'monospace'),
            decoration: InputDecoration(
              hintText: 'Paste your API key here',
              hintStyle: const TextStyle(color: AppTheme.textMuted),
              filled: true, fillColor: AppTheme.surfaceElevated,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.accent)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedId == 'openrouter' ? 'Free models available at openrouter.ai' : _selectedId == 'ollama' ? 'No key needed for local Ollama' : 'Get your key from the provider\'s website',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18)),
              child: const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderOption extends StatelessWidget {
  final dynamic provider;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProviderOption({required this.provider, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accent.withOpacity(0.1) : AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppTheme.accent : AppTheme.border, width: isSelected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Text(provider.name, style: TextStyle(color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, fontSize: 15)),
            const Spacer(),
            if (isSelected) const Icon(Icons.check_rounded, color: AppTheme.accent, size: 20),
          ],
        ),
      ),
    );
  }
}
