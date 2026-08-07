class AddressModel {
  final String id;
  final String label; // Home, Work, etc.
  final String fullAddress;
  final double latitude;
  final double longitude;
  final String recipientName;
  final String recipientPhone;

  AddressModel({
    required this.id,
    required this.label,
    required this.fullAddress,
    required this.latitude,
    required this.longitude,
    required this.recipientName,
    required this.recipientPhone,
  });

  factory AddressModel.fromFirestore(String id, Map<String, dynamic> data) {
    return AddressModel(
      id: id,
      label: data['label'] ?? '',
      fullAddress: data['full_address'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      recipientName: data['recipient_name'] ?? '',
      recipientPhone: data['recipient_phone'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'full_address': fullAddress,
      'latitude': latitude,
      'longitude': longitude,
      'recipient_name': recipientName,
      'recipient_phone': recipientPhone,
    };
  }
}
