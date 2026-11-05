import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/controllers/business_controller.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';

void showCollectDebtDialog(BuildContext context, BusinessController ctrl, HouseholdModel hh) {
  final formKey = GlobalKey<FormState>();
  final amountCtrl = TextEditingController(
    text: CurrencyInputFormatter.format(hh.currentDebt),
  );
  final shellCtrl = TextEditingController(text: '0');
  final noteCtrl = TextEditingController();
  String method = 'CASH';

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) {
        final payingAmount = AppFormatters.parseVnd(amountCtrl.text);
        final remainingDebt = (hh.currentDebt - payingAmount).clamp(0, 999999999);
        final payingShell = int.tryParse(shellCtrl.text.trim()) ?? 0;
        final remainingShell = (hh.containerOwed - payingShell).clamp(0, 999999);

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.green.shade100,
                child: const Icon(Icons.payments, color: Colors.green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Thu Nợ Khách Hàng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('Hộ: ${hh.name}', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
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
                  // THẺ DƯ NỢ HIỆN TẠI
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Dư nợ sổ hiện tại:', style: TextStyle(fontSize: 12, color: Colors.black54)),
                        const SizedBox(height: 2),
                        Text(
                          AppFormatters.formatVnd(hh.currentDebt),
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.deepOrange.shade800),
                        ),
                        if (hh.containerOwed > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('Đang mượn: ${hh.containerOwed} vỏ / két', style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // SỐ TIỀN THU
                  TextFormField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      CurrencyInputFormatter(),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Số tiền khách trả đợt này *',
                      prefixIcon: const Icon(Icons.monetization_on_outlined),
                      suffixText: 'VNĐ',
                      suffixStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade800),
                      border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                    validator: (v) => Validators.positiveCurrency(v, 'Vui lòng nhập số tiền hợp lệ (> 0đ)'),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 8),

                  // QUICK ACTION CHIPS
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.done_all, size: 14),
                        label: const Text('Trả hết 100%'),
                        onPressed: () => setDialogState(() => amountCtrl.text = CurrencyInputFormatter.format(hh.currentDebt)),
                      ),
                      if (hh.currentDebt > 0)
                        ActionChip(
                          avatar: const Icon(Icons.pie_chart_outline, size: 14),
                          label: const Text('Trả 50%'),
                          onPressed: () => setDialogState(() => amountCtrl.text = CurrencyInputFormatter.format(hh.currentDebt ~/ 2)),
                        ),
                      ...[200000, 500000, 1000000, 2000000].map((amt) {
                        return ActionChip(
                          visualDensity: VisualDensity.compact,
                          label: Text('+${AppFormatters.formatCompact(amt)}'),
                          onPressed: () {
                            final curr = AppFormatters.parseVnd(amountCtrl.text);
                            setDialogState(() => amountCtrl.text = CurrencyInputFormatter.format(curr + amt));
                          },
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // DƯ NỢ CÒN LẠI DỰ KIẾN
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: remainingDebt == 0 ? Colors.green.shade50 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: remainingDebt == 0 ? Colors.green.shade300 : Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Dư nợ còn lại sau khi thu:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            Text(
                              remainingDebt == 0 ? '✨ Hết nợ' : AppFormatters.formatVnd(remainingDebt),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: remainingDebt == 0 ? Colors.green.shade800 : Colors.deepOrange.shade800,
                              ),
                            ),
                          ],
                        ),
                        if (hh.containerOwed > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Vỏ bao bì còn giữ:', style: TextStyle(fontSize: 11, color: Colors.black54)),
                                Text(
                                  remainingShell == 0 ? '✨ Đã trả hết vỏ' : '$remainingShell vỏ',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: remainingShell == 0 ? Colors.green.shade800 : Colors.blue.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // SỐ VỎ TRẢ
                  if (hh.containerOwed > 0) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: shellCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Số vỏ mang trả',
                              prefixIcon: Icon(Icons.repeat_outlined),
                              suffixText: 'vỏ',
                              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                            ),
                            validator: (v) {
                              final num = int.tryParse(v ?? '') ?? 0;
                              if (num < 0) return 'Số vỏ không hợp lệ';
                              if (num > hh.containerOwed) return 'Tối đa ${hh.containerOwed} vỏ';
                              return null;
                            },
                            onChanged: (_) => setDialogState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () => setDialogState(() => shellCtrl.text = hh.containerOwed.toString()),
                          child: const Text('Trả hết vỏ'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // HÌNH THỨC THANH TOÁN
                  DropdownButtonFormField<String>(
                    value: method,
                    decoration: const InputDecoration(
                      labelText: 'Hình thức thanh toán',
                      prefixIcon: Icon(Icons.payment),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'CASH', child: Text('💵 Tiền mặt')),
                      DropdownMenuItem(value: 'BANK', child: Text('🏦 Chuyển khoản (VietQR)')),
                    ],
                    onChanged: (v) => setDialogState(() => method = v ?? 'CASH'),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Ghi chú thu nợ (tùy chọn)',
                      hintText: 'VD: Bác Hoa gửi trả tiền cám...',
                      prefixIcon: Icon(Icons.notes),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            FilledButton.icon(
              icon: const Icon(Icons.check_circle_outline, size: 18),
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                final amt = AppFormatters.parseVnd(amountCtrl.text);
                final shells = int.tryParse(shellCtrl.text.trim()) ?? 0;
                ctrl.collectHouseholdDebt(
                  householdId: hh.id,
                  amount: amt,
                  containersReturned: shells,
                  method: method,
                  note: noteCtrl.text.trim(),
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã thu nợ ${AppFormatters.formatVnd(amt)} từ ${hh.name}!'),
                    backgroundColor: Colors.green.shade700,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              label: const Text('Xác Nhận Thu Nợ'),
            ),
          ],
        );
      },
    ),
  );
}
