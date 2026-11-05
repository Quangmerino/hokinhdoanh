import 'package:flutter/material.dart';
import '../utils/formatters.dart';

class QuickAmountChips extends StatelessWidget {
  final List<int> amounts;
  final ValueChanged<int> onSelectAmount;
  final ValueChanged<int>? onAddAmount;
  final bool isAdditive;

  const QuickAmountChips({
    super.key,
    required this.amounts,
    required this.onSelectAmount,
    this.onAddAmount,
    this.isAdditive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: amounts.map((amount) {
        final label = isAdditive
            ? '+${AppFormatters.formatCompact(amount)}'
            : AppFormatters.formatCompact(amount);
        return ActionChip(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
          visualDensity: VisualDensity.compact,
          label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          onPressed: () {
            if (isAdditive && onAddAmount != null) {
              onAddAmount!(amount);
            } else {
              onSelectAmount(amount);
            }
          },
        );
      }).toList(),
    );
  }
}
