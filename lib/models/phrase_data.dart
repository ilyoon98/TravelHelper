class PhraseItem {
  final String korean;
  final String native;
  final String pronunciation;
  final String koreanPron;

  const PhraseItem({
    required this.korean,
    required this.native,
    required this.pronunciation,
    required this.koreanPron,
  });

  factory PhraseItem.fromJson(Map<String, dynamic> json) {
    return PhraseItem(
      korean: json['korean'] as String,
      native: json['native'] as String,
      pronunciation: json['pronunciation'] as String,
      koreanPron: json['korean_pron'] as String,
    );
  }
}

class PhraseCategory {
  final String category;
  final List<PhraseItem> phrases;

  const PhraseCategory({required this.category, required this.phrases});

  factory PhraseCategory.fromJson(Map<String, dynamic> json) {
    final rawList = json['phrases'] as List<dynamic>;
    return PhraseCategory(
      category: json['category'] as String,
      phrases: rawList
          .map((e) => PhraseItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CountryPhrases {
  final String code;
  final String name;
  final List<PhraseCategory> categories;

  const CountryPhrases({
    required this.code,
    required this.name,
    required this.categories,
  });

  factory CountryPhrases.fromJson(Map<String, dynamic> json) {
    final rawList = json['categories'] as List<dynamic>;
    return CountryPhrases(
      code: json['code'] as String,
      name: json['name'] as String,
      categories: rawList
          .map((e) => PhraseCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
