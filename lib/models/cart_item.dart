import 'menu_item.dart';

class CartItem {
  final MenuItem menuItem;
  int quantity;

  CartItem({required this.menuItem, this.quantity = 1});

  double get total => menuItem.price * quantity;

  Map<String, dynamic> toOrderMap() {
    return {
      'item_id': menuItem.id,
      'name': menuItem.name,
      'price': menuItem.price,
      'qty': quantity,
    };
  }
}
