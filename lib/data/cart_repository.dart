/// Persistence for the cart.
///
/// The UI depends only on [CartRepository]; the app wires in
/// [SharedPreferencesCartRepository] and tests use [InMemoryCartRepository].
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../logic/cart.dart';

abstract interface class CartRepository {
  /// Returns the saved cart, or null when nothing has been saved yet.
  Future<CartState?> load();
  Future<void> save(CartState state);
}

/// Stores the cart as one JSON object under [storageKey].
class SharedPreferencesCartRepository implements CartRepository {
  const SharedPreferencesCartRepository({
    this.storageKey = 'digital_products_cart_v1',
  });

  final String storageKey;

  @override
  Future<CartState?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = prefs.getString(storageKey);
    if (payload == null || payload.isEmpty) return null;
    final decoded = jsonDecode(payload);
    if (decoded is! Map) {
      throw const FormatException('Saved cart is not an object.');
    }
    return CartState.fromJson(Map<String, Object?>.from(decoded));
  }

  @override
  Future<void> save(CartState state) async {
    final prefs = await SharedPreferences.getInstance();
    final ok = await prefs.setString(storageKey, jsonEncode(state.toJson()));
    if (!ok) throw StateError('The device did not save the cart.');
  }
}

class InMemoryCartRepository implements CartRepository {
  InMemoryCartRepository([this._state]);

  CartState? _state;

  @override
  Future<CartState?> load() async => _state;

  @override
  Future<void> save(CartState state) async => _state = state;
}

const CartRepository deviceCartRepository = SharedPreferencesCartRepository();
