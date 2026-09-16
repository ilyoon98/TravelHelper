class NumberEntry {
  final String native;
  final String pronunciation;
  final String korean;

  const NumberEntry({
    required this.native,
    required this.pronunciation,
    required this.korean,
  });

  factory NumberEntry.fromJson(Map<String, dynamic> json) {
    return NumberEntry(
      native: json['native'] as String,
      pronunciation: json['pronunciation'] as String,
      korean: json['korean'] as String,
    );
  }
}

class CountryNumbers {
  final String code;
  final String language;
  final Map<String, NumberEntry> digits;

  const CountryNumbers({
    required this.code,
    required this.language,
    required this.digits,
  });

  factory CountryNumbers.fromJson(Map<String, dynamic> json) {
    final rawDigits = json['numbers'] as Map<String, dynamic>;
    return CountryNumbers(
      code: json['code'] as String,
      language: json['language'] as String,
      digits: rawDigits.map(
        (key, value) => MapEntry(key, NumberEntry.fromJson(value as Map<String, dynamic>)),
      ),
    );
  }
}
