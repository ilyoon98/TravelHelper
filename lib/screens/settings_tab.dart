import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/rate_cache_provider.dart';
import '../providers/theme_provider.dart';

/// 탭4 — 설정. No country picker here (spec section 2).
///
/// NOTE: "광고 제거 구매" row is still omitted — there is nothing to remove
/// yet since ads are deferred (see currency_tab.dart for the ad-related
/// decision). Add it back once AdMob lands.
class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  Future<void> _openContactForm(BuildContext context) async {
    final uri = Uri.parse('https://forms.gle/cLifTZ4ZzeVNVrbh6');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('문의 페이지를 열 수 없습니다')),
        );
      }
    }
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  String _formatTime(DateTime dt) =>
      '${dt.year}.${_two(dt.month)}.${_two(dt.day)} ${_two(dt.hour)}:${_two(dt.minute)}';

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final rateCache = context.watch<RateCacheProvider>();
    final hasCache = rateCache.hasCache;

    return Scaffold(
      appBar: AppBar(title: const Text('설정'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: SwitchListTile(
              title: const Text('다크모드'),
              value: theme.isDark,
              onChanged: (v) => context.read<ThemeProvider>().setDark(v),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              title: const Text('환율 캐시 정보'),
              subtitle: Text(
                hasCache
                    ? '마지막 업데이트: 전체 통화 · ${_formatTime(rateCache.lastUpdateAt!)}'
                    : '마지막 업데이트: 없음 (기본 하드코딩 값 사용 중)',
              ),
              trailing: TextButton(
                onPressed: hasCache
                    ? () async {
                        await context.read<RateCacheProvider>().resetAll();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('환율 캐시를 초기화했습니다')),
                          );
                        }
                      }
                    : null,
                child: const Text('초기화'),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              title: const Text('문의하기'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openContactForm(context),
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: ListTile(
              title: Text('앱 정보'),
              trailing: Text('v0.2 (개발 중)', style: TextStyle(color: Colors.grey)),
            ),
          ),
        ],
      ),
    );
  }
}
