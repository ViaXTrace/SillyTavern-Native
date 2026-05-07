import 'dart:io';

class Character {
  final String id;
  final String name;
  final String description;
  final String personality;
  final String scenario;
  final String firstMessage;
  final String systemPrompt;
  final String? avatarPath;
  final String? vrmPath;
  final String? vrmAnimation;
  final Map<String, dynamic> raw;

  const Character({
    required this.id,
    required this.name,
    this.description = '',
    this.personality = '',
    this.scenario = '',
    this.firstMessage = '',
    this.systemPrompt = '',
    this.avatarPath,
    this.vrmPath,
    this.vrmAnimation,
    this.raw = const {},
  });

  String get initials =>
      name.trim().isNotEmpty ? name.trim().substring(0, name.trim().length > 1 ? 2 : 1).toUpperCase() : '?';

  bool get hasVRM => vrmPath != null && vrmPath!.isNotEmpty;

  bool get hasAvatar => avatarPath != null && File(avatarPath!).existsSync();

  /// Build the system prompt used when chatting
  String buildSystemPrompt() {
    final parts = <String>[];
    if (systemPrompt.isNotEmpty) parts.add(systemPrompt);
    if (description.isNotEmpty) parts.add('Description: $description');
    if (personality.isNotEmpty) parts.add('Personality: $personality');
    if (scenario.isNotEmpty) parts.add('Scenario: $scenario');
    return parts.join('\n\n');
  }

  Character copyWith({
    String? name,
    String? description,
    String? personality,
    String? scenario,
    String? firstMessage,
    String? systemPrompt,
    String? avatarPath,
    String? vrmPath,
    String? vrmAnimation,
  }) {
    return Character(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      personality: personality ?? this.personality,
      scenario: scenario ?? this.scenario,
      firstMessage: firstMessage ?? this.firstMessage,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      avatarPath: avatarPath ?? this.avatarPath,
      vrmPath: vrmPath ?? this.vrmPath,
      vrmAnimation: vrmAnimation ?? this.vrmAnimation,
      raw: raw,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'personality': personality,
    'scenario': scenario,
    'firstMessage': firstMessage,
    'systemPrompt': systemPrompt,
    'avatarPath': avatarPath,
    'vrmPath': vrmPath,
    'vrmAnimation': vrmAnimation,
  };

  factory Character.fromJson(Map<String, dynamic> j) => Character(
    id: j['id'] as String? ?? j['name'] as String? ?? '',
    name: j['name'] as String? ?? 'Unknown',
    description: j['description'] as String? ?? '',
    personality: j['personality'] as String? ?? '',
    scenario: j['scenario'] as String? ?? '',
    firstMessage: j['firstMessage'] as String? ?? j['first_mes'] as String? ?? '',
    systemPrompt: j['systemPrompt'] as String? ?? j['system_prompt'] as String? ?? '',
    avatarPath: j['avatarPath'] as String?,
    vrmPath: j['vrmPath'] as String?,
    vrmAnimation: j['vrmAnimation'] as String?,
    raw: j,
  );
}
