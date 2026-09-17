import 'package:flutter_test/flutter_test.dart';
import 'package:maruthi_eats/models/menu_item.dart';
import 'package:maruthi_eats/providers/cart_provider.dart';

void main() {
  test('cart totals reflect quantities and delivery fee', () {
    final cart = CartProvider();
    final item = MenuItem(
      id: 'idli',
      name: 'Idli',
      description: '',
      price: 40,
      category: 'Breakfast',
      imageUrl: '',
      isVeg: true,
    );

    cart.addItem(item);
    cart.addItem(item);

    expect(cart.itemCount, 2);
    expect(cart.subtotal, 80);
    expect(cart.deliveryFee, 30);
    expect(cart.totalPayable, 110);
  });
}
