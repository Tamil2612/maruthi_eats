import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/menu_item.dart';
import '../models/coupon.dart';
import '../models/offer.dart';

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => _items;

  int get itemCount => _items.values.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => _items.values.fold(0, (sum, item) => sum + item.total);

  Coupon? _appliedCoupon;
  Coupon? get appliedCoupon => _appliedCoupon;

  double get couponDiscount {
    if (_appliedCoupon == null) return 0.0;
    return _appliedCoupon!.amount;
  }

  double get deliveryFee => isEmpty ? 0.0 : 30.0;
  double get totalPayable => (subtotal - couponDiscount) + deliveryFee;

  bool get isEmpty => _items.isEmpty;

  void addItem(MenuItem menuItem) {
    if (_items.containsKey(menuItem.id)) {
      _items[menuItem.id]!.quantity++;
    } else {
      _items[menuItem.id] = CartItem(
        id: menuItem.id,
        name: menuItem.name,
        unitPrice: menuItem.effectivePrice,
        imageUrl: menuItem.imageUrl,
        isVeg: menuItem.isVeg,
        menuItem: menuItem,
      );
    }
    notifyListeners();
  }

  void addOffer(OfferModel offer, {MenuItem? buyItem, MenuItem? getItem}) {
    if (offer.type == OfferType.combo) {
      final offerId = 'offer_${offer.id}';
      if (_items.containsKey(offerId)) {
        _items[offerId]!.quantity++;
      } else {
        String desc = offer.bundleItems.map((e) => "${e.itemName} x ${e.qty}").join(", ");
        _items[offerId] = CartItem(
          id: offerId,
          name: offer.title,
          unitPrice: offer.comboPrice,
          imageUrl: offer.imageUrl,
          isVeg: true, 
          isOffer: true,
          offerDescription: desc,
          offerModel: offer,
        );
      }
    } else if (offer.type == OfferType.bogo && buyItem != null && getItem != null) {
      // For BOGO, we add two items linked by a group ID
      final groupId = 'bogo_${offer.id}_${DateTime.now().millisecondsSinceEpoch}';
      
      // 1. Add the paid item
      final buyId = '${groupId}_buy';
      _items[buyId] = CartItem(
        id: buyId,
        name: buyItem.name,
        unitPrice: buyItem.effectivePrice,
        quantity: offer.buyQty,
        imageUrl: buyItem.imageUrl,
        isVeg: buyItem.isVeg,
        isOffer: true,
        parentOfferId: groupId,
        menuItem: buyItem,
        offerDescription: 'Part of: ${offer.title}',
      );

      // 2. Add the free item
      final getId = '${groupId}_get';
      _items[getId] = CartItem(
        id: getId,
        name: getItem.name,
        unitPrice: 0.0,
        originalPrice: getItem.effectivePrice,
        quantity: offer.getQty,
        imageUrl: getItem.imageUrl,
        isVeg: getItem.isVeg,
        isOffer: true,
        isFree: true,
        parentOfferId: groupId,
        menuItem: getItem,
        offerDescription: 'FREE with ${offer.title}',
      );
    }
    notifyListeners();
  }

  void syncMenuItem(MenuItem freshItem) {
    if (_items.containsKey(freshItem.id)) {
      final oldQty = _items[freshItem.id]!.quantity;
      _items[freshItem.id] = CartItem(
        id: freshItem.id,
        name: freshItem.name,
        unitPrice: freshItem.effectivePrice,
        quantity: oldQty,
        imageUrl: freshItem.imageUrl,
        isVeg: freshItem.isVeg,
        menuItem: freshItem,
      );
      notifyListeners();
    }
  }

  void removeOne(String itemId) {
    if (!_items.containsKey(itemId)) return;
    
    final item = _items[itemId]!;
    if (item.parentOfferId != null) {
      // Atomic removal for linked BOGO items
      final parentId = item.parentOfferId;
      _items.removeWhere((key, value) => value.parentOfferId == parentId);
    } else {
      if (item.quantity > 1) {
        item.quantity--;
      } else {
        _items.remove(itemId);
      }
    }
    notifyListeners();
  }

  int quantityOf(String itemId) => _items[itemId]?.quantity ?? 0;

  void applyCoupon(Coupon coupon) {
    _appliedCoupon = coupon;
    notifyListeners();
  }

  void removeCoupon() {
    _appliedCoupon = null;
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _appliedCoupon = null;
    notifyListeners();
  }
}
