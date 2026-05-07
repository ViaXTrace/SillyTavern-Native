class AppSettings {
  final String activeProviderId;
  final String activeCharacterId;
  final bool enableVRM;
  final bool enableTTS;
  final bool streamResponses;
  final int maxContextMessages;
  final double temperature;
  final int maxTokens;
  final String systemPromptTemplate;
  final bool hapticFeedback;
  final bool showTimestamps;

  const AppSettings({
    this.activeProviderId = 'openrouter',
    this.activeCharacterId = '',
    this.enableVRM = true,
    this.enableTTS = false,
    this.streamResponses = true,
    this.maxContextMessages = 20,
    this.temperature = 0.8,
    this.maxTokens = 1024,
    this.systemPromptTemplate = '',
    this.hapticFeedback = true,
    this.showTimestamps = false,
  });

  AppSettings copyWith({
    String? activeProviderId,
    String? activeCharacterId,
    bool? enableVRM,
    bool? enableTTS,
    bool? streamResponses,
    int? maxContextMessages,
    double? temperature,
    int? maxTokens,
    String? systemPromptTemplate,
    bool? hapticFeedback,
    bool? showTimestamps,
  }) {
    return AppSettings(
      activeProviderId: activeProviderId ?? this.activeProviderId,
      activeCharacterId: activeCharacterId ?? this.activeCharacterId,
      enableVRM: enableVRM ?? this.enableVRM,
      enableTTS: enableTTS ?? this.enableTTS,
      streamResponses: streamResponses ?? this.streamResponses,
      maxContextMessages: maxContextMessages ?? this.maxContextMessages,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      systemPromptTemplate: systemPromptTemplate ?? this.systemPromptTemplate,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      showTimestamps: showTimestamps ?? this.showTimestamps,
    );
  }

  Map<String, dynamic> toJson() => {
    'activeProviderId': activeProviderId,
    'activeCharacterId': activeCharacterId,
    'enableVRM': enableVRM,
    'enableTTS': enableTTS,
    'streamResponses': streamResponses,
    'maxContextMessages': maxContextMessages,
    'temperature': temperature,
    'maxTokens': maxTokens,
    'systemPromptTemplate': systemPromptTemplate,
    'hapticFeedback': hapticFeedback,
    'showTimestamps': showTimestamps,
  };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
    activeProviderId: j['activeProviderId'] as String? ?? 'openrouter',
    activeCharacterId: j['activeCharacterId'] as String? ?? '',
    enableVRM: j['enableVRM'] as bool? ?? true,
    enableTTS: j['enableTTS'] as bool? ?? false,
    streamResponses: j['streamResponses'] as bool? ?? true,
    maxContextMessages: j['maxContextMessages'] as int? ?? 20,
    temperature: (j['temperature'] as num?)?.toDouble() ?? 0.8,
    maxTokens: j['maxTokens'] as int? ?? 1024,
    systemPromptTemplate: j['systemPromptTemplate'] as String? ?? '',
    hapticFeedback: j['hapticFeedback'] as bool? ?? true,
    showTimestamps: j['showTimestamps'] as bool? ?? false,
  );
}
