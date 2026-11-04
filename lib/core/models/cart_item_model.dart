import 'product_model.dart';

class CartItemModel {
  final ProductModel product;
  final bool usePackUnit;
  final double qty;
  final int customUnitPrice;

  const CartItemModel({
    required this.product,
    required this.usePackUnit,
    required this.qty,
    required this.customUnitPrice,
  });

  double get baseDeductionQty =>
      usePackUnit ? double.parse((qty * product.packRate).toStringAsFixed(2)) : qty;

  String get unitLabel => usePackUnit ? product.packUnitName : product.baseUnit;

  int get lineTotal => (qty * customUnitPrice).round();

  CartItemModel copyWith({
    ProductModel? product,
    bool? usePackUnit,
    double? qty,
    int? customUnitPrice,
  }) {
    return CartItemModel(
      product: product ?? this.product,
      usePackUnit: usePackUnit ?? this.usePackUnit,
      qty: qty ?? this.qty,
      customUnitPrice: customUnitPrice ?? this.customUnitPrice,
    );
  }
}
