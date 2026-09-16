import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/number_data.dart';
import '../providers/country_provider.dart';
import '../services/data_service.dart';
import '../services/number_to_words.dart';
import 'widgets/anchored_numpad_layout.dart';
import 'widgets/app_header.dart';
import 'widgets/numpad.dart';

enum NumberMode { digit, full }

/// 탭1 — 숫자 발음. Input persists across country switches (spec section 3);
/// switching country just re-renders with the new country's data. The mode
/// toggle sits as plain text right under the header (same spot/style as the
/// 환율 탭's 방향 전환), and the numpad stays pinned to the bottom regardless
/// of how tall the results above it get (see AnchoredNumpadLayout).
class NumberTab extends StatefulWidget {
  const NumberTab({super.key});

  @override
  State<NumberTab> createState() => _NumberTabState();
}

class _NumberTabState extends State<NumberTab> {
  String _input = '';
  NumberMode _mode = NumberMode.digit;

  String? _loadedCode;
  CountryNumbers? _numbers;

  Future<void> _loadFor(String code) async {
    final data = await DataService.instance.loadNumbers(code);
    if (!mounted) return;
    setState(() {
      _loadedCode = code;
      _numbers = data;
    });
  }

  void _onDigit(String d) {
    setState(() {
      if (_input == '0') {
        _input = d; // no leading zeros — typing 0 then 5 should read "5", not "05"
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

  @override
  Widget build(BuildContext context) {
    final countryCode = context.watch<CountryProvider>().selectedCode;
    if (countryCode != _loadedCode) {
      // Kick off (re)load; render a lightweight placeholder meanwhile.
      _loadFor(countryCode);
      return Scaffold(
        appBar: const AppHeader(tabTitle: '숫자 발음'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final numbers = _numbers!;
    return Scaffold(
      appBar: const AppHeader(tabTitle: '숫자 발음'),
      body: AnchoredNumpadLayout(
        top: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<NumberMode>(
              segments: const [
                ButtonSegment(value: NumberMode.digit, label: Text('자릿수 모드')),
                ButtonSegment(value: NumberMode.full, label: Text('전체 읽기 모드')),
              ],
              selected: {_mode},
              onSelectionChanged: (s) => setState(() => _mode = s.first),
            ),
            const SizedBox(height: 14),
            if (_mode == NumberMode.digit)
              _DigitModeResults(input: _input, numbers: numbers)
            else
              _FullModeResult(input: _input, numbers: numbers),
            const SizedBox(height: 18),
            Builder(builder: (context) {
              final displayText =
                  _mode == NumberMode.digit ? (_input.isEmpty ? '0' : _input) : commaFormat(_input);
              final native = nativeDigitsFor(numbers.language, displayText);
              return Column(
                children: [
                  Text(
                    displayText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
                  ),
                  if (native != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        native,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 20, color: Colors.grey),
                      ),
                    ),
                ],
              );
            }),
          ],
        ),
        numpad: Numpad(onDigit: _onDigit, onBackspace: _onBackspace, onClear: _onClear),
      ),
    );
  }
}

class _DigitModeResults extends StatelessWidget {
  final String input;
  final CountryNumbers numbers;

  const _DigitModeResults({required this.input, required this.numbers});

  @override
  Widget build(BuildContext context) {
    if (input.isEmpty) {
      return const _EmptyHint(text: '숫자를 입력하면 자리별 발음이 표시됩니다');
    }
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: input.split('').map((d) {
        final entry = numbers.digits[d];
        if (entry == null) return const SizedBox.shrink();
        return _DigitCard(entry: entry);
      }).toList(),
    );
  }
}

class _DigitCard extends StatelessWidget {
  final NumberEntry entry;
  const _DigitCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(entry.native, style: const TextStyle(fontSize: 26)),
          const SizedBox(height: 4),
          Text(entry.korean, style: TextStyle(fontSize: 19, color: scheme.primary)),
          Text(entry.pronunciation, style: const TextStyle(fontSize: 15, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _FullModeResult extends StatelessWidget {
  final String input;
  final CountryNumbers numbers;

  const _FullModeResult({required this.input, required this.numbers});

  @override
  Widget build(BuildContext context) {
    if (input.isEmpty) {
      return const _EmptyHint(text: '숫자를 입력하면 전체 문장으로 읽어줍니다');
    }
    final n = int.tryParse(input);
    if (n == null || n > maxFullReadingValue) {
      return const _EmptyHint(text: '전체 읽기 모드는 999,999까지만 지원합니다');
    }
    final words = numberToWords(numbers.language, n);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(words.native, style: const TextStyle(fontSize: 28), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(words.korean, style: TextStyle(fontSize: 20, color: scheme.primary), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(words.pronunciation, style: const TextStyle(fontSize: 16, color: Colors.grey), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(text, style: const TextStyle(color: Colors.grey), textAlign: TextAlign.center),
    );
  }
}
