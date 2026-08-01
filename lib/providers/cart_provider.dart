import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/menu_item.dart';

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => _items;

  int get itemCount => _items.values.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => _items.values.fold(0, (sum, item) => sum + item.total);

  bool get isEmpty => _items.isEmpty;

  void addItem(MenuItem menuItem) {
    if (_items.containsKey(menuItem.id)) {
      _items[menuItem.id]!.quantity++;
    } else {
      _items[menuItem.id] = CartItem(menuItem: menuItem);
    }
    notifyListeners();
  }

  void removeOne(String menuItemId) {
    if (!_items.containsKey(menuItemId)) return;
    if (_items[menuItemId]!.quantity > 1) {
      _items[menuItemId]!.quantity--;
    } else {
      _items.remove(menuItemId);
    }
    notifyListeners();
  }

  int quantityOf(String menuItemId) => _items[menuItemId]?.quantity ?? 0;

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
