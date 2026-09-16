import 'package:flutter/material.dart';

import '../models/country.dart';

/// Region display order — countries are grouped under these headers rather
/// than shown as one long flat list. New regions can be appended here.
const _regionOrder = ['동아시아', '동남아시아', '아프리카', '남미', '중미', '북미', '오세아니아', '유럽'];

/// Korean 초성 (leading consonants), in Unicode syllable order — index i
/// here matches the chosung index encoded in every 가-힣 syllable.
const _chosungTable = [
  'ㄱ', 'ㄲ', 'ㄴ', 'ㄷ', 'ㄸ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅃ', 'ㅅ',
  'ㅆ', 'ㅇ', 'ㅈ', 'ㅉ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ',
];

/// Extracts the 초성 of every Hangul syllable in [text] (e.g. "태국" ->
/// "ㅌㄱ"), leaving any non-Hangul character (letters, digits...) untouched.
String _chosungOf(String text) {
  final buffer = StringBuffer();
  for (final rune in text.runes) {
    if (rune >= 0xAC00 && rune <= 0xD7A3) {
      buffer.write(_chosungTable[(rune - 0xAC00) ~/ 588]);
    } else {
      buffer.writeCharCode(rune);
    }
  }
  return buffer.toString();
}

/// True if every character in [text] is itself a 초성 — i.e. the user is
/// typing initials like "ㅌㄱ" rather than full syllables.
bool _isChosungQuery(String text) {
  if (text.isEmpty) return false;
  return text.runes.every((r) => _chosungTable.contains(String.fromCharCode(r)));
}

/// Full-screen country search sheet (spec section 2). The caller decides
/// which list to pass in — tab 2 (환율) includes the EUR currency-only
/// entry, tabs 1/3 exclude it since it has no number/phrase data.
class CountryPickerSheet extends StatefulWidget {
  final List<CountryMeta> countries;
  final String selectedCode;

  const CountryPickerSheet({
    super.key,
    required this.countries,
    required this.selectedCode,
  });

  @override
  State<CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<CountryPickerSheet> {
  String _query = '';

  bool _matches(CountryMeta c) {
    final query = _query.trim();
    if (query.isEmpty) return true;
    final lowerQuery = query.toLowerCase();
    if (c.name.toLowerCase().contains(lowerQuery)) return true;
    if (c.nameEn.toLowerCase().contains(lowerQuery)) return true;
    if (c.code.toLowerCase().contains(lowerQuery)) return true;
    if (_isChosungQuery(query) && _chosungOf(c.name).contains(query)) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.countries.where(_matches).toList();

    // Flatten into [region header, country, country, ..., next header, ...],
    // skipping regions with no matches, in the fixed _regionOrder.
    final rows = <Object>[];
    for (final region in _regionOrder) {
      final inRegion = filtered.where((c) => c.region == region).toList();
      if (inRegion.isEmpty) continue;
      rows.add(region);
      rows.addAll(inRegion);
    }
    // Any country whose region isn't in _regionOrder still shows up, grouped
    // under its own region name, so nothing silently disappears.
    final knownRegions = _regionOrder.toSet();
    final leftoverRegions = filtered.map((c) => c.region).where((r) => !knownRegions.contains(r)).toSet();
    for (final region in leftoverRegions) {
      final inRegion = filtered.where((c) => c.region == region).toList();
      rows.add(region);
      rows.addAll(inRegion);
    }

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          decoration: const InputDecoration(
            hintText: '나라 이름 검색',
            border: InputBorder.none,
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
        ],
      ),
      body: filtered.isEmpty
          ? const Center(
              child: Text('검색 결과가 없습니다', style: TextStyle(color: Colors.grey)),
            )
          : ListView.builder(
              itemCount: rows.length,
              itemBuilder: (context, index) {
                final row = rows[index];
                if (row is String) {
                  return Container(
                    width: double.infinity,
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      row,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  );
                }
                final c = row as CountryMeta;
                final isSelected = c.code == widget.selectedCode;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      tileColor: isSelected
                          ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4)
                          : null,
                      leading: Text(c.flag, style: const TextStyle(fontSize: 24)),
                      title: Text(c.name, style: const TextStyle(fontSize: 16)),
                      trailing: Chip(
                        label: Text(c.code, style: const TextStyle(fontSize: 12)),
                        visualDensity: VisualDensity.compact,
                      ),
                      onTap: () => Navigator.of(context).pop(c.code),
                    ),
                    const Divider(height: 1),
                  ],
                );
              },
            ),
    );
  }
}
