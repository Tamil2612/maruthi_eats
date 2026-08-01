class AddressModel {
  final String id;
  final String label; // Home, Work, etc.
  final String fullAddress;
  final double latitude;
  final double longitude;

  AddressModel({
    required this.id,
    required this.label,
    required this.fullAddress,
    required this.latitude,
    required this.longitude,
  });

  factory AddressModel.fromFirestore(String id, Map<String, dynamic> data) {
    return AddressModel(
      id: id,
      label: data['label'] ?? '',
      fullAddress: data['full_address'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'full_address': fullAddress,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
