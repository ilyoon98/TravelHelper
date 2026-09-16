import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/rate_cache.dart';

class ExchangeRateException implements Exception {
  final String message;
  ExchangeRateException(this.message);

  @override
  String toString() => message;
}

/// Fetches live rates (free, no API key) for every currency in a single
/// request and caches the whole snapshot locally. Rate priority is
/// "cached live value > hardcoded default" (spec section 5) — the hardcoded
/// fallback lives in the currency tab, this service only ever returns what
/// it could actually fetch.
class ExchangeRateService {
  ExchangeRateService._();
  static final ExchangeRateService instance = ExchangeRateService._();

  static const _cacheKey = 'rate_cache_v2_global';

  Future<RateCache?> loadCached() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null) return null;
    try {
      return RateCache.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null; // Ignore a corrupted cache rather than failing startup.
    }
  }

  /// Fetches KRW-based rates for every currency the API knows about and
  /// caches the whole snapshot at once — one tap refreshes every country.
  Future<RateCache> fetchAndCacheAll() async {
    final http.Response resp;
    try {
      resp = await http
          .get(Uri.parse('https://open.er-api.com/v6/latest/KRW'))
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      throw ExchangeRateException('인터넷 연결을 확인해주세요');
    }
    if (resp.statusCode != 200) {
      throw ExchangeRateException('환율 서버 응답 오류 (${resp.statusCode})');
    }
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    if (body['result'] != 'success') {
      throw ExchangeRateException('환율 정보를 가져오지 못했습니다');
    }
    final rawRates = body['rates'] as Map<String, dynamic>;
    final rates = <String, double>{};
    rawRates.forEach((code, v) {
      if (v is num && v > 0) rates[code] = 1 / v.toDouble();
    });
    if (rates.isEmpty) {
      throw ExchangeRateException('환율 정보를 가져오지 못했습니다');
    }

    final cache = RateCache(updatedAt: DateTime.now(), rates: rates);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(cache.toJson()));
    return cache;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
  }
}
