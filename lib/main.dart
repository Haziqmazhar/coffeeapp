import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'models/cart_item.dart';
import 'screens/account_screen.dart';
import 'screens/cart_screen.dart';
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
  final List<CartItem> _cartItems = [];

  int get _cartCount =>
      _cartItems.fold(0, (sum, item) => sum + item.quantity);

  double get _cartTotal =>
      _cartItems.fold(0, (sum, item) => sum + (item.price * item.quantity));

  void _addToCart(String name, double price) {
    setState(() {
      final index = _cartItems.indexWhere((item) => item.name == name);
      if (index >= 0) {
        _cartItems[index].quantity += 1;
      } else {
        _cartItems.add(CartItem(name: name, price: price));
      }
    });
  }

  void _updateQuantity(String name, int delta) {
    setState(() {
      final index = _cartItems.indexWhere((item) => item.name == name);
      if (index == -1) {
        return;
      }
      final item = _cartItems[index];
      item.quantity += delta;
      if (item.quantity <= 0) {
        _cartItems.removeAt(index);
      }
    });
  }

  void _removeItem(String name) {
    setState(() {
      _cartItems.removeWhere((item) => item.name == name);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        cartCount: _cartCount,
        cartTotal: _cartTotal,
        onQuickAdd: _addToCart,
        onCartTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CartScreen(
                items: _cartItems,
                total: _cartTotal,
                onUpdateQuantity: _updateQuantity,
                onRemoveItem: _removeItem,
              ),
            ),
          );
        },
      ),
      MenuScreen(onAddToCart: _addToCart),
      const OrdersScreen(),
      const AccountScreen(),
    ];
    return Scaffold(
      body: screens[_index],
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
