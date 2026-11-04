import 'package:flutter/material.dart';
import '../../../core/controllers/business_controller.dart';
import '../../../core/models/models.dart';

void showStoreSettingsDialog(BuildContext context, BusinessController ctrl) {
  final nameCtrl = TextEditingController(text: ctrl.storeConfig.storeName);
  final subCtrl = TextEditingController(text: ctrl.storeConfig.storeSubtitle);
  final bankCtrl = TextEditingController(text: ctrl.storeConfig.bankName);
  final accCtrl = TextEditingController(text: ctrl.storeConfig.bankAccount);
  final holderCtrl = TextEditingController(text: ctrl.storeConfig.bankHolder);

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('⚙️ Cài Đặt Cửa Hàng & Ngân Hàng'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên Cửa Hàng / Hộ Kinh Doanh')),
            TextField(controller: subCtrl, decoration: const InputDecoration(labelText: 'Mô tả ngành nghề')),
            TextField(controller: bankCtrl, decoration: const InputDecoration(labelText: 'Tên Ngân hàng (VietQR)')),
            TextField(controller: accCtrl, decoration: const InputDecoration(labelText: 'Số tài khoản')),
            TextField(controller: holderCtrl, decoration: const InputDecoration(labelText: 'Tên Chủ tài khoản')),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
        FilledButton(
          onPressed: () {
            ctrl.updateStoreConfig(StoreConfig(
              storeName: nameCtrl.text.trim().isEmpty ? 'HỘ KINH DOANH CỦA TÔI' : nameCtrl.text.trim(),
              storeSubtitle: subCtrl.text.trim(),
              bankName: bankCtrl.text.trim(),
              bankAccount: accCtrl.text.trim(),
              bankHolder: holderCtrl.text.trim(),
            ));
            Navigator.pop(ctx);
          },
          child: const Text('Lưu Cài Đặt'),
        ),
      ],
    ),
  );
}
