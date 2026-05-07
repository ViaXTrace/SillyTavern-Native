enum AIProviderType { openai, anthropic, gemini, ollama, openrouter, custom }

class AIProvider {
  final String id;
  final AIProviderType type;
  final String name;
  final String baseUrl;
  final String model;
  final bool isEnabled;

  const AIProvider({
    required this.id,
    required this.type,
    required this.name,
    required this.baseUrl,
    required this.model,
    this.isEnabled = true,
  });

  static const List<AIProvider> defaults = [
    AIProvider(
      id: 'openai',
      type: AIProviderType.openai,
      name: 'OpenAI',
      baseUrl: 'https://api.openai.com/v1',
      model: 'gpt-4o',
    ),
    AIProvider(
      id: 'anthropic',
      type: AIProviderType.anthropic,
      name: 'Claude',
      baseUrl: 'https://api.anthropic.com/v1',
      model: 'claude-3-5-sonnet-20241022',
    ),
    AIProvider(
      id: 'gemini',
      type: AIProviderType.gemini,
      name: 'Gemini',
      baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
      model: 'gemini-1.5-pro',
    ),
    AIProvider(
      id: 'openrouter',
      type: AIProviderType.openrouter,
      name: 'OpenRouter',
      baseUrl: 'https://openrouter.ai/api/v1',
      model: 'meta-llama/llama-3.1-8b-instruct:free',
    ),
    AIProvider(
      id: 'ollama',
      type: AIProviderType.ollama,
      name: 'Ollama (Local)',
      baseUrl: 'http://localhost:11434/v1',
      model: 'llama3.2',
    ),
  ];

  AIProvider copyWith({
    String? id,
    AIProviderType? type,
    String? name,
    String? baseUrl,
    String? model,
    bool? isEnabled,
  }) {
    return AIProvider(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'name': name,
    'baseUrl': baseUrl,
    'model': model,
    'isEnabled': isEnabled,
  };

  factory AIProvider.fromJson(Map<String, dynamic> j) => AIProvider(
    id: j['id'] as String,
    type: AIProviderType.values.firstWhere(
      (e) => e.name == j['type'],
      orElse: () => AIProviderType.openai,
    ),
    name: j['name'] as String,
    baseUrl: j['baseUrl'] as String,
    model: j['model'] as String,
    isEnabled: j['isEnabled'] as bool? ?? true,
  );

  String get displayModel => model.length > 30 ? '${model.substring(0, 30)}…' : model;
}
