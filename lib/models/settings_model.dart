class AppSettings {
  final String activeProviderId;
  final String activeCharacterId;
  final bool enableVRM;
  final bool enableTTS;
  final String ttsLanguage;
  final double ttsPitch;
  final double ttsRate;
  final double ttsVolume;
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
    this.ttsLanguage = 'en-US',
    this.ttsPitch = 1.0,
    this.ttsRate = 0.5,
    this.ttsVolume = 1.0,
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
    String? ttsLanguage,
    double? ttsPitch,
    double? ttsRate,
    double? ttsVolume,
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
      ttsLanguage: ttsLanguage ?? this.ttsLanguage,
      ttsPitch: ttsPitch ?? this.ttsPitch,
      ttsRate: ttsRate ?? this.ttsRate,
      ttsVolume: ttsVolume ?? this.ttsVolume,
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
    'ttsLanguage': ttsLanguage,
    'ttsPitch': ttsPitch,
    'ttsRate': ttsRate,
    'ttsVolume': ttsVolume,
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
    ttsLanguage: j['ttsLanguage'] as String? ?? 'en-US',
    ttsPitch: (j['ttsPitch'] as num?)?.toDouble() ?? 1.0,
    ttsRate: (j['ttsRate'] as num?)?.toDouble() ?? 0.5,
    ttsVolume: (j['ttsVolume'] as num?)?.toDouble() ?? 1.0,
    streamResponses: j['streamResponses'] as bool? ?? true,
    maxContextMessages: j['maxContextMessages'] as int? ?? 20,
    temperature: (j['temperature'] as num?)?.toDouble() ?? 0.8,
    maxTokens: j['maxTokens'] as int? ?? 1024,
    systemPromptTemplate: j['systemPromptTemplate'] as String? ?? '',
    hapticFeedback: j['hapticFeedback'] as bool? ?? true,
    showTimestamps: j['showTimestamps'] as bool? ?? false,
  );
}
