import 'dart:convert';

import 'package:digital_products/data/cart_repository.dart';
import 'package:digital_products/logic/cart.dart';
import 'package:digital_products/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const repo = SharedPreferencesCartRepository();
  const key = 'digital_products_cart_v1';
  const state = CartState(quantities: {'ebook-flutter': 2}, code: 'WELCOME10');

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('round-trips the cart through shared_preferences', () async {
    await repo.save(state);
    expect((await repo.load())!.toJson(), state.toJson());
  });

  test('empty storage loads null', () async {
    expect(await repo.load(), isNull);
  });

  test('skips bad quantities and rejects non-object payloads', () async {
    SharedPreferences.setMockInitialValues({
      key: jsonEncode({
        'quantities': {'ebook-flutter': 1, 'ebook-dart': 'x'},
        'code': null,
      }),
    });
    expect((await repo.load())!.quantities, {'ebook-flutter': 1});

    SharedPreferences.setMockInitialValues({key: '[]'});
    expect(repo.load(), throwsFormatException);
  });

  test('restore drops unknown products and codes and clamps quantities', () {
    final cart = Cart()
      ..restore(
        const CartState(
          quantities: {'ebook-flutter': 500, 'gone': 3, 'ebook-dart': 0},
          code: 'EXPIRED',
        ),
        sampleCatalog,
      );
    expect(cart.quantities, {'ebook-flutter': Cart.maxQuantity});
    expect(cart.appliedCode, isNull);
  });

  Future<void> pumpHome(WidgetTester tester, CartRepository repo) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: HomeScreen(repository: repo)));
    await tester.pumpAndSettle();
  }

  testWidgets('restores a saved cart and saves changes', (tester) async {
    final memory = InMemoryCartRepository(state);
    await pumpHome(tester, memory);
    expect(
      tester.widget<Text>(find.byKey(const Key('total'))).data,
      r'$34.20',
    );

    await tester.tap(find.byKey(const Key('add-course-git')));
    await tester.pumpAndSettle();
    expect((await memory.load())!.quantities, {
      'ebook-flutter': 2,
      'course-git': 1,
    });
  });

  testWidgets('shows an error when the saved cart cannot be read',
      (tester) async {
    await pumpHome(tester, _FailingRepository());
    expect(find.byKey(const Key('storage-error')), findsOneWidget);
  });
}

class _FailingRepository implements CartRepository {
  @override
  Future<CartState?> load() async => throw const FormatException('bad');

  @override
  Future<void> save(CartState state) async => throw StateError('full');
}
