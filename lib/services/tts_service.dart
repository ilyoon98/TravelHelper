import 'package:flutter_tts/flutter_tts.dart';

class TtsUnavailableException implements Exception {
  const TtsUnavailableException();
}

/// Reads phrases aloud with the phone's own TTS engine (works offline once
/// the language's voice data is on the device).
class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  FlutterTts? _tts;
  final Map<String, String> _resolvedLocale = {};

  /// Locales to try, most specific first — engines differ in which regional
  /// variants they ship (e.g. Samsung vs Google for Latin American Spanish).
  static List<String> _candidates(String language, String countryCode) {
    switch (language) {
      case 'en':
        return switch (countryCode) {
          'UK' => ['en-GB', 'en-US'],
          'AU' || 'NZ' => ['en-AU', 'en-GB', 'en-US'],
          'ZA' || 'NA' || 'ZW' || 'ZM' || 'KE' || 'TZ' || 'MU' => ['en-GB', 'en-US'],
          _ => ['en-US', 'en-GB'],
        };
      case 'es':
        return ['es-$countryCode', 'es-MX', 'es-US', 'es-ES'];
      case 'pt':
        return ['pt-BR', 'pt-PT'];
      case 'ar':
        return ['ar-EG', 'ar-SA', 'ar'];
      case 'th':
        return ['th-TH'];
      case 'ja':
        return ['ja-JP'];
      case 'vi':
        return ['vi-VN'];
      case 'id':
        return ['id-ID', 'in-ID'];
      case 'fi':
        return ['fi-FI'];
      default:
        return [language];
    }
  }

  Future<FlutterTts> _engine() async {
    final existing = _tts;
    if (existing != null) return existing;
    final tts = FlutterTts();
    await tts.setSpeechRate(0.42);
    _tts = tts;
    return tts;
  }

  /// Throws [TtsUnavailableException] when the device has no voice for
  /// [language].
  Future<void> speak({
    required String language,
    required String countryCode,
    required String text,
  }) async {
    final tts = await _engine();
    final key = '$language-$countryCode';
    // Misses aren't cached, so a voice downloaded mid-session is picked up.
    var locale = _resolvedLocale[key];
    if (locale == null) {
      for (final candidate in _candidates(language, countryCode)) {
        if (await tts.isLanguageAvailable(candidate) == true) {
          locale = candidate;
          break;
        }
      }
      if (locale == null) throw const TtsUnavailableException();
      _resolvedLocale[key] = locale;
    }
    await tts.stop();
    await tts.setLanguage(locale);
    await tts.speak(text);
  }
}
