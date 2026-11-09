import 'package:flutter/foundation.dart';

import 'package:sekolahku/models/product.dart';

/// Keranjang belanja koperasi (state bersama lewat ChangeNotifier).
class Cart extends ChangeNotifier {
  static final i = Cart();
  final Map<Product, int> items = {};

  void add(Product p, int q) {
    items[p] = (items[p] ?? 0) + q;
    notifyListeners();
  }

  void clear() {
    items.clear();
    notifyListeners();
  }

  int get total => items.entries.fold(0, (s, e) => s + e.key.price * e.value);
}