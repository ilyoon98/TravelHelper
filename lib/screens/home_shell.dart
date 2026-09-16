import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/ad_service.dart';
import 'currency_tab.dart';
import 'number_tab.dart';
import 'phrase_tab.dart';
import 'settings_tab.dart';

/// Bottom-nav shell holding the 4 tabs (spec section 1). Uses IndexedStack so
/// each tab's State (numpad input, category filter, etc.) survives switching
/// away and back.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _tabs = [
    NumberTab(),
    CurrencyTab(),
    PhraseTab(),
    SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final adService = context.watch<AdService>();
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: IndexedStack(index: _index, children: _tabs)),
            if (!adService.isAdRemoved)
              Center(child: adService.bannerWidget(context)),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.numbers), label: '숫자'),
          NavigationDestination(icon: Icon(Icons.currency_exchange), label: '환율'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: '회화'),
          NavigationDestination(icon: Icon(Icons.settings), label: '설정'),
        ],
      ),
    );
  }
}
