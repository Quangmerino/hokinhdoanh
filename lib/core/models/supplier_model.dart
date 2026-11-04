import 'dart:convert';

class SupplierModel {
  final int id;
  final String name;
  final String phone;
  final String address;
  final int payableDebt;
  final List<int> categoryIds;

  const SupplierModel({
    required this.id,
    required this.name,
    this.phone = '',
    this.address = '',
    this.payableDebt = 0,
    this.categoryIds = const [],
  });

  SupplierModel copyWith({
    String? name,
    String? phone,
    String? address,
    int? payableDebt,
    List<int>? categoryIds,
  }) {
    return SupplierModel(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      payableDebt: payableDebt ?? this.payableDebt,
      categoryIds: categoryIds ?? this.categoryIds,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'address': address,
        'payable_debt': payableDebt,
        'category_ids_json': jsonEncode(categoryIds),
      };

  factory SupplierModel.fromMap(Map<String, dynamic> map) {
    final rawJson = map['category_ids_json'] as String? ?? '[]';
    final List<dynamic> decoded = jsonDecode(rawJson) as List<dynamic>;
    return SupplierModel(
      id: map['id'] as int,
      name: map['name'] as String,
      phone: map['phone'] as String? ?? '',
      address: map['address'] as String? ?? '',
      payableDebt: (map['payable_debt'] as num?)?.toInt() ?? 0,
      categoryIds: decoded.map((e) => (e as num).toInt()).toList(),
    );
  }
}
