import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/country.dart';
import '../models/currency_data.dart';
import '../providers/country_provider.dart';
import '../providers/rate_cache_provider.dart';
import '../services/ad_service.dart';
import '../services/data_service.dart';
import '../services/exchange_rate_service.dart';
import '../services/number_to_words.dart' show commaFormat;
import 'country_picker_sheet.dart';
import 'widgets/anchored_numpad_layout.dart';
import 'widgets/numpad.dart';

/// 탭2 — 환율 계산. 왼쪽/오른쪽 통화를 각각 독립적으로 고를 수 있는 일반
/// 변환기 — 왼쪽은 항상 "내가 입력하는 통화", 오른쪽은 "계산된 결과", 가운데
/// 스왑 버튼으로 둘을 맞바꾼다. 그래서 탭1·3처럼 헤더의 공유 국가 선택을
/// 쓰지 않는다 (설정 탭과 같은 이유로 AppHeader 미사용) — 처음 진입할 때만
/// 공유 선택 국가를 왼쪽 기본값으로 가져오고, 그 뒤로는 완전히 독립적이다.
///
/// "🔄 최신 환율 받기"는 리워드 광고를 끝까지 봐야 API를 호출한다 (spec
/// section 5). 한 번의 API 호출로 전체 통화를 한꺼번에 갱신하므로
/// (RateCacheProvider 참고) 어느 쪽 통화를 고르든 새로 받을 필요가 없고,
/// 성공한 갱신마다 [RateCacheProvider.cooldown] 동안 다시 누를 수 없다.
///
/// 이 앱은 오프라인이 기본이므로 인터넷이 없어도 하드코딩 기본값으로 계속
/// 쓸 수 있어야 한다 — 갱신 실패는 팝업으로만 알리고 화면을 막지 않는다.
class CurrencyTab extends StatefulWidget {
  const CurrencyTab({super.key});

  @override
  State<CurrencyTab> createState() => _CurrencyTabState();
}

class _CurrencyTabState extends State<CurrencyTab> {
  String _input = '';
  bool _refreshing = false;
  Timer? _cooldownTicker;
  bool _initStarted = false;

  CountryMeta? _leftCountry;
  CountryMeta? _rightCountry;
  CountryCurrency? _leftCurrency;
  CountryCurrency? _rightCurrency;
  int _leftIndex = 0;
  int _rightIndex = 0;
  Timer? _adRetryTimer;

