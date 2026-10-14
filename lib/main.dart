import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/country_provider.dart';
import 'providers/rate_cache_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_shell.dart';

void main() {
  runApp(const TravelHelperApp());
}

class TravelHelperApp extends StatelessWidget {
  const TravelHelperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CountryProvider()..load()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..load()),
        ChangeNotifierProvider(create: (_) => RateCacheProvider()..load()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) {
          return MaterialApp(
            title: 'Travel Helper',
            debugShowCheckedModeBanner: false,
            themeMode: theme.isDark ? ThemeMode.dark : ThemeMode.light,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF009688)),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF26A69A),
                brightness: Brightness.dark,
              ),
            ),
            home: const HomeShell(),
          );
        },
      ),
    );
  }
}
