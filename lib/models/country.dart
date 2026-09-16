class CountryMeta {
  final String code;
  final String name;
  final String nameEn;
  final String flag;
  final String? language;
  final String region;
  final bool hasNumbers;
  final bool hasPhrases;

  const CountryMeta({
    required this.code,
    required this.name,
    required this.nameEn,
    required this.flag,
    required this.language,
    required this.region,
    required this.hasNumbers,
    required this.hasPhrases,
  });

  factory CountryMeta.fromJson(Map<String, dynamic> json) {
    return CountryMeta(
      code: json['code'] as String,
      name: json['name'] as String,
      nameEn: json['nameEn'] as String,
      flag: json['flag'] as String,
      language: json['language'] as String?,
      region: json['region'] as String,
      hasNumbers: json['hasNumbers'] as bool,
      hasPhrases: json['hasPhrases'] as bool,
    );
  }
}
