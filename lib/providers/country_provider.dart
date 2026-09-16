import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/country.dart';
import '../services/data_service.dart';

/// Shared "selected country" state — tabs 1 (숫자) and 3 (회화) read/write
/// this single provider so switching country in one tab updates the other
/// immediately (per spec section 2). 환율 has its own independent left/right
/// selectors (see currency_tab.dart) and only reads this once as its initial
/// left-side default. The selection is persisted so it survives an app
/// restart instead of always starting back at the hardcoded default.
class CountryProvider extends ChangeNotifier {
  static const _prefKey = 'selected_country_code';

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
    try {
      final prefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 2));
      final saved = prefs.getString(_prefKey);
      if (saved != null && _countries.any((c) => c.code == saved)) {
        _selectedCode = saved;
      }
    } catch (_) {
      // No saved selection this session — just keep the hardcoded default.
    }
    _loaded = true;
    notifyListeners();
  }

  void select(String code) {
    if (code == _selectedCode) return;
    _selectedCode = code;
    notifyListeners();
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setString(_prefKey, code))
        .catchError((_) => false);
  }
}
