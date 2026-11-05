import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/controllers/business_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';

void showManualCashModal(BuildContext context, BusinessController ctrl, String flow) {
  final formKey = GlobalKey<FormState>();
  final isIncome = flow == 'IN';
  final amountCtrl = TextEditingController(text: CurrencyInputFormatter.format(500000));
  final noteCtrl = TextEditingController();
  String method = 'CASH';
  String category = isIncome ? 'OTHER_IN' : 'OPERATING_EXPENSE';
  int? selectedSupId = ctrl.suppliers.isNotEmpty ? ctrl.suppliers.first.id : null;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: isIncome
                    ? (isDark ? Colors.green.shade900 : Colors.green.shade100)
                    : (isDark ? Colors.red.shade900 : Colors.red.shade100),
                child: Icon(
                  isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isIncome
                      ? (isDark ? Colors.green.shade200 : Colors.green.shade800)
                      : (isDark ? Colors.red.shade200 : Colors.red.shade800),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isIncome ? 'Lập Phiếu Thu Quỹ' : 'Lập Phiếu Chi Quỹ',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      isIncome ? 'Ghi nhận dòng tiền VÀO' : 'Ghi nhận dòng tiền RA',
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        content: Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Loại thu chi
                if (!isIncome && ctrl.suppliers.isNotEmpty) ...[
                  SegmentedButton<String>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: 'OPERATING_EXPENSE', label: Text('Chi phí vận hành', style: TextStyle(fontSize: 12))),
                      ButtonSegment(value: 'SUPPLIER_DEBT_PAY', label: Text('Trả nợ NCC', style: TextStyle(fontSize: 12))),
                    ],
                    selected: {category},
                    onSelectionChanged: (v) => setDialogState(() => category = v.first),
                  ),
                  const SizedBox(height: 12),
                  if (category == 'SUPPLIER_DEBT_PAY') ...[
                    DropdownButtonFormField<int>(
                      value: selectedSupId,
                      decoration: const InputDecoration(
                        labelText: 'Chọn Nhà cung cấp cần trả nợ',
                        prefixIcon: Icon(Icons.local_shipping_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                      items: ctrl.suppliers.map((s) {
                        return DropdownMenuItem(
                          value: s.id,
                          child: Text('${s.name} (Nợ: ${AppFormatters.formatVnd(s.payableDebt)})'),
                        );
                      }).toList(),
                      onChanged: (v) => setDialogState(() => selectedSupId = v),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],

                // SỐ TIỀN THU / CHI (FORMAT 500.000 VNĐ)
                TextFormField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    CurrencyInputFormatter(),
                  ],
                  decoration: InputDecoration(
                    labelText: isIncome ? 'Số tiền thu vào *' : 'Số tiền chi ra *',
                    prefixIcon: const Icon(Icons.attach_money),
                    suffixText: 'VNĐ',
                    suffixStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isIncome
                          ? (isDark ? Colors.green.shade300 : Colors.green.shade800)
                          : (isDark ? Colors.red.shade300 : Colors.red.shade800),
                    ),
                    border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  validator: (v) => Validators.positiveCurrency(v, 'Vui lòng nhập số tiền hợp lệ (> 0đ)'),
                  onChanged: (_) => setDialogState(() {}),
                ),
                const SizedBox(height: 8),

                // QUICK AMOUNT CHIPS
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [50000, 100000, 200000, 500000, 1000000, 2000000, 5000000].map((amt) {
                    return ActionChip(
                      visualDensity: VisualDensity.compact,
                      label: Text(AppFormatters.formatCompact(amt)),
                      onPressed: () => setDialogState(() => amountCtrl.text = CurrencyInputFormatter.format(amt)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // NGUỒN TIỀN
                const Text('Nguồn tiền / Hình thức:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: 'CASH',
                      icon: Icon(Icons.payments_outlined, size: 16),
                      label: Text('Tiền mặt', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    ButtonSegment(
                      value: 'BANK',
                      icon: Icon(Icons.account_balance_outlined, size: 16),
                      label: Text('Chuyển khoản', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                  selected: {method},
                  onSelectionChanged: (v) => setDialogState(() => method = v.first),
                ),
                const SizedBox(height: 12),

                // DIỄN GIẢI
                TextFormField(
                  controller: noteCtrl,
                  decoration: InputDecoration(
                    labelText: 'Diễn giải lý do chi tiết *',
                    hintText: isIncome ? 'VD: Bán bao bì ve chai, thu tiền điện...' : 'VD: Mua túi bóng, trả tiền điện tháng 5...',
                    prefixIcon: const Icon(Icons.edit_note_outlined),
                    border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  validator: (v) => Validators.required(v, 'Vui lòng nhập diễn giải lý do'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: isIncome ? Colors.green.shade700 : Colors.red.shade700,
            ),
            icon: const Icon(Icons.check, size: 18),
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              final amt = AppFormatters.parseVnd(amountCtrl.text);
              ctrl.addManualCashTransaction(
                flow: flow,
                category: category,
                amount: amt,
                method: method,
                note: noteCtrl.text.trim(),
                supplierId: category == 'SUPPLIER_DEBT_PAY' ? selectedSupId : null,
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã ghi sổ quỹ: ${isIncome ? '+' : '-'}${AppFormatters.formatVnd(amt)}'),
                  backgroundColor: isIncome ? Colors.green.shade800 : Colors.red.shade800,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            label: Text(isIncome ? 'Ghi Thu Sổ Quỹ' : 'Ghi Chi Sổ Quỹ'),
          ),
        ],
      );
    },
  ),
);
}
