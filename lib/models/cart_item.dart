import 'menu_item.dart';
import 'offer.dart';

class CartItem {
  final String id;
  final String name;
  final double unitPrice;
  final double? originalPrice;
  int quantity;
  final String imageUrl;
  final bool isVeg;
  final bool isOffer;
  final bool isFree;
  final String? parentOfferId;
  final String? offerDescription;
  
  // Reference to original objects if needed
  final MenuItem? menuItem;
  final OfferModel? offerModel;

  CartItem({
    required this.id,
    required this.name,
    required this.unitPrice,
    this.originalPrice,
    this.quantity = 1,
    required this.imageUrl,
    required this.isVeg,
    this.isOffer = false,
    this.isFree = false,
    this.parentOfferId,
    this.offerDescription,
    this.menuItem,
    this.offerModel,
  });

  double get total => unitPrice * quantity;

  Map<String, dynamic> toOrderMap() {
    return {
      'item_id': id,
      'name': name,
      'price': unitPrice,
      'qty': quantity,
      'is_offer': isOffer,
      'is_free': isFree,
      if (parentOfferId != null) 'parent_offer_id': parentOfferId,
      if (offerDescription != null) 'offer_description': offerDescription,
    };
  }
}
