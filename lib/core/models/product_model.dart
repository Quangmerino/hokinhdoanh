import 'dart:convert';

class ProductModel {
  final int id;
  final String sku;
  final String name;
  final int categoryId;
  final int primarySupplierId;
  final List<int> supplierIds;
  final String baseUnit;
  final double stockQty;
  final double minStock;
  final int costPrice;
  final int retailPrice;
  final String packUnitName;
  final double packRate;
  final int packPrice;
  final bool trackReturnableShell;
  final String specNote;
  final String? imagePath;

  const ProductModel({
    required this.id,
    required this.sku,
    required this.name,
    required this.categoryId,
    this.primarySupplierId = 0,
    this.supplierIds = const [],
    required this.baseUnit,
    this.stockQty = 0,
    this.minStock = 5,
    this.costPrice = 0,
    required this.retailPrice,
    this.packUnitName = '',
    this.packRate = 1,
    this.packPrice = 0,
    this.trackReturnableShell = false,
    this.specNote = '',
    this.imagePath,
  });

  bool get hasPackUnit => packUnitName.trim().isNotEmpty && packRate > 1;

  String get formattedStock {
    if (hasPackUnit) {
      final fullPacks = (stockQty / packRate).floor();
      final rem = double.parse((stockQty % packRate).toStringAsFixed(1));
      if (rem > 0) {
        return '$stockQty $baseUnit ($fullPacks $packUnitName + $rem $baseUnit)';
      }
      return '$stockQty $baseUnit ($fullPacks $packUnitName)';
    }
    return '$stockQty $baseUnit';
  }

  ProductModel copyWith({
    String? sku,
    String? name,
    int? categoryId,
    int? primarySupplierId,
    List<int>? supplierIds,
    String? baseUnit,
    double? stockQty,
    double? minStock,
    int? costPrice,
    int? retailPrice,
    String? packUnitName,
    double? packRate,
    int? packPrice,
    bool? trackReturnableShell,
    String? specNote,
    String? imagePath,
  }) {
    return ProductModel(
      id: id,
      sku: sku ?? this.sku,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      primarySupplierId: primarySupplierId ?? this.primarySupplierId,
      supplierIds: supplierIds ?? this.supplierIds,
      baseUnit: baseUnit ?? this.baseUnit,
      stockQty: stockQty ?? this.stockQty,
      minStock: minStock ?? this.minStock,
      costPrice: costPrice ?? this.costPrice,
      retailPrice: retailPrice ?? this.retailPrice,
      packUnitName: packUnitName ?? this.packUnitName,
      packRate: packRate ?? this.packRate,
      packPrice: packPrice ?? this.packPrice,
      trackReturnableShell: trackReturnableShell ?? this.trackReturnableShell,
      specNote: specNote ?? this.specNote,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'sku': sku,
        'name': name,
        'category_id': categoryId,
        'primary_supplier_id': primarySupplierId,
        'supplier_ids_json': jsonEncode(supplierIds),
        'base_unit': baseUnit,
        'stock_qty': stockQty,
        'min_stock': minStock,
        'cost_price': costPrice,
        'retail_price': retailPrice,
        'pack_unit_name': packUnitName,
        'pack_rate': packRate,
        'pack_price': packPrice,
        'track_shell': trackReturnableShell ? 1 : 0,
        'spec_note': specNote,
        'image_path': imagePath,
      };

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    final supJson = map['supplier_ids_json'] as String? ?? '[]';
    final List<dynamic> decoded = jsonDecode(supJson) as List<dynamic>;
    return ProductModel(
      id: map['id'] as int,
      sku: map['sku'] as String? ?? '',
      name: map['name'] as String,
      categoryId: (map['category_id'] as num).toInt(),
      primarySupplierId: (map['primary_supplier_id'] as num?)?.toInt() ?? 0,
      supplierIds: decoded.map((e) => (e as num).toInt()).toList(),
      baseUnit: map['base_unit'] as String? ?? 'Cái',
      stockQty: (map['stock_qty'] as num?)?.toDouble() ?? 0.0,
      minStock: (map['min_stock'] as num?)?.toDouble() ?? 5.0,
      costPrice: (map['cost_price'] as num?)?.toInt() ?? 0,
      retailPrice: (map['retail_price'] as num?)?.toInt() ?? 0,
      packUnitName: map['pack_unit_name'] as String? ?? '',
      packRate: (map['pack_rate'] as num?)?.toDouble() ?? 1.0,
      packPrice: (map['pack_price'] as num?)?.toInt() ?? 0,
      trackReturnableShell: ((map['track_shell'] as num?)?.toInt() ?? 0) == 1,
      specNote: map['spec_note'] as String? ?? '',
      imagePath: map['image_path'] as String?,
    );
  }
}
