class CurrencyOption {
  final String currency;
  final String symbol;
  final double rateToKrw;

  const CurrencyOption({
    required this.currency,
    required this.symbol,
    required this.rateToKrw,
  });

  factory CurrencyOption.fromJson(Map<String, dynamic> json) {
    return CurrencyOption(
      currency: json['currency'] as String,
      symbol: json['symbol'] as String,
      rateToKrw: (json['rate_to_krw'] as num).toDouble(),
    );
  }
}

class CountryCurrency {
  final String code;
  final String name;
  final List<CurrencyOption> currencies;

  const CountryCurrency({
    required this.code,
    required this.name,
    required this.currencies,
  });

  factory CountryCurrency.fromJson(Map<String, dynamic> json) {
    final rawList = json['currencies'] as List<dynamic>;
    return CountryCurrency(
      code: json['code'] as String,
      name: json['name'] as String,
      currencies: rawList
          .map((e) => CurrencyOption.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
