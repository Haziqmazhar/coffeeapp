import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/account_screen.dart';
import 'screens/home_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/orders_screen.dart';
import 'theme/coffee_palette.dart';

void main() {
  runApp(const CoffeeArqApp());
}

class CoffeeArqApp extends StatelessWidget {
  const CoffeeArqApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData.light(useMaterial3: true);
    return MaterialApp(
      title: 'CoffeeArq',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        scaffoldBackgroundColor: CoffeePalette.cream,
        colorScheme: base.colorScheme.copyWith(
          primary: CoffeePalette.espresso,
          secondary: CoffeePalette.caramel,
          surface: CoffeePalette.card,
        ),
        textTheme: GoogleFonts.manropeTextTheme(base.textTheme).copyWith(
          headlineLarge: GoogleFonts.fraunces(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: CoffeePalette.espresso,
          ),
          titleLarge: GoogleFonts.fraunces(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: CoffeePalette.espresso,
          ),
          titleMedium: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: CoffeePalette.espresso,
          ),
          bodyMedium: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: CoffeePalette.espressoSoft,
          ),
          bodySmall: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: CoffeePalette.espressoSoft,
          ),
        ),
      ),
      home: const RootShell(),
    );
  }
}

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  final _screens = const [
    HomeScreen(),
    MenuScreen(),
    OrdersScreen(),
    AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: NavigationBar(
        backgroundColor: CoffeePalette.card,
        selectedIndex: _index,
        indicatorColor: CoffeePalette.caramelSoft,
        onDestinationSelected: (value) {
          setState(() => _index = value);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.menu_book), label: 'Menu'),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Orders'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Account'),
        ],
      ),
    );
  }
}
