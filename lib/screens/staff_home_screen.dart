import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/coffee_palette.dart';

class StaffHomeScreen extends StatelessWidget {
  const StaffHomeScreen({
    super.key,
    required this.currentRole,
    required this.onRoleChange,
  });

  final String currentRole;
  final ValueChanged<String> onRoleChange;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoffeePalette.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TopBar(
                currentRole: currentRole,
                onRoleChange: onRoleChange,
              ),
              const SizedBox(height: 24),
              Text(
                'Staff Home',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Use the Menu and Orders tabs to manage availability and live orders.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.currentRole,
    required this.onRoleChange,
  });

  final String currentRole;
  final ValueChanged<String> onRoleChange;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () async {
            final selected = await showModalBottomSheet<String>(
              context: context,
              backgroundColor: CoffeePalette.card,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              builder: (_) => _RolePicker(currentRole: currentRole),
            );
            if (selected != null && selected != currentRole) {
              onRoleChange(selected);
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: CoffeePalette.espresso,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currentRole == 'staff' ? 'Staff' : 'Customer',
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.keyboard_arrow_down, color: Colors.white),
              ],
            ),
          ),
        ),
        const Spacer(),
        Text(
          'CoffeeArq',
          style: GoogleFonts.baloo2(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: CoffeePalette.espresso,
          ),
        ),
      ],
    );
  }
}

class _RolePicker extends StatelessWidget {
  const _RolePicker({required this.currentRole});

  final String currentRole;

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
              'Choose mode',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ...['customer', 'staff'].map((role) {
              final isSelected = role == currentRole;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  role == 'staff' ? 'Staff' : 'Customer',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle,
                        color: CoffeePalette.espresso)
                    : const Icon(Icons.circle_outlined,
                        color: CoffeePalette.espressoSoft),
                onTap: () => Navigator.of(context).pop(role),
              );
            }),
          ],
        ),
      ),
    );
  }
}