  @override
  void initState() {
    super.initState();
    // Keeps a rewarded ad topped up while this tab is around, so tapping
    // "최신 환율 받기" doesn't usually hit "광고 준비 중" — tied to this
    // widget's lifecycle (not a permanent service-level timer) so it stops
    // the moment the tab goes away instead of running for the whole app.
    _adRetryTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      context.read<AdService>().ensureRewardedAdLoading();
    });
  }

  @override
  void dispose() {
    _adRetryTimer?.cancel();
    _cooldownTicker?.cancel();
    super.dispose();
  }

  Future<void> _initDefaults(CountryProvider provider) async {
    _initStarted = true;
    final leftMeta = provider.selected;
    final krwMeta = provider.countries.firstWhere((c) => c.code == 'KR');
    final leftData = await DataService.instance.loadCurrency(leftMeta.code);
    final rightData = await DataService.instance.loadCurrency(krwMeta.code);
    if (!mounted) return;
    setState(() {
      _leftCountry = leftMeta;
      _rightCountry = krwMeta;
      _leftCurrency = leftData;
      _rightCurrency = rightData;
    });
  }

  Future<void> _pickCountry(bool isLeft) async {
    final provider = context.read<CountryProvider>();
    final current = (isLeft ? _leftCountry : _rightCountry)!;
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => CountryPickerSheet(
          countries: provider.countries,
          selectedCode: current.code,
        ),
        fullscreenDialog: true,
      ),
    );
    if (code == null || code == current.code) return;
    final meta = provider.countries.firstWhere((c) => c.code == code);
    final data = await DataService.instance.loadCurrency(code);
    if (!mounted) return;
    setState(() {
      if (isLeft) {
        _leftCountry = meta;
        _leftCurrency = data;
        _leftIndex = 0;
      } else {
        _rightCountry = meta;
        _rightCurrency = data;
        _rightIndex = 0;
      }
    });
  }

  void _swap() {
    setState(() {
      final tc = _leftCountry;
      _leftCountry = _rightCountry;
      _rightCountry = tc;
      final td = _leftCurrency;
      _leftCurrency = _rightCurrency;
      _rightCurrency = td;
      final ti = _leftIndex;
      _leftIndex = _rightIndex;
      _rightIndex = ti;
    });
  }

  void _onDigit(String d) {
    setState(() {
      if (_input == '0') {
        _input = d;
      } else if ((_input + d).length <= 15) {
        _input = _input + d;
      }
    });
  }

  void _onBackspace() {
    if (_input.isEmpty) return;
    setState(() => _input = _input.substring(0, _input.length - 1));
  }

  void _onClear() => setState(() => _input = '');

  void _ensureCooldownTicker(bool active) {
    if (active && _cooldownTicker == null) {
      _cooldownTicker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (!active && _cooldownTicker != null) {
      _cooldownTicker!.cancel();
      _cooldownTicker = null;
    }
  }

  Future<void> _onRefresh() async {
    setState(() => _refreshing = true);
    try {
      final earned = await context.read<AdService>().showRewardedAd();
      if (!earned) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('광고를 끝까지 시청해야 환율을 받을 수 있어요')),
          );
        }
        return;
      }
      if (!mounted) return;
      await context.read<RateCacheProvider>().refreshAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('전체 통화의 최신 환율을 받아왔습니다')),
        );
      }
    } on AdNotReadyException {
      if (mounted) _showFailureDialog('광고를 준비하는 중입니다. 잠시 후 다시 시도해주세요');
    } on ExchangeRateException catch (e) {
      if (mounted) _showFailureDialog(e.message);
    } catch (_) {
      if (mounted) _showFailureDialog('환율을 갱신하지 못했습니다');
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  void _showFailureDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('최신 환율 받기 실패'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  /// Merges the hardcoded default with the global live cache, per currency.
  CurrencyOption _effectiveOption(CurrencyOption option, RateCacheProvider rateCache) {
    final live = rateCache.rateFor(option.currency);
    if (live == null) return option;
    return CurrencyOption(currency: option.currency, symbol: option.symbol, rateToKrw: live);
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  String _formatTime(DateTime dt) => '${dt.month}/${dt.day} ${_two(dt.hour)}:${_two(dt.minute)}';

  String _formatCooldown(Duration d) => '${_two(d.inMinutes)}:${_two(d.inSeconds % 60)}';

  /// Keeps up to 2 decimal places, trimmed to a whole number when exact.
  String _formatAmount(double value) {
    final rounded = double.parse(value.toStringAsFixed(2));
    final isWhole = rounded == rounded.roundToDouble();
    final text = isWhole ? rounded.toStringAsFixed(0) : rounded.toStringAsFixed(2);
    final parts = text.split('.');
    final wholePart = commaFormat(parts[0]);
    return parts.length > 1 ? '$wholePart.${parts[1]}' : wholePart;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CountryProvider>();
    if (!provider.loaded) {
      return Scaffold(
        appBar: AppBar(title: const Text('환율 계산'), centerTitle: true),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (!_initStarted) _initDefaults(provider);
    if (_leftCountry == null || _rightCountry == null || _leftCurrency == null || _rightCurrency == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('환율 계산'), centerTitle: true),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final rateCache = context.watch<RateCacheProvider>();
    final scheme = Theme.of(context).colorScheme;

    final leftDefault = _leftCurrency!.currencies[_leftIndex];
    final rightDefault = _rightCurrency!.currencies[_rightIndex];
    final leftOption = _effectiveOption(leftDefault, rateCache);
    final rightOption = _effectiveOption(rightDefault, rateCache);
    final isLive = rateCache.rateFor(leftOption.currency) != null && rateCache.rateFor(rightOption.currency) != null;

    final amount = double.tryParse(_input.isEmpty ? '0' : _input) ?? 0;
    final krwValue = amount * leftOption.rateToKrw;
    final resultValue = rightOption.rateToKrw == 0 ? 0.0 : krwValue / rightOption.rateToKrw;
    final crossRate = rightOption.rateToKrw == 0 ? 0.0 : leftOption.rateToKrw / rightOption.rateToKrw;

    final remaining = rateCache.remainingCooldown;
    _ensureCooldownTicker(remaining != null);

    return Scaffold(
      appBar: AppBar(title: const Text('환율 계산'), centerTitle: true),
      body: AnchoredNumpadLayout(
        top: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: (_refreshing || remaining != null) ? null : _onRefresh,
                icon: _refreshing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh, size: 16),
                label: Text(
                  remaining != null
                      ? '${_formatCooldown(remaining)} 후 재시도'
                      : '최신 환율 받기 (전체)',
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _CurrencySelector(
                    country: _leftCountry!,
                    option: leftOption,
                    onTap: () => _pickCountry(true),
                  ),
                ),
                IconButton(
                  onPressed: _swap,
                  icon: const Icon(Icons.swap_horiz),
                  tooltip: '통화 바꾸기',
                  style: IconButton.styleFrom(backgroundColor: scheme.primaryContainer),
                ),
                Expanded(
                  child: _CurrencySelector(
                    country: _rightCountry!,
                    option: rightOption,
                    onTap: () => _pickCountry(false),
                  ),
                ),
              ],
            ),
            if (_leftCurrency!.currencies.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 8,
                  children: [
                    for (var i = 0; i < _leftCurrency!.currencies.length; i++)
                      ChoiceChip(
                        label: Text(_leftCurrency!.currencies[i].currency),
                        selected: _leftIndex == i,
                        onSelected: (_) => setState(() => _leftIndex = i),
                      ),
                  ],
                ),
              ),
            if (_rightCurrency!.currencies.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 8,
                  children: [
                    for (var i = 0; i < _rightCurrency!.currencies.length; i++)
                      ChoiceChip(
                        label: Text(_rightCurrency!.currencies[i].currency),
                        selected: _rightIndex == i,
                        onSelected: (_) => setState(() => _rightIndex = i),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            Text(
              isLive
                  ? '실시간 환율: 1 ${leftOption.currency} ≈ ${_formatAmount(crossRate)} ${rightOption.currency}\n(${_formatTime(rateCache.lastUpdateAt!)} 기준)'
                  : '기본 환율: 1 ${leftOption.currency} ≈ ${_formatAmount(crossRate)} ${rightOption.currency}',
              style: const TextStyle(fontSize: 15, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _AmountBox(
              isInput: true,
              flag: _leftCountry!.flag,
              currency: leftOption.currency,
              text: '${leftOption.symbol}${commaFormat(_input.isEmpty ? '0' : _input)}',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Icon(Icons.arrow_downward, color: scheme.primary),
            ),
            _AmountBox(
              isInput: false,
              flag: _rightCountry!.flag,
              currency: rightOption.currency,
              text: '${rightOption.symbol}${_formatAmount(resultValue)}',
            ),
          ],
        ),
        numpad: Numpad(onDigit: _onDigit, onBackspace: _onBackspace, onClear: _onClear),
      ),
    );
  }
}

class _CurrencySelector extends StatelessWidget {
  final CountryMeta country;
  final CurrencyOption option;
  final VoidCallback onTap;

  const _CurrencySelector({required this.country, required this.option, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(country.flag, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 2),
          Text(option.currency, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const Icon(Icons.expand_more, size: 16, color: Colors.grey),
        ],
      ),
    );
  }
}

/// Visually distinguishes the editable field (입력) from the computed one
/// (결과): the input box has a solid border and sits on the surface color,
/// the result box is filled/muted with no border, like a read-only field.
class _AmountBox extends StatelessWidget {
  final bool isInput;
  final String flag;
  final String currency;
  final String text;

  const _AmountBox({
    required this.isInput,
    required this.flag,
    required this.currency,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isInput ? scheme.surface : scheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: isInput ? Border.all(color: scheme.primary, width: 2) : null,
      ),
      child: Row(
        children: [
          Text(flag, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 6),
          Text(
            currency,
            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: isInput ? 30 : 26,
                fontWeight: FontWeight.bold,
                color: isInput ? scheme.onSurface : scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
