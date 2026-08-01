class AppUser {
  final String id;
  final String name;
  final String phone;
  final String address;
  final String email;
  final String dob;

  AppUser({
    required this.id,
    required this.name,
    required this.phone,
    this.address = '',
    this.email = '',
    this.dob = '',
  });

  factory AppUser.fromFirestore(String id, Map<String, dynamic> data) {
    return AppUser(
      id: id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
      email: data['email'] ?? '',
      dob: data['dob'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'address': address,
      'email': email,
      'dob': dob,
    };
  }
}
