import 'package:digital_products/logic/cart.dart';
import 'package:flutter_test/flutter_test.dart';

const a = Product(id: 'a', name: 'A', category: 'X', priceCents: 1999);
const b = Product(id: 'b', name: 'B', category: 'Y', priceCents: 333);

void main() {
  test('formatCents', () {
    expect(formatCents(0), r'$0.00');
    expect(formatCents(1905), r'$19.05');
    expect(formatCents(123456789), r'$1,234,567.89');
    expect(formatCents(-250), r'-$2.50');
  });

  test('categories are distinct and sorted', () {
    expect(categoriesOf(sampleCatalog),
        ['Courses', 'Design assets', 'Templates', 'eBooks']..sort());
  });

  test('add/remove/setQuantity with clamping', () {
    final cart = Cart()
      ..add(a)
      ..add(a)
      ..add(b);
    expect(cart.quantityOf('a'), 2);
    cart.remove(b);
    expect(cart.quantities.containsKey('b'), isFalse);
    cart.setQuantity(a, 500);
    expect(cart.quantityOf('a'), Cart.maxQuantity);
    cart.setQuantity(a, -3);
    expect(cart.isEmpty, isTrue);
  });

  test('totals in integer cents with half-up discount rounding', () {
    final cart = Cart()
      ..setQuantity(a, 3)
      ..add(b);
    var t = cart.totals();
    expect(t.subtotalCents, 1999 * 3 + 333);
    expect(t.itemCount, 4);
    expect(t.totalCents, 6330);

    expect(cart.applyCode('welcome10'), isTrue);
    t = cart.totals();
    expect(t.discountCents, 633); // 633.0
    expect(t.totalCents, 6330 - 633);

    cart.setQuantity(a, 0);
    cart.setQuantity(b, 1); // 333 * 10% = 33.3 -> 33
    expect(cart.totals().discountCents, 33);
    expect(cart.applyCode('HALFOFF'), isTrue); // 166.5 -> 167
    expect(cart.totals().discountCents, 167);
    expect(cart.totals().totalCents, 166);
  });

  test('unknown code is rejected and keeps previous; empty clears', () {
    final cart = Cart()..add(a);
    cart.applyCode('HALFOFF');
    expect(cart.applyCode('FREE'), isFalse);
    expect(cart.appliedCode, 'HALFOFF');
    expect(cart.applyCode(''), isTrue);
    expect(cart.appliedCode, isNull);
    cart.clear();
    expect(cart.totals().totalCents, 0);
  });

  group('edge cases (pass 3)', () {
    test('formatCents boundaries', () {
      expect(formatCents(1), r'$0.01');
      expect(formatCents(99), r'$0.99');
      expect(formatCents(100000), r'$1,000.00');
      expect(formatCents(99999), r'$999.99');
      expect(formatCents(-1), r'-$0.01');
    });

    test('discount rounding at the half-cent boundary', () {
      const one = Product(id: 'o', name: 'O', category: 'Z', priceCents: 1);
      final cart = Cart()..add(one);
      cart.applyCode('HALFOFF'); // 0.5 cents -> 1
      expect(cart.totals().discountCents, 1);
      expect(cart.totals().totalCents, 0);
      cart.applyCode('WELCOME10'); // 0.1 cents -> 0
      expect(cart.totals().discountCents, 0);
      cart.setQuantity(one, 5); // 0.5 cents -> 1
      expect(cart.totals().discountCents, 1);
    });

    test('total never goes negative and a full cart stays exact', () {
      final cart = Cart();
      for (final p in sampleCatalog) {
        cart.setQuantity(p, Cart.maxQuantity);
      }
      cart.applyCode('HALFOFF');
      final t = cart.totals();
      final subtotal =
          sampleCatalog.fold(0, (s, p) => s + p.priceCents) * Cart.maxQuantity;
      expect(t.subtotalCents, subtotal);
      expect(t.itemCount, sampleCatalog.length * Cart.maxQuantity);
      expect(t.discountCents + t.totalCents, subtotal);
      expect(t.totalCents, greaterThanOrEqualTo(0));
    });

    test('add at the limit is a no-op; remove at zero is a no-op', () {
      final cart = Cart()..setQuantity(a, Cart.maxQuantity);
      cart.add(a);
      expect(cart.quantityOf('a'), Cart.maxQuantity);
      cart.remove(b);
      expect(cart.quantities.containsKey('b'), isFalse);
    });

    test('codes ignore case and surrounding whitespace only', () {
      final cart = Cart();
      expect(cart.applyCode('  halfOff\t'), isTrue);
      expect(cart.appliedCode, 'HALFOFF');
      expect(cart.applyCode('HALF OFF'), isFalse);
      expect(cart.applyCode('   '), isTrue);
      expect(cart.appliedCode, isNull);
    });

    test('cart order follows first add, even after quantity changes', () {
      final cart = Cart()
        ..add(b)
        ..add(a)
        ..setQuantity(b, 5);
      expect(cart.products.map((p) => p.id), ['b', 'a']);
    });

    test('CartState JSON skips non-integer quantities', () {
      final state = CartState.fromJson({
        'quantities': {'a': 2, 'b': 2.0, 'c': '3', 'd': null},
        'code': 'WELCOME10',
      });
      expect(state.quantities, {'a': 2});
      final cart = Cart()..restore(state, const [a, b]);
      expect(cart.totals().subtotalCents, 1999 * 2);
      expect(cart.appliedCode, 'WELCOME10');
    });
  });
}
