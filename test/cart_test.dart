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
}
