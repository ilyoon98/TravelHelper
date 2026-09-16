import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/country_provider.dart';
import '../country_picker_sheet.dart';

/// Header used by 숫자/회화 tabs (spec section 2): small tab label on top,
/// large flag+name button below that opens the country picker — these two
/// tabs share one country selection via [CountryProvider]. 환율 has its own
/// independent left/right currency selectors now (see currency_tab.dart) so
/// it no longer uses this header, the same way 설정 never did. A thin
/// divider under the header separates it from the tab body — the body's own
/// first row is always the tab's mode toggle (자릿수/전체읽기), kept out of
/// the header itself so it reads as plain text instead of an icon-only
/// button.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String tabTitle;

  const AppHeader({super.key, required this.tabTitle});

  @override
  Size get preferredSize => const Size.fromHeight(65);

  Future<void> _openPicker(BuildContext context, CountryProvider provider) async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => CountryPickerSheet(
          countries: provider.countriesWithContent,
          selectedCode: provider.selectedCode,
        ),
        fullscreenDialog: true,
      ),
    );
    if (code != null) provider.select(code);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CountryProvider>();
    if (!provider.loaded) {
      return AppBar(title: Text(tabTitle), centerTitle: true);
    }
    final selected = provider.selected;
    final scheme = Theme.of(context).colorScheme;
    return AppBar(
      toolbarHeight: 64,
      automaticallyImplyLeading: false,
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: Theme.of(context).dividerColor),
      ),
      title: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(tabTitle, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 4),
          Material(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _openPicker(context, provider),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(selected.flag, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Text(
                      selected.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.expand_more, size: 18, color: scheme.onPrimaryContainer),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
