class OrderRecordModel {
  final int id;
  final String dateStr;
  final String orderType; // 'SALE' or 'PURCHASE'
  final int categoryRootId;
  final int totalAmount;
  final int cogs;
  final int paidAmount;
  final int debtAmount;
  final String description;

  const OrderRecordModel({
    required this.id,
    required this.dateStr,
    required this.orderType,
    required this.categoryRootId,
    required this.totalAmount,
    required this.cogs,
    required this.paidAmount,
    required this.debtAmount,
    required this.description,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'date_str': dateStr,
        'order_type': orderType,
        'category_root_id': categoryRootId,
        'total_amount': totalAmount,
        'cogs': cogs,
        'paid_amount': paidAmount,
        'debt_amount': debtAmount,
        'description': description,
      };

  factory OrderRecordModel.fromMap(Map<String, dynamic> map) => OrderRecordModel(
        id: map['id'] as int,
        dateStr: map['date_str'] as String,
        orderType: map['order_type'] as String,
        categoryRootId: (map['category_root_id'] as num?)?.toInt() ?? 0,
        totalAmount: (map['total_amount'] as num).toInt(),
        cogs: (map['cogs'] as num?)?.toInt() ?? 0,
        paidAmount: (map['paid_amount'] as num).toInt(),
        debtAmount: (map['debt_amount'] as num).toInt(),
        description: map['description'] as String? ?? '',
      );
}
