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
  double get totalPayable {
    final payable = (subtotal - couponDiscount) + deliveryFee;
    return payable < 0 ? 0.0 : payable;
  }

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
    _revalidateCoupon();
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
      // Predictable ID for BOGO to allow stacking if added multiple times
      final groupId = 'bogo_${offer.id}';
      
      if (_items.containsKey('${groupId}_buy')) {
        _items['${groupId}_buy']!.quantity += offer.buyQty;
        _items['${groupId}_get']!.quantity += offer.getQty;
      } else {
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
          offerModel: offer,
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
          offerModel: offer,
          offerDescription: 'FREE with ${offer.title}',
        );
      }
    }
    _revalidateCoupon();
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
      _revalidateCoupon();
      notifyListeners();
    }
  }

  void incrementItem(String itemId) {
    if (!_items.containsKey(itemId)) return;
    
    final item = _items[itemId]!;
    if (item.parentOfferId != null && item.offerModel != null) {
      final parentId = item.parentOfferId;
      final offer = item.offerModel!;
      
      // Increment all items in this BOGO set by their respective offer quantities
      _items.forEach((key, val) {
        if (val.parentOfferId == parentId) {
          if (key.endsWith('_buy')) {
            val.quantity += offer.buyQty;
          } else if (key.endsWith('_get')) {
            val.quantity += offer.getQty;
          }
        }
      });
    } else {
      _items[itemId]!.quantity++;
    }
    _revalidateCoupon();
    notifyListeners();
  }

  /// Returns true if removing this item caused the applied coupon to be
  /// dropped (e.g. subtotal fell below the coupon's minimum order value),
  /// so the UI can inform the user.
  bool removeOne(String itemId) {
    if (!_items.containsKey(itemId)) return false;

    final item = _items[itemId]!;
    if (item.parentOfferId != null && item.offerModel != null) {
      final parentId = item.parentOfferId;
      final offer = item.offerModel!;
      
      // Check if we can decrement the set or must remove it
      final canDecrement = item.quantity > offer.buyQty; // buy and get have same ratio multipliers
      
      if (canDecrement) {
        _items.forEach((key, val) {
          if (val.parentOfferId == parentId) {
            if (key.endsWith('_buy')) {
              val.quantity -= offer.buyQty;
            } else if (key.endsWith('_get')) {
              val.quantity -= offer.getQty;
            }
          }
        });
      } else {
        _items.removeWhere((key, value) => value.parentOfferId == parentId);
      }
    } else {
      if (item.quantity > 1) {
        item.quantity--;
      } else {
        _items.remove(itemId);
      }
    }
    final couponDropped = _revalidateCoupon();
    notifyListeners();
    return couponDropped;
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

  /// Drops the applied coupon if the cart no longer meets its terms
  /// (min order value, expiry, or active flag). Called after every
  /// mutation that can change the subtotal so a coupon applied on a
  /// larger cart can't silently keep discounting a smaller one.
  bool _revalidateCoupon() {
    final coupon = _appliedCoupon;
    if (coupon == null) return false;

    final expired = coupon.expiryDate != null && coupon.expiryDate!.isBefore(DateTime.now());
    final belowMinOrder = subtotal < coupon.minOrderValue;

    if (!coupon.isActive || expired || belowMinOrder) {
      _appliedCoupon = null;
      return true;
    }
    return false;
  }
}
