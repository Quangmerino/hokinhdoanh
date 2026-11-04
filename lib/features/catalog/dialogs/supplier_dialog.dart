import 'package:flutter/material.dart';
import '../../../core/controllers/business_controller.dart';
import '../../../core/models/models.dart';

void showSupplierDialog(
  BuildContext context,
  BusinessController ctrl, {
  SupplierModel? editSupplier,
}) {
  final nameCtrl = TextEditingController(text: editSupplier?.name ?? '');
  final phoneCtrl = TextEditingController(text: editSupplier?.phone ?? '');
  final addrCtrl = TextEditingController(text: editSupplier?.address ?? '');
  final debtCtrl = TextEditingController(text: (editSupplier?.payableDebt ?? 0).toString());
  final selectedCats = <int>{
    ...(editSupplier?.categoryIds ?? (ctrl.selectedCategoryId != null ? [ctrl.selectedCategoryId!] : <int>[])),
  };

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        title: Text(editSupplier != null ? 'Sửa Nhà Cung Cấp' : 'Tự Thêm Nhà Cung Cấp'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên Nhà cung cấp')),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Số điện thoại')),
              TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'Địa chỉ / Ghi chú')),
              TextField(
                controller: debtCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Nợ phải trả NCC (VNĐ)'),
              ),
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Thuộc các danh mục:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              ...ctrl.categories.map((c) => CheckboxListTile(
                    dense: true,
                    value: selectedCats.contains(c.id),
                    title: Text(ctrl.getCategoryDepthLabel(c), style: const TextStyle(fontSize: 12)),
                    onChanged: (val) {
                      setDialogState(() {
                        if (val == true) {
                          selectedCats.add(c.id);
                        } else {
                          selectedCats.remove(c.id);
                        }
                      });
                    },
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              ctrl.saveSupplier(
                editId: editSupplier?.id,
                name: nameCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
                address: addrCtrl.text.trim(),
                payableDebt: int.tryParse(debtCtrl.text.trim()) ?? 0,
                categoryIds: selectedCats.toList(),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Lưu NCC'),
          ),
        ],
      ),
    ),
  );
}
