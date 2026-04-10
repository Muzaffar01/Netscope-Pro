import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:netscope/providers/theme_provider.dart';
import 'package:netscope/providers/search_provider.dart';
import 'package:netscope/providers/history_provider.dart';
import 'package:netscope/screens/home_screen.dart';
import 'package:netscope/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NetScopeApp());
}

class NetScopeApp extends StatelessWidget {
  const NetScopeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'NetScope Pro',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
