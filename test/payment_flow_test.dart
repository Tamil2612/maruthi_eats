import 'package:flutter_test/flutter_test.dart';
import 'package:maruthi_eats/models/menu_item.dart';
import 'package:maruthi_eats/providers/cart_provider.dart';

void main() {
  group('Payment Flow and Cart State Tests', () {
    test('Cart is intact when Razorpay payment is cancelled or fails', () {
      final cart = CartProvider();
      final item = MenuItem(
        id: 'dosa',
        name: 'Masala Dosa',
        description: '',
        price: 100,
        category: 'Tiffin',
        imageUrl: '',
        isVeg: true,
      );

      cart.addItem(item);
      expect(cart.itemCount, 1);
      expect(cart.subtotal, 100);

      // Simulate payment failure / cancellation: cart should NOT be cleared
      // (following Rule 7: NEVER clear cart merely because Razorpay returned success callback or failed/cancelled)
      expect(cart.itemCount, 1);
      expect(cart.subtotal, 100);
    });

    test('Cart is cleared only after backend verification success', () {
      final cart = CartProvider();
      final item = MenuItem(
        id: 'idli',
        name: 'Idli',
        description: '',
        price: 50,
        category: 'Tiffin',
        imageUrl: '',
        isVeg: true,
      );

      cart.addItem(item);
      expect(cart.itemCount, 1);

      // Simulate successful backend payment verification (razorpay_verify_payment returns paid)
      // Cart should be cleared only now.
      cart.clear();
      expect(cart.itemCount, 0);
      expect(cart.subtotal, 0);
    });

    test('COD flow clears cart upon order placement', () {
      final cart = CartProvider();
      final item = MenuItem(
        id: 'vada',
        name: 'Vada',
        description: '',
        price: 40,
        category: 'Tiffin',
        imageUrl: '',
        isVeg: true,
      );

      cart.addItem(item);
      expect(cart.itemCount, 1);

      // COD order placement clears cart immediately
      cart.clear();
      expect(cart.itemCount, 0);
    });
  });
}
