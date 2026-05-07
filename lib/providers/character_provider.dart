import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../models/character_model.dart';

class CharacterNotifier extends AsyncNotifier<List<Character>> {
  late Directory _dir;

  @override
  Future<List<Character>> build() async {
    final docs = await getApplicationDocumentsDirectory();
    _dir = Directory('${docs.path}/characters');
    if (!_dir.existsSync()) _dir.createSync(recursive: true);
    return _loadAll();
  }

  Future<List<Character>> _loadAll() async {
    final files = _dir.listSync().whereType<File>().where((f) => f.path.endsWith('.json'));
    final chars = <Character>[];
    for (final f in files) {
      try {
        final json = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        chars.add(Character.fromJson(json));
      } catch (_) {}
    }
    chars.sort((a, b) => a.name.compareTo(b.name));
    return chars;
  }

  Future<void> add(Character char) async {
    final file = File('${_dir.path}/${char.id}.json');
    await file.writeAsString(jsonEncode(char.toJson()));
    state = AsyncData([...(state.value ?? []), char]..sort((a, b) => a.name.compareTo(b.name)));
  }

  Future<void> saveCharacter(Character char) async {
    final file = File('${_dir.path}/${char.id}.json');
    await file.writeAsString(jsonEncode(char.toJson()));
    final list = [...(state.value ?? [])];
    final idx = list.indexWhere((c) => c.id == char.id);
    if (idx >= 0) list[idx] = char;
    state = AsyncData(list);
  }

  Future<void> delete(String id) async {
    final file = File('${_dir.path}/$id.json');
    if (file.existsSync()) file.deleteSync();
    state = AsyncData((state.value ?? []).where((c) => c.id != id).toList());
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _loadAll());
  }

  /// Import a SillyTavern-format character card JSON
  Future<Character> importFromJson(Map<String, dynamic> json) async {
    final char = Character.fromJson(json);
    await add(char);
    return char;
  }
}

final characterProvider =
    AsyncNotifierProvider<CharacterNotifier, List<Character>>(CharacterNotifier.new);
