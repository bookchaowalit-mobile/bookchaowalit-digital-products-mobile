/// Catalog and cart maths in integer cents (no floating-point money).
library;

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.priceCents,
  });

  final String id;
  final String name;
  final String category;
  final int priceCents;
}

const sampleCatalog = [
  Product(
      id: 'ebook-flutter',
      name: 'Flutter Starter eBook',
      category: 'eBooks',
      priceCents: 1900),
  Product(
      id: 'ebook-dart',
      name: 'Dart Patterns eBook',
      category: 'eBooks',
      priceCents: 1500),
  Product(
      id: 'tpl-notion',
      name: 'Notion Planner Template',
      category: 'Templates',
      priceCents: 900),
  Product(
      id: 'tpl-resume',
      name: 'Resume Template Pack',
      category: 'Templates',
      priceCents: 1200),
  Product(
      id: 'icons-line',
      name: 'Line Icon Set (500)',
      category: 'Design assets',
      priceCents: 2500),
  Product(
      id: 'course-git',
      name: 'Git in One Hour',
      category: 'Courses',
      priceCents: 4900),
];

/// Demo discount codes -> percentage off.
const discountCodes = {'WELCOME10': 10, 'HALFOFF': 50};

List<String> categoriesOf(Iterable<Product> products) =>
    {for (final p in products) p.category}.toList()..sort();

String formatCents(int cents) {
  final sign = cents < 0 ? '-' : '';
  final abs = cents.abs();
  final whole = (abs ~/ 100).toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => ',',
      );
  return '$sign\$$whole.${(abs % 100).toString().padLeft(2, '0')}';
}

class CartTotals {
  const CartTotals({
    required this.subtotalCents,
    required this.discountCents,
    required this.totalCents,
    required this.itemCount,
  });

  final int subtotalCents;
  final int discountCents;
  final int totalCents;
  final int itemCount;
}

class Cart {
  final Map<String, int> _qty = {};
  final Map<String, Product> _products = {};
  String? _code;

  static const maxQuantity = 99;

  Map<String, int> get quantities => Map.unmodifiable(_qty);
  List<Product> get products => _qty.keys.map((id) => _products[id]!).toList();
  String? get appliedCode => _code;
  bool get isEmpty => _qty.isEmpty;

  int quantityOf(String id) => _qty[id] ?? 0;

  void add(Product p) => setQuantity(p, quantityOf(p.id) + 1);

  void remove(Product p) => setQuantity(p, quantityOf(p.id) - 1);

  /// Sets the quantity (clamped to 0..[maxQuantity]); 0 removes the line.
  void setQuantity(Product p, int qty) {
    final q = qty.clamp(0, maxQuantity);
    if (q == 0) {
      _qty.remove(p.id);
      _products.remove(p.id);
    } else {
      _qty[p.id] = q;
      _products[p.id] = p;
    }
  }

  /// Applies a code (case-insensitive). Returns false and keeps the previous
  /// code when it is unknown. An empty code clears the discount.
  bool applyCode(String code) {
    final c = code.trim().toUpperCase();
    if (c.isEmpty) {
      _code = null;
      return true;
    }
    if (!discountCodes.containsKey(c)) return false;
    _code = c;
    return true;
  }

  void clear() {
    _qty.clear();
    _products.clear();
    _code = null;
  }

  /// Serializable snapshot of the cart (product ids, quantities, code).
  CartState snapshot() => CartState(quantities: Map.of(_qty), code: _code);

  /// Replaces the cart with [state], resolving ids against [catalog].
  /// Unknown products, non-positive quantities and unknown codes are
  /// dropped; quantities above [maxQuantity] are clamped.
  void restore(CartState state, Iterable<Product> catalog) {
    clear();
    final byId = {for (final p in catalog) p.id: p};
    state.quantities.forEach((id, q) {
      final product = byId[id];
      if (product != null) setQuantity(product, q);
    });
    if (state.code != null) applyCode(state.code!);
  }

  CartTotals totals() {
    var subtotal = 0;
    var count = 0;
    _qty.forEach((id, q) {
      subtotal += _products[id]!.priceCents * q;
      count += q;
    });
    final pct = _code == null ? 0 : discountCodes[_code]!;
    // Round the discount half-up to the nearest cent.
    final discount = (subtotal * pct + 50) ~/ 100;
    return CartTotals(
      subtotalCents: subtotal,
      discountCents: discount,
      totalCents: subtotal - discount,
      itemCount: count,
    );
  }
}

class CartState {
  const CartState({this.quantities = const {}, this.code});

  final Map<String, int> quantities;
  final String? code;

  Map<String, Object?> toJson() => {'quantities': quantities, 'code': code};

  /// Entries with a non-integer quantity are skipped; a malformed shape
  /// throws.
  static CartState fromJson(Map<String, Object?> json) {
    final raw = json['quantities'] as Map? ?? const {};
    return CartState(
      quantities: {
        for (final e in raw.entries)
          if (e.key is String && e.value is int)
            e.key as String: e.value as int,
      },
      code: json['code'] as String?,
    );
  }
}
