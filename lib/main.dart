import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'models/cart_item.dart';
import 'data/profile_service.dart';
import 'screens/account_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/home_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/orders_screen.dart';
import 'data/stores_service.dart';
import 'screens/staff_home_screen.dart';
import 'screens/staff_menu_screen.dart';
import 'screens/staff_orders_screen.dart';
import 'theme/coffee_palette.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Stripe.publishableKey =
      'pk_test_51Sv1GdArYzLwrB1mxeCYlxfatkmGBX8fIAWuJatpkUQL8fR6B5N4Ox8y1h5h7gbqWUlpZt1zrdXXuttR6Z6Fbsgf00Llxp7NAS';
  await Stripe.instance.applySettings();
  await Supabase.initialize(
    url: 'https://cowndvyhxurynathkpnj.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNvd25kdnloeHVyeW5hdGhrcG5qIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk2NzE5NzUsImV4cCI6MjA4NTI0Nzk3NX0.mPES4IvjzHBDhhprKElMrE35wpCLBkdl97ThbGqx5uk',
  );
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
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: CoffeePalette.card,
          indicatorColor: CoffeePalette.caramelSoft,
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? CoffeePalette.espresso
                  : CoffeePalette.espressoSoft,
            ),
          ),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              color: states.contains(WidgetState.selected)
                  ? CoffeePalette.espresso
                  : CoffeePalette.espressoSoft,
              fontWeight:
                  states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
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
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.85, curve: Curves.easeInOut),
    );
    _controller.forward();
    Future<void>.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 350),
          pageBuilder: (_, __, ___) => const RootShell(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoffeePalette.cream,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: Text(
            'CoffeeArq',
            style: GoogleFonts.baloo2(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: CoffeePalette.espresso,
            ),
          ),
        ),
      ),
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
  List<Store> _stores = const [];
  Store? _currentStore;
  String _menuCategory = 'All';
  bool _loadingStores = true;
  String _userRole = 'customer';
  String _viewMode = 'customer';
  StreamSubscription<AuthState>? _authSub;

  int get _cartCount =>
      _cartItems.fold(0, (sum, item) => sum + item.quantity);

  double get _cartTotal =>
      _cartItems.fold(0, (sum, item) => sum + (item.price * item.quantity));

  @override
  void initState() {
    super.initState();
    _loadStores();
    _loadUserRole();
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      _loadUserRole();
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _loadStores() async {
    try {
      final stores = await StoresService().fetchStores();
      if (!mounted) return;
      if (stores.isEmpty) {
        setState(() {
          _stores = const [];
          _currentStore = null;
          _loadingStores = false;
        });
        return;
      }
      setState(() {
        _stores = stores;
        _currentStore = stores.first;
        _loadingStores = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingStores = false);
    }
  }

  Future<void> _loadUserRole() async {
    final profile = await ProfileService().fetchProfile();
    if (!mounted) return;
    final role = profile?.role ?? 'customer';
    final canStaff = role == 'staff' || role == 'admin';
    setState(() {
      _userRole = role;
      if (!canStaff) {
        _viewMode = 'customer';
      } else if (_viewMode != 'staff') {
        _viewMode = 'customer';
      }
    });
  }

  bool get _canUseStaff => _userRole == 'staff' || _userRole == 'admin';
  bool get _showStorePicker => _stores.length > 1;
  String get _currentStoreName => _currentStore?.name ?? 'Downtown Cafe';
  String? get _currentStoreId => _currentStore?.id;

  void _setViewMode(String mode) {
    if (!_canUseStaff && mode == 'staff') return;
    setState(() => _viewMode = mode);
  }

  void _addToCart(CartItem item) {
    setState(() {
      final index = _cartItems.indexWhere((existing) => existing.key == item.key);
      if (index >= 0) {
        _cartItems[index].quantity += 1;
      } else {
        _cartItems.add(item);
      }
    });
  }

  void _updateQuantity(String key, int delta) {
    setState(() {
      final index = _cartItems.indexWhere((item) => item.key == key);
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

  void _removeItem(String key) {
    setState(() {
      _cartItems.removeWhere((item) => item.key == key);
    });
  }

  void _clearCart() {
    setState(() => _cartItems.clear());
  }

  void _setCartItems(List<CartItem> items) {
    setState(() {
      _cartItems
        ..clear()
        ..addAll(items);
    });
  }

  Future<void> _openStorePicker() async {
    if (_loadingStores || !_showStorePicker) return;
    final selected = await showModalBottomSheet<Store>(
      context: context,
      backgroundColor: CoffeePalette.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _StorePicker(
        currentStore: _currentStore,
        stores: _stores,
      ),
    );
    if (selected != null && selected != _currentStore) {
      setState(() => _currentStore = selected);
    }
  }

  void _openMenuCategory(String category) {
    setState(() {
      _menuCategory = category;
      _index = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final customerScreens = [
      HomeScreen(
        currentStore: _currentStoreName,
        currentStoreId: _currentStoreId,
        cartCount: _cartCount,
        cartTotal: _cartTotal,
        onQuickAdd: _addToCart,
        onCartTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CartScreen(
                items: _cartItems,
                total: _cartTotal,
                storeName: _currentStoreName,
                storeId: _currentStoreId,
                onUpdateQuantity: _updateQuantity,
                onRemoveItem: _removeItem,
                onCheckoutComplete: _clearCart,
                onReorder: _setCartItems,
              ),
            ),
          );
        },
        onStoreTap: _openStorePicker,
        onCategoryTap: _openMenuCategory,
        showStorePicker: _showStorePicker,
        showRoleSwitcher: _canUseStaff,
        currentRole: _viewMode,
        onRoleChange: _setViewMode,
      ),
      MenuScreen(
        onAddToCart: _addToCart,
        initialCategory: _menuCategory,
        currentStore: _currentStoreName,
        currentStoreId: _currentStoreId,
        showStorePicker: _showStorePicker,
        onStoreTap: _openStorePicker,
      ),
      OrdersScreen(onReorder: _setCartItems),
      const AccountScreen(),
    ];

    final staffScreens = [
      StaffHomeScreen(
        currentRole: _viewMode,
        onRoleChange: _setViewMode,
      ),
      StaffMenuScreen(storeId: _currentStoreId),
      StaffOrdersScreen(storeId: _currentStoreId),
      const AccountScreen(),
    ];

    final screens = _viewMode == 'staff' ? staffScreens : customerScreens;
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

class _StorePicker extends StatelessWidget {
  const _StorePicker({
    required this.currentStore,
    required this.stores,
  });

  final Store? currentStore;
  final List<Store> stores;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose a store',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ...stores.map((store) {
              final isSelected = store.id == currentStore?.id;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  store.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: CoffeePalette.espresso)
                    : const Icon(Icons.circle_outlined, color: CoffeePalette.espressoSoft),
                onTap: () => Navigator.of(context).pop(store),
              );
            }),
          ],
        ),
      ),
    );
  }
}
