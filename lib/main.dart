import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ui/theme.dart';
import 'ui/dashboard.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: FactoryClickerApp(),
    ),
  );
}

class FactoryClickerApp extends StatelessWidget {
  const FactoryClickerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Factory Clicker',
      debugShowCheckedModeBanner: false,
      theme: FactoryTheme.themeData,
      home: const DashboardScreen(),
    );
  }
}

