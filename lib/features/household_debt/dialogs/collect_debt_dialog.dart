import 'package:flutter/material.dart';
import '../../../core/controllers/business_controller.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/formatters.dart';

void showCollectDebtDialog(BuildContext context, BusinessController ctrl, HouseholdModel hh) {
  final amountCtrl = TextEditingController(text: hh.currentDebt.toString());
  final shellCtrl = TextEditingController(text: '0');
  final noteCtrl = TextEditingController();
  String method = 'CASH';

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        title: Text('Thu Nợ: ${hh.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Dư nợ hiện tại: ${AppFormatters.formatVnd(hh.currentDebt)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Số tiền khách trả đợt này (VNĐ)'),
            ),
            TextField(
              controller: shellCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Số vỏ / bao bì mang trả'),
            ),
            DropdownButtonFormField<String>(
              value: method,
              decoration: const InputDecoration(labelText: 'Hình thức thanh toán'),
              items: const [
                DropdownMenuItem(value: 'CASH', child: Text('💵 Tiền mặt')),
                DropdownMenuItem(value: 'BANK', child: Text('🏦 Chuyển khoản')),
              ],
              onChanged: (v) => setDialogState(() => method = v ?? 'CASH'),
            ),
            TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Ghi chú')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () {
              ctrl.collectHouseholdDebt(
                householdId: hh.id,
                amount: int.tryParse(amountCtrl.text.trim()) ?? 0,
                containersReturned: int.tryParse(shellCtrl.text.trim()) ?? 0,
                method: method,
                note: noteCtrl.text.trim(),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Xác Nhận Thu Nợ'),
          ),
        ],
      ),
    ),
  );
}
