import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/phrase_data.dart';
import '../providers/country_provider.dart';
import '../services/data_service.dart';
import 'widgets/app_header.dart';

/// 탭3 — 여행 회화. Category chips filter which categories are shown;
/// "전체" (null) shows every category.
class PhraseTab extends StatefulWidget {
  const PhraseTab({super.key});

  @override
  State<PhraseTab> createState() => _PhraseTabState();
}

class _PhraseTabState extends State<PhraseTab> {
  String? _selectedCategory;

  String? _loadedCode;
  CountryPhrases? _phrases;

  Future<void> _loadFor(String code) async {
    final data = await DataService.instance.loadPhrases(code);
    if (!mounted) return;
    setState(() {
      _loadedCode = code;
      _phrases = data;
      _selectedCategory = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final countryCode = context.watch<CountryProvider>().selectedCode;
    if (countryCode != _loadedCode) {
      _loadFor(countryCode);
      return Scaffold(
        appBar: const AppHeader(tabTitle: '여행 회화'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final phrases = _phrases!;
    final categories = phrases.categories
        .where((c) => _selectedCategory == null || c.category == _selectedCategory)
        .toList();

    return Scaffold(
      appBar: const AppHeader(tabTitle: '여행 회화'),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _CategoryChip(
                  label: '전체',
                  selected: _selectedCategory == null,
                  onTap: () => setState(() => _selectedCategory = null),
                ),
                for (final cat in phrases.categories)
                  _CategoryChip(
                    label: cat.category,
                    selected: _selectedCategory == cat.category,
                    onTap: () => setState(() => _selectedCategory = cat.category),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: categories.length,
              itemBuilder: (context, index) => _PhraseCategoryCard(category: categories[index]),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onTap()),
    );
  }
}

class _PhraseCategoryCard extends StatelessWidget {
  final PhraseCategory category;
  const _PhraseCategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              category.category,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            const Divider(),
            for (final p in category.phrases) _PhraseRow(phrase: p),
          ],
        ),
      ),
    );
  }
}

class _PhraseRow extends StatelessWidget {
  final PhraseItem phrase;
  const _PhraseRow({required this.phrase});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(phrase.korean, style: const TextStyle(fontSize: 15, color: Colors.grey)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(phrase.native, style: const TextStyle(fontSize: 19), textAlign: TextAlign.end),
                Text(phrase.koreanPron, style: TextStyle(fontSize: 15, color: scheme.primary), textAlign: TextAlign.end),
                Text(phrase.pronunciation, style: const TextStyle(fontSize: 14, color: Colors.grey), textAlign: TextAlign.end),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
