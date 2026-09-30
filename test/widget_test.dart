import 'package:digital_products/data/cart_repository.dart';
import 'package:digital_products/logic/cart.dart';
import 'package:digital_products/main.dart';
import 'package:digital_products/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('app shell shows shop and about tab', (tester) async {
    await tester.pumpWidget(const DigitalProductsApp());
    await tester.pumpAndSettle();
    expect(find.text('Digital Products'), findsWidgets);
    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();
    expect(find.text('Features'), findsOneWidget);
  });

  testWidgets('adding items and a code updates the total', (tester) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();
    Text total() => tester.widget<Text>(find.byKey(const Key('total')));
    expect(total().data, r'$0.00');

    await tester.tap(find.byKey(const Key('add-ebook-flutter')));
    await tester.tap(find.byKey(const Key('add-ebook-flutter')));
    await tester.pump();
    expect(total().data, r'$38.00');

    await tester.enterText(find.byKey(const Key('code-input')), 'nope');
    await tester.tap(find.byKey(const Key('apply-code')));
    await tester.pump();
    expect(find.text('Unknown code'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('code-input')), 'welcome10');
    await tester.tap(find.byKey(const Key('apply-code')));
    await tester.pump();
    expect(total().data, r'$34.20');

    await tester.tap(find.text('Templates'));
    await tester.pump();
    expect(find.text('Flutter Starter eBook'), findsNothing);
  });

  Widget home({double textScale = 1, CartRepository? repository}) =>
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: HomeScreen(repository: repository),
        ),
      );

  testWidgets('add is disabled at the per-product limit', (tester) async {
    await tester.pumpWidget(
      home(
        repository: InMemoryCartRepository(
          const CartState(quantities: {'ebook-flutter': Cart.maxQuantity}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final add = tester.widget<IconButton>(
      find.byKey(const Key('add-ebook-flutter')),
    );
    expect(add.onPressed, isNull);
    expect(add.tooltip, 'Maximum ${Cart.maxQuantity} per product');
    expect(
      tester.widget<Text>(find.byKey(const Key('qty-ebook-flutter'))).data,
      '${Cart.maxQuantity}',
    );
  });

  testWidgets('quantity is announced with the product name', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(home());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-ebook-dart')));
    await tester.pump();
    expect(
      find.bySemanticsLabel(RegExp('1 of Dart Patterns eBook in cart')),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('meets tap-target, label and contrast guidelines', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(home());
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });

  testWidgets('lays out at 200% text scale without overflow', (tester) async {
    await tester.pumpWidget(home(textScale: 2));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
