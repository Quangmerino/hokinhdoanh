class DebtLedgerEntry {
  final int id;
  final int householdId;
  final String dateStr;
  final String actorName;
  final String description;
  final int changeAmount;
  final int balanceAfter;

  const DebtLedgerEntry({
    required this.id,
    required this.householdId,
    required this.dateStr,
    required this.actorName,
    required this.description,
    required this.changeAmount,
    required this.balanceAfter,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'household_id': householdId,
        'date_str': dateStr,
        'actor_name': actorName,
        'description': description,
        'change_amount': changeAmount,
        'balance_after': balanceAfter,
      };

  factory DebtLedgerEntry.fromMap(Map<String, dynamic> map) => DebtLedgerEntry(
        id: map['id'] as int,
        householdId: (map['household_id'] as num).toInt(),
        dateStr: map['date_str'] as String,
        actorName: map['actor_name'] as String? ?? '',
        description: map['description'] as String? ?? '',
        changeAmount: (map['change_amount'] as num).toInt(),
        balanceAfter: (map['balance_after'] as num).toInt(),
      );
}
