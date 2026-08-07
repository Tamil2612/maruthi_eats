import 'menu_item.dart';

class CartItem {
  MenuItem menuItem;
  int quantity;

  CartItem({required this.menuItem, this.quantity = 1});

  double get total => menuItem.effectivePrice * quantity;

  Map<String, dynamic> toOrderMap() {
    return {
      'item_id': menuItem.id,
      'name': menuItem.name,
      'price': menuItem.effectivePrice,
      'qty': quantity,
    };
  }
}
