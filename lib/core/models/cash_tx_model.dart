class CashTxModel {
  final int id;
  final String dateStr;
  final String flow; // 'IN' or 'OUT'
  final String category; // 'SALE_CASH', 'DEBT_COLLECTION', 'PURCHASE_PAY', 'SUPPLIER_DEBT_PAY', 'OPERATING_EXPENSE', 'OTHER_IN'
  final String method; // 'CASH' or 'BANK'
  final int amount;
  final String note;

  const CashTxModel({
    required this.id,
    required this.dateStr,
    required this.flow,
    required this.category,
    required this.method,
    required this.amount,
    required this.note,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'date_str': dateStr,
        'flow': flow,
        'category': category,
        'method': method,
        'amount': amount,
        'note': note,
      };

  factory CashTxModel.fromMap(Map<String, dynamic> map) => CashTxModel(
        id: map['id'] as int,
        dateStr: map['date_str'] as String,
        flow: map['flow'] as String,
        category: map['category'] as String,
        method: map['method'] as String? ?? 'CASH',
        amount: (map['amount'] as num).toInt(),
        note: map['note'] as String? ?? '',
      );
}
