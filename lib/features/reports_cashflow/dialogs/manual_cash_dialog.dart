import 'package:flutter/material.dart';
import '../../../core/controllers/business_controller.dart';

void showManualCashModal(BuildContext context, BusinessController ctrl, String flow) {
  final amountCtrl = TextEditingController(text: '500000');
  final noteCtrl = TextEditingController();
  String method = 'CASH';
  String category = flow == 'IN' ? 'OTHER_IN' : 'OPERATING_EXPENSE';

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        title: Text(flow == 'IN' ? '➕ Lập Phiếu Thu Ngoài' : '➖ Lập Phiếu Chi / Trả NCC'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Số tiền (VNĐ)'),
            ),
            DropdownButtonFormField<String>(
              value: method,
              decoration: const InputDecoration(labelText: 'Nguồn tiền'),
              items: const [
                DropdownMenuItem(value: 'CASH', child: Text('💵 Tiền mặt')),
                DropdownMenuItem(value: 'BANK', child: Text('🏦 Chuyển khoản')),
              ],
              onChanged: (v) => setDialogState(() => method = v ?? 'CASH'),
            ),
            TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Diễn giải chi tiết')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () {
              ctrl.addManualCashTransaction(
                flow: flow,
                category: category,
                amount: int.tryParse(amountCtrl.text.trim()) ?? 0,
                method: method,
                note: noteCtrl.text.trim(),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Ghi Sổ Quỹ'),
          ),
        ],
      ),
    ),
  );
}
