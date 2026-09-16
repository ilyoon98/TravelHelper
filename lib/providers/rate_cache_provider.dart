import 'package:flutter/foundation.dart';

import '../models/rate_cache.dart';
import '../services/exchange_rate_service.dart';

/// One global live-rate snapshot shared by every country/currency — see
/// [RateCache] for why a single refresh covers all of them at once.
///
/// Refreshing is rate-limited: a successful fetch starts a cooldown so users
/// can't hammer the free API by mashing the button, and it doubles as the
/// natural slot for a rewarded-ad gate later (ad shown once per cooldown
/// instead of every tap). A *failed* attempt does not start the cooldown —
/// people should be able to retry right away.
class RateCacheProvider extends ChangeNotifier {
  static const cooldown = Duration(minutes: 5);

  RateCache? _cache;
  bool _loaded = false;

  DateTime? get lastUpdateAt => _cache?.updatedAt;
  bool get hasCache => _cache != null;

  /// Null when refresh is allowed right now.
  Duration? get remainingCooldown {
    final last = _cache?.updatedAt;
    if (last == null) return null;
    final remaining = cooldown - DateTime.now().difference(last);
    return remaining.isNegative ? null : remaining;
  }

  bool get canRefresh => remainingCooldown == null;

  double? rateFor(String currencyCode) => _cache?.rates[currencyCode];

  Future<void> load() async {
    if (_loaded) return;
    _cache = await ExchangeRateService.instance.loadCached();
    _loaded = true;
    notifyListeners();
  }

  /// Throws [ExchangeRateException] on failure — the caller shows it to the user.
  Future<void> refreshAll() async {
    if (!canRefresh) {
      throw ExchangeRateException('잠시 후 다시 시도해주세요');
    }
    _cache = await ExchangeRateService.instance.fetchAndCacheAll();
    notifyListeners();
  }

  Future<void> resetAll() async {
    await ExchangeRateService.instance.clear();
    _cache = null;
    notifyListeners();
  }
}
