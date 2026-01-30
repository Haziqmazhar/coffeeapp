import 'package:flutter/material.dart';

import '../theme/coffee_palette.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoffeePalette.cream,
      appBar: AppBar(
        backgroundColor: CoffeePalette.cream,
        elevation: 0,
        title:
            Text('Privacy Policy', style: Theme.of(context).textTheme.titleLarge),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        children: [
          _PolicyBlock(
            title: 'What we collect',
            body:
                'We collect your name, email, and order details to provide the service.',
          ),
          const SizedBox(height: 12),
          _PolicyBlock(
            title: 'How we use data',
            body:
                'Data is used to process orders, show receipts, and keep your preferences.',
          ),
          const SizedBox(height: 12),
          _PolicyBlock(
            title: 'Payments',
            body:
                'Payments are handled securely by Stripe. We do not store full card numbers.',
          ),
          const SizedBox(height: 12),
          _PolicyBlock(
            title: 'Notifications',
            body:
                'Notifications are optional and can be turned off in Account settings.',
          ),
          const SizedBox(height: 12),
          _PolicyBlock(
            title: 'Data removal',
            body:
                'You can request deletion of your account and data by contacting support.',
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: CoffeePalette.card,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Last updated: January 30, 2026',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicyBlock extends StatelessWidget {
  const _PolicyBlock({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CoffeePalette.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(body, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
