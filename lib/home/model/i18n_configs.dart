class I18nConfigs {
  final String defaultLocale;
  final String filePrefix;

  const I18nConfigs({this.defaultLocale = 'en', this.filePrefix = 'strings'});

  factory I18nConfigs.fromMap(Map<String, dynamic> map) {
    return I18nConfigs(
      defaultLocale: map['default_locale'] as String? ?? 'en',
      filePrefix: map['file_prefix'] as String? ?? 'strings',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'default_locale': defaultLocale,
      'file_prefix': filePrefix,
    };
  }

  I18nConfigs copyWith({
    String? defaultLocale,
    String? filePrefix,
  }) {
    return I18nConfigs(
      defaultLocale: defaultLocale ?? this.defaultLocale,
      filePrefix: filePrefix ?? this.filePrefix,
    );
  }

  @override
  String toString() {
    return 'defaultLocale: $defaultLocale, filePrefix: $filePrefix';
  }
}
