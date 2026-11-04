import 'package:flutter/material.dart';
import '../../../core/controllers/business_controller.dart';
import '../../../core/models/models.dart';

void showHouseholdDialog(
  BuildContext context,
  BusinessController ctrl, {
  HouseholdModel? editHh,
}) {
  final nameCtrl = TextEditingController(text: editHh?.name ?? '');
  final headCtrl = TextEditingController(text: editHh?.headName ?? '');
  final phoneCtrl = TextEditingController(text: editHh?.phone ?? '');
  final addrCtrl = TextEditingController(text: editHh?.address ?? '');
  final limitCtrl = TextEditingController(text: (editHh?.creditLimit ?? 20000000).toString());
  final debtCtrl = TextEditingController(text: (editHh?.currentDebt ?? 0).toString());
  final shellCtrl = TextEditingController(text: (editHh?.containerOwed ?? 0).toString());
  final memCtrl = TextEditingController(
    text: editHh != null && editHh.members.length > 1 ? editHh.members.sublist(1).join(', ') : '',
  );

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(editHh != null ? 'Sửa Hồ Sơ Hộ GĐ' : 'Tự Thêm Hộ Gia Đình'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên Hộ gia đình')),
            TextField(controller: headCtrl, decoration: const InputDecoration(labelText: 'Họ tên Chủ hộ')),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Số điện thoại / Zalo')),
            TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'Địa chỉ')),
            TextField(
              controller: limitCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Hạn mức nợ tối đa (VNĐ)'),
            ),
            TextField(
              controller: debtCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Dư nợ hiện tại (VNĐ)'),
            ),
            TextField(
              controller: shellCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Số vỏ / bao bì đang giữ'),
            ),
            TextField(
              controller: memCtrl,
              decoration: const InputDecoration(labelText: 'Thành viên mua hộ (cách nhau dấu phẩy)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
        FilledButton(
          onPressed: () {
            if (nameCtrl.text.trim().isEmpty) return;
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
              creditLimit: int.tryParse(limitCtrl.text.trim()) ?? 20000000,
              initDebt: int.tryParse(debtCtrl.text.trim()) ?? 0,
              initContainerOwed: int.tryParse(shellCtrl.text.trim()) ?? 0,
              extraMembers: extras,
            );
            Navigator.pop(ctx);
          },
          child: const Text('Lưu Hộ GĐ'),
        ),
      ],
    ),
  );
}
