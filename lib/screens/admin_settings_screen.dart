import 'package:flutter/material.dart';

import '../theme/coffee_palette.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoffeePalette.cream,
      appBar: AppBar(
        backgroundColor: CoffeePalette.cream,
        elevation: 0,
        title: Text('Settings', style: Theme.of(context).textTheme.titleLarge),
      ),
      body: Center(
        child: Text(
          'Store status, audit log, and emergency controls.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
