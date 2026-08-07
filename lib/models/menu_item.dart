class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String imageUrl;
  final bool isVeg;
  final bool available;
  final double discountPrice;
  final bool hasDiscount;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.imageUrl,
    required this.isVeg,
    this.available = true,
    this.discountPrice = 0,
    this.hasDiscount = false,
  });

  double get effectivePrice => hasDiscount ? discountPrice : price;

  factory MenuItem.fromFirestore(String id, Map<String, dynamic> data) {
    return MenuItem(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      category: data['category'] ?? 'Other',
      imageUrl: data['image_url'] ?? '',
      isVeg: data['is_veg'] ?? true,
      available: data['available'] ?? true,
      discountPrice: (data['discount_price'] ?? 0).toDouble(),
      hasDiscount: data['has_discount'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'image_url': imageUrl,
      'is_veg': isVeg,
      'available': available,
      'discount_price': discountPrice,
      'has_discount': hasDiscount,
    };
  }
}
