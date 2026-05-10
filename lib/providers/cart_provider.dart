import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/shop_model.dart';

class CartItem {
  final ProductModel product;
  final ShopModel shop;
  int qty;

  CartItem({
    required this.product,
    required this.shop,
    this.qty = 1,
  });
}

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items =>
      List.unmodifiable(_items);

  int get totalCount =>
      _items.fold(0, (sum, i) => sum + i.qty);

  double get totalPrice => _items.fold(
    0,
    (sum, i) => sum + (i.product.price * i.qty),
  );

  bool isInCart(String productId) => _items.any(
    (i) => i.product.id == productId,
  );

  void addItem(
    ProductModel product,
    ShopModel shop,
  ) {
    if (product.stock <= 0) return;

    final index = _items.indexWhere(
      (i) => i.product.id == product.id,
    );
    if (index >= 0) {
      if (_items[index].qty < product.stock) {
        _items[index].qty++;
      }
    } else {
      _items.add(
        CartItem(product: product, shop: shop),
      );
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.removeWhere(
      (i) => i.product.id == productId,
    );
    notifyListeners();
  }

  void incrementQty(String productId) {
    final index = _items.indexWhere(
      (i) => i.product.id == productId,
    );
    if (index >= 0) {
      final item = _items[index];
      if (item.qty < item.product.stock) {
        item.qty++;
      }
      notifyListeners();
    }
  }

  void decrementQty(String productId) {
    final index = _items.indexWhere(
      (i) => i.product.id == productId,
    );
    if (index >= 0) {
      if (_items[index].qty <= 1) {
        _items.removeAt(index);
      } else {
        _items[index].qty--;
      }
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
