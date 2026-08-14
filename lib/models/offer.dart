import 'package:cloud_firestore/cloud_firestore.dart';

enum OfferType { combo, bogo }

class OfferItem {
  final String itemId;
  final String itemName;
  final int qty;

  OfferItem({required this.itemId, required this.itemName, required this.qty});

  Map<String, dynamic> toMap() => {
    'item_id': itemId,
    'item_name': itemName,
    'qty': qty,
  };

  factory OfferItem.fromMap(Map<String, dynamic> map) => OfferItem(
    itemId: map['item_id'] ?? '',
    itemName: map['item_name'] ?? '',
    qty: map['qty'] ?? 1,
  );
}

class OfferModel {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final OfferType type;
  final bool isActive;
  final DateTime? expiryDate;
  
  // For Combo
  final List<OfferItem> bundleItems;
  final double comboPrice;

  // For BOGO
  final String? buyItemId;
  final String? buyItemName;
  final int buyQty;
  final String? getItemId;
  final String? getItemName;
  final int getQty;

  OfferModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.type,
    this.isActive = true,
    this.expiryDate,
    this.bundleItems = const [],
    this.comboPrice = 0,
    this.buyItemId,
    this.buyItemName,
    this.buyQty = 1,
    this.getItemId,
    this.getItemName,
    this.getQty = 1,
  });

  factory OfferModel.fromFirestore(String id, Map<String, dynamic> data) {
    return OfferModel(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['image_url'] ?? '',
      type: data['type'] == 'bogo' ? OfferType.bogo : OfferType.combo,
      isActive: data['is_active'] ?? true,
      expiryDate: (data['expiry_date'] is Timestamp)
          ? (data['expiry_date'] as Timestamp).toDate()
          : null,
      bundleItems: (data['bundle_items'] as List?)
              ?.map((e) => OfferItem.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      comboPrice: (data['combo_price'] ?? 0).toDouble(),
      buyItemId: data['buy_item_id'],
      buyItemName: data['buy_item_name'],
      buyQty: data['buy_qty'] ?? 1,
      getItemId: data['get_item_id'],
      getItemName: data['get_item_name'],
      getQty: data['get_qty'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'type': type == OfferType.bogo ? 'bogo' : 'combo',
      'is_active': isActive,
      'expiry_date': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'bundle_items': bundleItems.map((e) => e.toMap()).toList(),
      'combo_price': comboPrice,
      'buy_item_id': buyItemId,
      'buy_item_name': buyItemName,
      'buy_qty': buyQty,
      'get_item_id': getItemId,
      'get_item_name': getItemName,
      'get_qty': getQty,
    };
  }
}
