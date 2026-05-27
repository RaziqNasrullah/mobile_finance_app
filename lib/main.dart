// lib/main.dart
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'utils/theme.dart';
import 'utils/theme_notifier.dart';
import 'utils/transaction_store.dart';
import 'utils/category_store.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
  ));
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final store = TransactionStore();
  final themeNotifier = ThemeNotifier();
  final categoryStore = CategoryStore();
  await Future.wait([store.load(), themeNotifier.load(), categoryStore.load(), initializeDateFormatting('id', null)]);

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: store),
      ChangeNotifierProvider.value(value: themeNotifier),
      ChangeNotifierProvider.value(value: categoryStore),
    ],
    child: const FinanceApp(),
  ));
}

class FinanceApp extends StatelessWidget {
  const FinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (_, notifier, __) => AnimatedTheme(
        duration: const Duration(milliseconds: 300),
        data: notifier.isDark ? AppTheme.dark : AppTheme.light,
        child: MaterialApp(
          title: 'Keuangan Ku',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: notifier.isDark ? ThemeMode.dark : ThemeMode.light,
          home: const HomeScreen(),
        ),
      ),
    );
  }
}   