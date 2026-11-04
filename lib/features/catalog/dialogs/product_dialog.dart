import 'package:flutter/material.dart';
import '../../../core/controllers/business_controller.dart';
import '../../../core/models/models.dart';

void showProductDialog(
  BuildContext context,
  BusinessController ctrl, {
  ProductModel? editProduct,
}) {
  final nameCtrl = TextEditingController(text: editProduct?.name ?? '');
  final skuCtrl = TextEditingController(text: editProduct?.sku ?? '');
  final unitCtrl = TextEditingController(text: editProduct?.baseUnit ?? 'Cái');
  final stockCtrl = TextEditingController(text: (editProduct?.stockQty ?? 0).toString());
  final costCtrl = TextEditingController(text: (editProduct?.costPrice ?? 0).toString());
  final retailCtrl = TextEditingController(text: (editProduct?.retailPrice ?? 0).toString());
  final packNameCtrl = TextEditingController(text: editProduct?.packUnitName ?? '');
  final packRateCtrl = TextEditingController(
    text: (editProduct != null && editProduct.packRate > 1) ? editProduct.packRate.toString() : '',
  );
  final packPriceCtrl = TextEditingController(
    text: (editProduct != null && editProduct.hasPackUnit) ? editProduct.packPrice.toString() : '',
  );
  final noteCtrl = TextEditingController(text: editProduct?.specNote ?? '');
  bool trackShell = editProduct?.trackReturnableShell ?? false;
  int selectedCatId = editProduct?.categoryId ??
      ctrl.selectedCategoryId ??
      (ctrl.categories.isNotEmpty ? ctrl.categories.first.id : 0);
  int selectedSupId = editProduct?.primarySupplierId ??
      ctrl.selectedSupplierId ??
      (ctrl.suppliers.isNotEmpty ? ctrl.suppliers.first.id : 0);

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        title: Text(editProduct != null ? 'Sửa Mặt Hàng' : 'Tự Thêm Mặt Hàng Mới'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên mặt hàng')),
              TextField(controller: skuCtrl, decoration: const InputDecoration(labelText: 'Mã SP / SKU')),
              if (ctrl.categories.isNotEmpty)
                DropdownButtonFormField<int>(
                  value: ctrl.categories.any((c) => c.id == selectedCatId)
                      ? selectedCatId
                      : ctrl.categories.first.id,
                  decoration: const InputDecoration(labelText: 'Thuộc Danh mục'),
                  items: ctrl.categories
                      .map((c) => DropdownMenuItem(value: c.id, child: Text(ctrl.getCategoryDepthLabel(c))))
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedCatId = v ?? 0),
                ),
              if (ctrl.suppliers.isNotEmpty)
                DropdownButtonFormField<int>(
                  value: ctrl.suppliers.any((s) => s.id == selectedSupId)
                      ? selectedSupId
                      : ctrl.suppliers.first.id,
                  decoration: const InputDecoration(labelText: 'Nhà cung cấp chính'),
                  items: ctrl.suppliers
                      .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedSupId = v ?? 0),
                ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: unitCtrl,
                      decoration: const InputDecoration(labelText: 'Đơn vị gốc (Cái, Kg...)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: stockCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Số lượng tồn'),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: costCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Giá nhập (VNĐ)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: retailCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Giá bán lẻ (VNĐ)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: packNameCtrl,
                decoration: const InputDecoration(labelText: 'Đơn vị chẵn tùy chọn (VD: Bao, Thùng)'),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: packRateCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Hệ số quy đổi (VD: 25)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: packPriceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Giá bán chẵn'),
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Quản lý vỏ bình / bao bì hoàn trả', style: TextStyle(fontSize: 13)),
                value: trackShell,
                onChanged: (v) => setDialogState(() => trackShell = v),
              ),
              TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Ghi chú thêm')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              ctrl.saveProduct(
                editId: editProduct?.id,
                name: nameCtrl.text.trim(),
                sku: skuCtrl.text.trim(),
                categoryId: selectedCatId,
                primarySupplierId: selectedSupId,
                supplierIds: selectedSupId > 0 ? [selectedSupId] : [],
                baseUnit: unitCtrl.text.trim().isEmpty ? 'Cái' : unitCtrl.text.trim(),
                stockQty: double.tryParse(stockCtrl.text.trim()) ?? 0,
                costPrice: int.tryParse(costCtrl.text.trim()) ?? 0,
                retailPrice: int.tryParse(retailCtrl.text.trim()) ?? 0,
                packUnitName: packNameCtrl.text.trim(),
                packRate: double.tryParse(packRateCtrl.text.trim()) ?? 1,
                packPrice: int.tryParse(packPriceCtrl.text.trim()) ?? 0,
                trackReturnableShell: trackShell,
                specNote: noteCtrl.text.trim(),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Lưu Mặt Hàng'),
          ),
        ],
      ),
    ),
  );
}
