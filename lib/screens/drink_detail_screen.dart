import 'package:flutter/material.dart';

import '../theme/coffee_palette.dart';

class DrinkDetailScreen extends StatefulWidget {
  const DrinkDetailScreen({
    super.key,
    required this.name,
    required this.subtitle,
    required this.basePrice,
    required this.onAddToCart,
    this.imagePath,
  });

  final String name;
  final String subtitle;
  final double basePrice;
  final void Function(double price) onAddToCart;
  final String? imagePath;

  @override
  State<DrinkDetailScreen> createState() => _DrinkDetailScreenState();
}

class _DrinkDetailScreenState extends State<DrinkDetailScreen> {
  int _sizeIndex = 1;
  int _milkIndex = 0;
  int _sweetIndex = 2;
  final Map<String, double> _addons = {
    'Extra shot': 0.75,
    'Vanilla': 0.50,
    'Caramel': 0.50,
  };
  final Set<String> _selectedAddons = {};

  double get _sizeMultiplier {
    switch (_sizeIndex) {
      case 0:
        return 0.9;
      case 2:
        return 1.2;
      default:
        return 1.0;
    }
  }

  double get _price {
    final addonsTotal = _selectedAddons.fold<double>(
      0,
      (sum, item) => sum + (_addons[item] ?? 0),
    );
    return (widget.basePrice * _sizeMultiplier) + addonsTotal;
  }

  String get _sizeLabel => ['S', 'M', 'L'][_sizeIndex];
  String get _milkLabel => ['Oat', 'Almond', 'Whole'][_milkIndex];
  String get _sweetLabel => ['0%', '25%', '50%', '100%'][_sweetIndex];

  String get _selectionSummary {
    final addons = _selectedAddons.isEmpty
        ? 'No add-ons'
        : _selectedAddons.join(', ');
    return 'Size: $_sizeLabel • Milk: $_milkLabel • Sweet: $_sweetLabel • $addons';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoffeePalette.cream,
      appBar: AppBar(
        backgroundColor: CoffeePalette.cream,
        elevation: 0,
        title: Text(
          widget.name,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: CoffeePalette.card,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 14,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: widget.imagePath == null
                    ? const Center(
                        child: Icon(
                          Icons.local_cafe,
                          size: 54,
                          color: CoffeePalette.espresso,
                        ),
                      )
                    : Image.asset(
                        widget.imagePath!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 180,
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Text(widget.subtitle, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            _SectionTitle(label: 'Size'),
            const SizedBox(height: 8),
            _SegmentedOptions(
              options: const ['S', 'M', 'L'],
              selectedIndex: _sizeIndex,
              onChanged: (index) => setState(() => _sizeIndex = index),
            ),
            const SizedBox(height: 16),
            _SectionTitle(label: 'Milk'),
            const SizedBox(height: 8),
            _SegmentedOptions(
              options: const ['Oat', 'Almond', 'Whole'],
              selectedIndex: _milkIndex,
              onChanged: (index) => setState(() => _milkIndex = index),
            ),
            const SizedBox(height: 16),
            _SectionTitle(label: 'Sweetness'),
            const SizedBox(height: 8),
            _SegmentedOptions(
              options: const ['0%', '25%', '50%', '100%'],
              selectedIndex: _sweetIndex,
              onChanged: (index) => setState(() => _sweetIndex = index),
            ),
            const SizedBox(height: 16),
            _SectionTitle(label: 'Add-ons'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _addons.entries.map((entry) {
                final selected = _selectedAddons.contains(entry.key);
                return FilterChip(
                  label: Text('${entry.key} (+\$${entry.value.toStringAsFixed(2)})'),
                  selected: selected,
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        _selectedAddons.add(entry.key);
                      } else {
                        _selectedAddons.remove(entry.key);
                      }
                    });
                  },
                  selectedColor: CoffeePalette.caramelSoft,
                  checkmarkColor: CoffeePalette.espresso,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            _SectionTitle(label: 'Ingredients'),
            const SizedBox(height: 8),
            Text(
              'Espresso, ${_milkLabel.toLowerCase()} milk, ice',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _SectionTitle(label: 'Calories'),
            const SizedBox(height: 8),
            Text(
              'Approx. 180 kcal',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _SectionTitle(label: 'Your Selection'),
            const SizedBox(height: 8),
            Text(
              _selectionSummary,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _SectionTitle(label: 'Notes (optional)'),
            const SizedBox(height: 8),
            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g., extra hot, no foam',
                filled: true,
                fillColor: CoffeePalette.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: ElevatedButton(
          onPressed: () {
            widget.onAddToCart(_price);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: CoffeePalette.espresso,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: Text('Add to Cart  \$${_price.toStringAsFixed(2)}'),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleMedium,
    );
  }
}

class _SegmentedOptions extends StatelessWidget {
  const _SegmentedOptions({
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      children: List.generate(options.length, (index) {
        final selected = index == selectedIndex;
        return ChoiceChip(
          label: Text(options[index]),
          selected: selected,
          onSelected: (_) => onChanged(index),
          selectedColor: CoffeePalette.caramelSoft,
          labelStyle: TextStyle(
            color: selected ? CoffeePalette.espresso : CoffeePalette.espressoSoft,
            fontWeight: FontWeight.w600,
          ),
        );
      }),
    );
  }
}
