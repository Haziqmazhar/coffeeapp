import 'package:flutter/material.dart';

import '../theme/coffee_palette.dart';

class AdminStaffScreen extends StatelessWidget {
  const AdminStaffScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoffeePalette.cream,
      appBar: AppBar(
        backgroundColor: CoffeePalette.cream,
        elevation: 0,
        title: Text('Staff', style: Theme.of(context).textTheme.titleLarge),
      ),
      body: Center(
        child: Text(
          'Manage staff profiles and permissions.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
