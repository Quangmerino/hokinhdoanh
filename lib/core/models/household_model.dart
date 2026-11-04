import 'dart:convert';
import 'debt_ledger_entry.dart';

class HouseholdModel {
  final int id;
  final String name;
  final String headName;
  final String phone;
  final String address;
  final int creditLimit;
  final int currentDebt;
  final int containerOwed;
  final List<String> members;
  final List<DebtLedgerEntry> ledger;

  const HouseholdModel({
    required this.id,
    required this.name,
    required this.headName,
    this.phone = '',
    this.address = '',
    this.creditLimit = 20000000,
    this.currentDebt = 0,
    this.containerOwed = 0,
    this.members = const [],
    this.ledger = const [],
  });

  HouseholdModel copyWith({
    String? name,
    String? headName,
    String? phone,
    String? address,
    int? creditLimit,
    int? currentDebt,
    int? containerOwed,
    List<String>? members,
    List<DebtLedgerEntry>? ledger,
  }) {
    return HouseholdModel(
      id: id,
      name: name ?? this.name,
      headName: headName ?? this.headName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      creditLimit: creditLimit ?? this.creditLimit,
      currentDebt: currentDebt ?? this.currentDebt,
      containerOwed: containerOwed ?? this.containerOwed,
      members: members ?? this.members,
      ledger: ledger ?? this.ledger,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'head_name': headName,
        'phone': phone,
        'address': address,
        'credit_limit': creditLimit,
        'current_debt': currentDebt,
        'container_owed': containerOwed,
        'members_json': jsonEncode(members),
      };

  factory HouseholdModel.fromMap(
    Map<String, dynamic> map, {
    List<DebtLedgerEntry> ledger = const [],
  }) {
    final memJson = map['members_json'] as String? ?? '[]';
    final List<dynamic> decoded = jsonDecode(memJson) as List<dynamic>;
    return HouseholdModel(
      id: map['id'] as int,
      name: map['name'] as String,
      headName: map['head_name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      address: map['address'] as String? ?? '',
      creditLimit: (map['credit_limit'] as num?)?.toInt() ?? 0,
      currentDebt: (map['current_debt'] as num?)?.toInt() ?? 0,
      containerOwed: (map['container_owed'] as num?)?.toInt() ?? 0,
      members: decoded.map((e) => e.toString()).toList(),
      ledger: ledger,
    );
  }
}
