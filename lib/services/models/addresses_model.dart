/// ----------------------
/// MODELE Address
/// ----------------------
class Address {
  final int id;
  final String name;
  final String address;
  final bool isDefault;

  Address({
    required this.id,
    required this.name,
    required this.address,
    this.isDefault = false,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      isDefault: json['is_default'] == true || json['isDefault'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'is_default': isDefault,
    };
  }
}