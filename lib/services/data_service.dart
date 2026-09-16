import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import '../models/country.dart';
import '../models/currency_data.dart';
import '../models/number_data.dart';
import '../models/phrase_data.dart';

/// Loads country metadata and per-country data files bundled as assets.
/// Data ships inside the app and only changes via an app update (no backend).
class DataService {
  DataService._();
  static final DataService instance = DataService._();

  List<CountryMeta>? _countries;
  final Map<String, CountryNumbers> _numbersCache = {};
  final Map<String, CountryCurrency> _currencyCache = {};
  final Map<String, CountryPhrases> _phrasesCache = {};

  Future<List<CountryMeta>> loadCountries() async {
    if (_countries != null) return _countries!;
    final raw = await rootBundle.loadString('assets/data/countries.json');
    final list = jsonDecode(raw) as List<dynamic>;
    _countries = list
        .map((e) => CountryMeta.fromJson(e as Map<String, dynamic>))
        .toList();
    return _countries!;
  }

  Future<CountryNumbers> loadNumbers(String code) async {
    final cached = _numbersCache[code];
    if (cached != null) return cached;
    final raw = await rootBundle.loadString('assets/data/numbers/$code.json');
    final data = CountryNumbers.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    _numbersCache[code] = data;
    return data;
  }

  Future<CountryCurrency> loadCurrency(String code) async {
    final cached = _currencyCache[code];
    if (cached != null) return cached;
    final raw = await rootBundle.loadString('assets/data/currency/$code.json');
    final data = CountryCurrency.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    _currencyCache[code] = data;
    return data;
  }

  Future<CountryPhrases> loadPhrases(String code) async {
    final cached = _phrasesCache[code];
    if (cached != null) return cached;
    final raw = await rootBundle.loadString('assets/data/phrases/$code.json');
    final data = CountryPhrases.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    _phrasesCache[code] = data;
    return data;
  }
}
