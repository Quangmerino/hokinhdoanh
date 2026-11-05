import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/controllers/business_controller.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';

void showHouseholdDialog(
  BuildContext context,
  BusinessController ctrl, {
  HouseholdModel? editHh,
}) {
  final formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController(text: editHh?.name ?? '');
  final headCtrl = TextEditingController(text: editHh?.headName ?? '');
  final phoneCtrl = TextEditingController(text: editHh?.phone ?? '');
  final addrCtrl = TextEditingController(text: editHh?.address ?? '');
  final limitCtrl = TextEditingController(
    text: CurrencyInputFormatter.format(editHh?.creditLimit ?? 20000000),
  );
  final debtCtrl = TextEditingController(
    text: CurrencyInputFormatter.format(editHh?.currentDebt ?? 0),
  );
  final shellCtrl = TextEditingController(text: (editHh?.containerOwed ?? 0).toString());
  final memCtrl = TextEditingController(
    text: editHh != null && editHh.members.length > 1 ? editHh.members.sublist(1).join(', ') : '',
  );

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.amber.shade100,
              child: const Icon(Icons.family_restroom, color: Colors.amber),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                editHh != null ? 'Sửa Sổ Nợ Hộ Gia Đình' : 'Tạo Sổ Nợ Hộ Gia Đình',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
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
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tên Hộ gia đình *',
                    hintText: 'VD: Hộ bà Hoa, Nhà chú Bảy...',
                    prefixIcon: Icon(Icons.home_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  validator: (v) => Validators.required(v, 'Vui lòng nhập tên Hộ gia đình'),
                  onChanged: (v) {
                    if (headCtrl.text.isEmpty) {
                      setDialogState(() => headCtrl.text = v);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: headCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Họ tên Chủ hộ *',
                    hintText: 'VD: Nguyễn Văn A',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  validator: (v) => Validators.required(v, 'Vui lòng nhập tên Chủ hộ'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại / Zalo',
                    hintText: 'VD: 0912345678',
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  validator: Validators.phone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: addrCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Địa chỉ nhà',
                    hintText: 'VD: Xóm 2, thôn Đông...',
                    prefixIcon: Icon(Icons.place_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                ),
                const SizedBox(height: 14),

                // HẠN MỨC NỢ (FORMAT TIỀN 20.000.000 VNĐ)
                TextFormField(
                  controller: limitCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    CurrencyInputFormatter(),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Hạn mức nợ tối đa *',
                    prefixIcon: const Icon(Icons.speed),
                    suffixText: 'VNĐ',
                    suffixStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                    border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  validator: (v) => Validators.positiveCurrency(v, 'Hạn mức phải lớn hơn 0'),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [5000000, 10000000, 20000000, 50000000].map((amt) {
                    return ActionChip(
                      visualDensity: VisualDensity.compact,
                      label: Text(AppFormatters.formatVnd(amt), style: const TextStyle(fontSize: 11)),
                      onPressed: () => setDialogState(() => limitCtrl.text = CurrencyInputFormatter.format(amt)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // DƯ NỢ HIỆN TẠI KHI KHỞI TẠO (FORMAT TIỀN)
                TextFormField(
                  controller: debtCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    CurrencyInputFormatter(),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Dư nợ hiện tại (nếu có)',
                    prefixIcon: const Icon(Icons.receipt_long_outlined),
                    suffixText: 'VNĐ',
                    suffixStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange.shade700),
                    border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  validator: (v) => Validators.nonNegativeCurrency(v, 'Dư nợ không hợp lệ'),
                ),
                const SizedBox(height: 12),

                // SỐ VỎ ĐANG GIỮ
                TextFormField(
                  controller: shellCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Số vỏ bình / két bao bì đang giữ',
                    prefixIcon: Icon(Icons.repeat_on_outlined),
                    suffixText: 'vỏ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  validator: (v) => Validators.nonNegativeNumber(v, 'Số vỏ không hợp lệ'),
                ),
                const SizedBox(height: 12),

                // THÀNH VIÊN
                TextFormField(
                  controller: memCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Thành viên mua hộ (cách nhau bằng dấu phẩy)',
                    hintText: 'VD: Chị Mai (con), Anh Tuấn (chồng)...',
                    prefixIcon: Icon(Icons.group_outlined),
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
            icon: const Icon(Icons.check, size: 18),
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              final extras = memCtrl.text
                  .split(',')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();
              ctrl.saveHousehold(
                editId: editHh?.id,
                name: nameCtrl.text.trim(),
                headName: headCtrl.text.trim().isEmpty ? nameCtrl.text.trim() : headCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
                address: addrCtrl.text.trim(),
                creditLimit: AppFormatters.parseVnd(limitCtrl.text),
                initDebt: AppFormatters.parseVnd(debtCtrl.text),
                initContainerOwed: int.tryParse(shellCtrl.text.trim()) ?? 0,
                extraMembers: extras,
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã lưu hồ sơ Hộ gia đình: ${nameCtrl.text.trim()}'),
                  backgroundColor: Colors.teal.shade700,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            label: const Text('Lưu Hộ GĐ'),
          ),
        ],
      ),
    ),
  );
}
