import 'package:flutter/material.dart';

import '../logic/cart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.catalog = sampleCatalog});

  final List<Product> catalog;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _cart = Cart();
  final _code = TextEditingController();
  String? _category;
  String? _codeError;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _applyCode() {
    setState(() {
      _codeError = _cart.applyCode(_code.text) ? null : 'Unknown code';
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final categories = categoriesOf(widget.catalog);
    final visible = widget.catalog
        .where((p) => _category == null || p.category == _category)
        .toList();
    final totals = _cart.totals();
    return Scaffold(
      appBar: AppBar(title: const Text('Digital Products')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: _category == null,
                onSelected: (_) => setState(() => _category = null),
              ),
              for (final c in categories)
                ChoiceChip(
                  label: Text(c),
                  selected: _category == c,
                  onSelected: (_) => setState(() => _category = c),
                ),
            ],
          ),
          const SizedBox(height: 8),
          for (final p in visible)
            Card(
              child: ListTile(
                title: Text(p.name),
                subtitle: Text('${p.category} · ${formatCents(p.priceCents)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Remove one ${p.name}',
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: _cart.quantityOf(p.id) == 0
                          ? null
                          : () => setState(() => _cart.remove(p)),
                    ),
                    Text('${_cart.quantityOf(p.id)}'),
                    IconButton(
                      key: Key('add-${p.id}'),
                      tooltip: 'Add ${p.name}',
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () => setState(() => _cart.add(p)),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text('Cart (${totals.itemCount} items)',
              style: textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('code-input'),
                  controller: _code,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'Discount code',
                    border: const OutlineInputBorder(),
                    errorText: _codeError,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                key: const Key('apply-code'),
                onPressed: _applyCode,
                child: const Text('Apply'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _row('Subtotal', formatCents(totals.subtotalCents)),
          if (totals.discountCents > 0)
            _row(
              'Discount (${_cart.appliedCode})',
              formatCents(-totals.discountCents),
            ),
          _row('Total', formatCents(totals.totalCents), key: 'total'),
          const SizedBox(height: 8),
          const Text(
            'Demo cart only: there is no checkout or payment.',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {String? key}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label),
          const Spacer(),
          Text(value, key: key == null ? null : Key(key)),
        ],
      ),
    );
  }
}
