import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/controllers/business_controller.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';

void showSupplierDialog(
  BuildContext context,
  BusinessController ctrl, {
  SupplierModel? editSupplier,
}) {
  final formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController(text: editSupplier?.name ?? '');
  final phoneCtrl = TextEditingController(text: editSupplier?.phone ?? '');
  final addrCtrl = TextEditingController(text: editSupplier?.address ?? '');
  final debtCtrl = TextEditingController(
    text: editSupplier != null && editSupplier.payableDebt > 0
        ? CurrencyInputFormatter.format(editSupplier.payableDebt)
        : '0',
  );
  final selectedCats = <int>{
    ...(editSupplier?.categoryIds ?? (ctrl.selectedCategoryId != null ? [ctrl.selectedCategoryId!] : <int>[])),
  };

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.indigo.shade100,
              child: const Icon(Icons.local_shipping, color: Colors.indigo),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                editSupplier != null ? 'Sửa Nhà Cung Cấp' : 'Thêm Nhà Cung Cấp',
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
                    labelText: 'Tên Nhà cung cấp *',
                    hintText: 'VD: Đại lý bia Hà Nội, Cty Tân Hiệp Phát...',
                    prefixIcon: Icon(Icons.storefront_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  validator: (v) => Validators.required(v, 'Vui lòng nhập tên nhà cung cấp'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại',
                    hintText: 'VD: 0987654321',
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  validator: Validators.phone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: addrCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Địa chỉ / Ghi chú giao hàng',
                    prefixIcon: Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: debtCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    CurrencyInputFormatter(),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Nợ phải trả NCC ban đầu',
                    prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                    suffixText: 'VNĐ',
                    suffixStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo.shade700),
                    border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    helperText: 'Định dạng tự động (VD: 5.000.000 VNĐ)',
                  ),
                  validator: (v) => Validators.nonNegativeCurrency(v, 'Số nợ không hợp lệ'),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: [0, 1000000, 5000000, 10000000].map((amt) {
                    return ActionChip(
                      label: Text(amt == 0 ? '0đ' : AppFormatters.formatVnd(amt), style: const TextStyle(fontSize: 11)),
                      onPressed: () => setDialogState(() => debtCtrl.text = CurrencyInputFormatter.format(amt)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Thuộc các danh mục cung ứng:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 4),
                if (ctrl.categories.isEmpty)
                  const Text('Chưa có danh mục nào. Bạn có thể tạo danh mục sau.', style: TextStyle(fontSize: 12, color: Colors.grey))
                else
                  Container(
                    constraints: const BoxConstraints(maxHeight: 180),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView(
                      shrinkWrap: true,
                      children: ctrl.categories.map((c) {
                        return CheckboxListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
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
                        );
                      }).toList(),
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
              ctrl.saveSupplier(
                editId: editSupplier?.id,
                name: nameCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
                address: addrCtrl.text.trim(),
                payableDebt: AppFormatters.parseVnd(debtCtrl.text),
                categoryIds: selectedCats.toList(),
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã lưu Nhà cung cấp: ${nameCtrl.text.trim()}'),
                  backgroundColor: Colors.indigo.shade700,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            label: const Text('Lưu NCC'),
          ),
        ],
      ),
    ),
  );
}
