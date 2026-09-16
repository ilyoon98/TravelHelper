import 'package:flutter/foundation.dart';

import '../models/country.dart';
import '../services/data_service.dart';

/// Shared "selected country" state — tabs 1 (숫자), 2 (환율) and 3 (회화)
/// all read/write this single provider so switching country in one tab
/// updates the other two immediately (per spec section 2).
class CountryProvider extends ChangeNotifier {
  List<CountryMeta> _countries = [];
  String _selectedCode = 'TH';
  bool _loaded = false;

  List<CountryMeta> get countries => _countries;
  bool get loaded => _loaded;
  String get selectedCode => _selectedCode;

  CountryMeta get selected =>
      _countries.firstWhere((c) => c.code == _selectedCode, orElse: () => _countries.first);

  /// Countries usable for tabs 1/3 (number & phrase data) — excludes EUR,
  /// which is a currency-only entry (spec section 10).
  List<CountryMeta> get countriesWithContent =>
      _countries.where((c) => c.hasNumbers).toList();

  Future<void> load() async {
    if (_loaded) return;
    _countries = await DataService.instance.loadCountries();
    _loaded = true;
    notifyListeners();
  }

  void select(String code) {
    if (code == _selectedCode) return;
    _selectedCode = code;
    notifyListeners();
  }
}
