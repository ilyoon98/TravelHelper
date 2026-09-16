/// Live exchange rates cached locally. One global snapshot covers every
/// currency at once (the API returns all of them in a single call), so
/// refreshing once applies to every country — including countries that
/// share a currency (e.g. UK's GBP/EUR, or USD used by several countries).
class RateCache {
  final DateTime updatedAt;

  /// currency code -> 1 unit of that currency in KRW.
  final Map<String, double> rates;

  const RateCache({required this.updatedAt, required this.rates});

  Map<String, dynamic> toJson() => {
        'updatedAt': updatedAt.toIso8601String(),
        'rates': rates,
      };

  factory RateCache.fromJson(Map<String, dynamic> json) {
    final rawRates = json['rates'] as Map<String, dynamic>;
    return RateCache(
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      rates: rawRates.map((k, v) => MapEntry(k, (v as num).toDouble())),
    );
  }
}
