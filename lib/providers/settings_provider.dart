import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings_model.dart';
import '../models/ai_provider.dart';

const _kSettings = 'app_settings';
const _kProviders = 'ai_providers';
const _storage = FlutterSecureStorage();

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kSettings);
    if (raw == null) return const AppSettings();
    return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(AppSettings Function(AppSettings) fn) async {
    final curr = state.value ?? const AppSettings();
    final next = fn(curr);
    state = AsyncData(next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSettings, jsonEncode(next.toJson()));
  }
}

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

// ── AI Providers ──────────────────────────────────────────────────────────────

class ProvidersNotifier extends AsyncNotifier<List<AIProvider>> {
  @override
  Future<List<AIProvider>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kProviders);
    if (raw == null) return AIProvider.defaults;
    final list = (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
    return list.map(AIProvider.fromJson).toList();
  }

  Future<void> _save(List<AIProvider> providers) async {
    state = AsyncData(providers);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kProviders,
      jsonEncode(providers.map((p) => p.toJson()).toList()),
    );
  }

  Future<void> updateProvider(AIProvider updated) async {
    final list = [...(state.value ?? AIProvider.defaults)];
    final idx = list.indexWhere((p) => p.id == updated.id);
    if (idx >= 0) list[idx] = updated;
    await _save(list);
  }

  Future<void> saveApiKey(String providerId, String key) async {
    await _storage.write(key: 'apikey_$providerId', value: key);
  }

  Future<String> getApiKey(String providerId) async {
    return await _storage.read(key: 'apikey_$providerId') ?? '';
  }
}

final providersProvider =
    AsyncNotifierProvider<ProvidersNotifier, List<AIProvider>>(ProvidersNotifier.new);
