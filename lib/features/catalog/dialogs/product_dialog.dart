import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/controllers/business_controller.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';

void showProductDialog(
  BuildContext context,
  BusinessController ctrl, {
  ProductModel? editProduct,
}) {
  final formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController(text: editProduct?.name ?? '');
  final skuCtrl = TextEditingController(text: editProduct?.sku ?? '');
  final unitCtrl = TextEditingController(text: editProduct?.baseUnit ?? 'Cái');
  final stockCtrl = TextEditingController(text: (editProduct?.stockQty ?? 0).toString());
  final costCtrl = TextEditingController(
    text: editProduct != null && editProduct.costPrice > 0
        ? CurrencyInputFormatter.format(editProduct.costPrice)
        : '0',
  );
  final retailCtrl = TextEditingController(
    text: editProduct != null && editProduct.retailPrice > 0
        ? CurrencyInputFormatter.format(editProduct.retailPrice)
        : '0',
  );
  bool enablePackUnit = editProduct != null && editProduct.packUnitName.trim().isNotEmpty;
  String conversionMode = 'PACK_IS_LARGER';
  String initialRatioText = '';
  if (editProduct != null && editProduct.packRate > 0 && editProduct.packUnitName.trim().isNotEmpty) {
    if (editProduct.packRate < 1.0) {
      conversionMode = 'BASE_IS_LARGER';
      final r = (1.0 / editProduct.packRate);
      initialRatioText = r % 1 == 0 ? r.toInt().toString() : r.toStringAsFixed(2);
    } else {
      conversionMode = 'PACK_IS_LARGER';
      final r = editProduct.packRate;
      initialRatioText = r % 1 == 0 ? r.toInt().toString() : r.toString();
    }
  }

  final packNameCtrl = TextEditingController(text: editProduct?.packUnitName ?? '');
  final packRatioCtrl = TextEditingController(text: initialRatioText);
  final packPriceCtrl = TextEditingController(
    text: (editProduct != null && editProduct.packPrice > 0)
        ? CurrencyInputFormatter.format(editProduct.packPrice)
        : '',
  );
  final noteCtrl = TextEditingController(text: editProduct?.specNote ?? '');
  bool trackShell = editProduct?.trackReturnableShell ?? false;
  int selectedCatId = editProduct?.categoryId ??
      ctrl.selectedCategoryId ??
      (ctrl.categories.isNotEmpty ? ctrl.categories.first.id : 0);
  int selectedSupId = editProduct?.primarySupplierId ??
      ctrl.selectedSupplierId ??
      (ctrl.suppliers.isNotEmpty ? ctrl.suppliers.first.id : 0);

  const commonUnits = ['Cái', 'Kg', 'Lon', 'Chai', 'Hộp', 'Gói', 'Bao', 'Thùng', 'Két', 'Bình'];

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) {
        final currentCost = AppFormatters.parseVnd(costCtrl.text);
        final currentRetail = AppFormatters.parseVnd(retailCtrl.text);
        final profit = currentRetail - currentCost;
        final profitMargin = currentRetail > 0 ? (profit / currentRetail * 100).toStringAsFixed(1) : '0';

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.teal.shade100,
                child: const Icon(Icons.inventory_2, color: Colors.teal),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  editProduct != null ? 'Sửa Mặt Hàng' : 'Thêm Mặt Hàng Mới',
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
                  // Tên SP
                  TextFormField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Tên mặt hàng *',
                      hintText: 'VD: Nước ngọt Coca Cola 330ml, Gạo ST25...',
                      prefixIcon: const Icon(Icons.shopping_bag_outlined),
                      border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      suffixIcon: nameCtrl.text.isNotEmpty
                          ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => setDialogState(() => nameCtrl.clear()))
                          : null,
                    ),
                    validator: (v) => Validators.required(v, 'Vui lòng nhập tên mặt hàng'),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 12),

                  // SKU & Tự sinh mã
                  TextFormField(
                    controller: skuCtrl,
                    decoration: InputDecoration(
                      labelText: 'Mã SKU / Barcode',
                      hintText: 'VD: SP-01, 893...',
                      prefixIcon: const Icon(Icons.qr_code),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () {
                            final auto = 'SP${DateTime.now().millisecondsSinceEpoch % 100000}';
                            setDialogState(() => skuCtrl.text = auto);
                          },
                          icon: const Icon(Icons.auto_awesome, size: 16),
                          label: const Text('Tạo mã', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Danh mục & Nhà cung cấp
                  if (ctrl.categories.isNotEmpty)
                    DropdownButtonFormField<int>(
                      initialValue: ctrl.categories.any((c) => c.id == selectedCatId)
                          ? selectedCatId
                          : ctrl.categories.first.id,
                      decoration: const InputDecoration(
                        labelText: 'Thuộc Danh mục *',
                        prefixIcon: Icon(Icons.category_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                      items: ctrl.categories
                          .map((c) => DropdownMenuItem(value: c.id, child: Text(ctrl.getCategoryDepthLabel(c))))
                          .toList(),
                      onChanged: (v) => setDialogState(() => selectedCatId = v ?? 0),
                    ),
                  const SizedBox(height: 12),

                  if (ctrl.suppliers.isNotEmpty)
                    DropdownButtonFormField<int>(
                      initialValue: ctrl.suppliers.any((s) => s.id == selectedSupId)
                          ? selectedSupId
                          : ctrl.suppliers.first.id,
                      decoration: const InputDecoration(
                        labelText: 'Nhà cung cấp chính',
                        prefixIcon: Icon(Icons.local_shipping_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                      items: ctrl.suppliers
                          .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                          .toList(),
                      onChanged: (v) => setDialogState(() => selectedSupId = v ?? 0),
                    ),
                  const SizedBox(height: 12),

                  // Đơn vị gốc & Tồn kho
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: unitCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Đơn vị gốc *',
                            hintText: 'Cái, Kg...',
                            prefixIcon: Icon(Icons.straighten),
                            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                          ),
                          validator: (v) => Validators.required(v, 'Nhập đơn vị'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: stockCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Số lượng tồn *',
                            prefixIcon: Icon(Icons.warehouse_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                          ),
                          validator: (v) => Validators.nonNegativeNumber(v, 'Tồn kho không âm'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    children: commonUnits.map((u) {
                      return ChoiceChip(
                        visualDensity: VisualDensity.compact,
                        label: Text(u, style: const TextStyle(fontSize: 11)),
                        selected: unitCtrl.text == u,
                        onSelected: (_) => setDialogState(() => unitCtrl.text = u),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // GIÁ NHẬP & GIÁ BÁN (FORMAT TIỀN VNĐ 2.000.000)
                  const Text('💰 Giá Vốn & Giá Bán Lẻ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: costCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            CurrencyInputFormatter(),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Giá nhập vốn',
                            suffixText: 'VNĐ',
                            suffixStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700, fontSize: 12),
                            border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                          ),
                          validator: (v) => Validators.nonNegativeCurrency(v, 'Giá không hợp lệ'),
                          onChanged: (_) => setDialogState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: retailCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            CurrencyInputFormatter(),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Giá bán lẻ *',
                            suffixText: 'VNĐ',
                            suffixStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade800, fontSize: 12),
                            border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                          ),
                          validator: (v) => Validators.positiveCurrency(v, 'Cần nhập giá bán'),
                          onChanged: (_) => setDialogState(() {}),
                        ),
                      ),
                    ],
                  ),

                  // LIVE PROFIT MARGIN BADGE (UX thông minh)
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: profit >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: profit >= 0 ? Colors.green.shade300 : Colors.red.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          profit >= 0 ? Icons.trending_up : Icons.warning_amber,
                          size: 16,
                          color: profit >= 0 ? Colors.green.shade800 : Colors.red.shade800,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            profit >= 0
                                ? 'Lãi gộp: +${AppFormatters.formatVnd(profit)} / ${unitCtrl.text} ($profitMargin%)'
                                : 'Cảnh báo: Bán dưới giá nhập (${AppFormatters.formatVnd(profit)})',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: profit >= 0 ? Colors.green.shade800 : Colors.red.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ĐƠN VỊ QUY ĐỔI SỈ / PHỤ (Thùng / Lốc / Két / Bao)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: enablePackUnit ? const Color(0xFFF0FDFA) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: enablePackUnit ? const Color(0xFF0F766E).withOpacity(0.4) : Colors.grey.shade300,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: const Row(
                            children: [
                              Text('📦 Bán Sỉ / Đơn Vị Quy Đổi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              SizedBox(width: 6),
                              Text('(Tùy chọn)', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                          subtitle: const Text(
                            'Bật nếu mặt hàng có bán sỉ theo Thùng/Két hoặc chia lẻ theo Lốc/Hộp',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          value: enablePackUnit,
                          onChanged: (v) {
                            setDialogState(() {
                              enablePackUnit = v;
                              if (!v) {
                                packNameCtrl.clear();
                                packRatioCtrl.clear();
                                packPriceCtrl.clear();
                              }
                            });
                          },
                        ),
                        if (enablePackUnit) ...[
                          const Divider(height: 16),
                          // 1. Tên đơn vị phụ
                          TextFormField(
                            controller: packNameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Tên đơn vị phụ / sỉ *',
                              hintText: 'VD: Lốc, Thùng, Két, Hộp, Bao...',
                              prefixIcon: Icon(Icons.all_inbox, size: 20),
                              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                              isDense: true,
                            ),
                            validator: (v) {
                              if (enablePackUnit && (v == null || v.trim().isEmpty)) {
                                return 'Vui lòng nhập tên đơn vị phụ (hoặc tắt công tắc ở trên)';
                              }
                              return null;
                            },
                            onChanged: (_) => setDialogState(() {}),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 4,
                            children: ['Lốc', 'Thùng', 'Két', 'Hộp', 'Bao', 'Vỉ'].map((u) {
                              return ChoiceChip(
                                visualDensity: VisualDensity.compact,
                                label: Text(u, style: const TextStyle(fontSize: 11)),
                                selected: packNameCtrl.text == u,
                                onSelected: (_) => setDialogState(() => packNameCtrl.text = u),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 10),

                          // 2. Chiều quy đổi linh hoạt
                          const Text('Chiều quy đổi tương quan:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          SegmentedButton<String>(
                            showSelectedIcon: false,
                            style: const ButtonStyle(
                              visualDensity: VisualDensity.compact,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            segments: [
                              ButtonSegment(
                                value: 'BASE_IS_LARGER',
                                label: Text(
                                  '1 ${unitCtrl.text.isEmpty ? "Gốc" : unitCtrl.text} = Nhiều ${packNameCtrl.text.isEmpty ? "Phụ" : packNameCtrl.text}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                icon: const Icon(Icons.call_split, size: 14),
                              ),
                              ButtonSegment(
                                value: 'PACK_IS_LARGER',
                                label: Text(
                                  '1 ${packNameCtrl.text.isEmpty ? "Phụ" : packNameCtrl.text} = Nhiều ${unitCtrl.text.isEmpty ? "Gốc" : unitCtrl.text}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                icon: const Icon(Icons.call_merge, size: 14),
                              ),
                            ],
                            selected: {conversionMode},
                            onSelectionChanged: (val) => setDialogState(() => conversionMode = val.first),
                          ),
                          const SizedBox(height: 10),

                          // 3. Số lượng quy đổi & Giá bán
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: packRatioCtrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    labelText: conversionMode == 'BASE_IS_LARGER'
                                        ? '1 ${unitCtrl.text.isEmpty ? "Gốc" : unitCtrl.text} = ? ${packNameCtrl.text.isEmpty ? "Phụ" : packNameCtrl.text} *'
                                        : '1 ${packNameCtrl.text.isEmpty ? "Phụ" : packNameCtrl.text} = ? ${unitCtrl.text.isEmpty ? "Gốc" : unitCtrl.text} *',
                                    hintText: conversionMode == 'BASE_IS_LARGER' ? 'VD: 4' : 'VD: 24',
                                    border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                                    isDense: true,
                                  ),
                                  validator: (v) {
                                    if (enablePackUnit) {
                                      final r = double.tryParse((v ?? '').trim().replaceAll(',', '.'));
                                      if (r == null || r <= 0) return 'Cần số > 0';
                                    }
                                    return null;
                                  },
                                  onChanged: (_) => setDialogState(() {}),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: packPriceCtrl,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    CurrencyInputFormatter(),
                                  ],
                                  decoration: InputDecoration(
                                    labelText: 'Giá bán ${packNameCtrl.text.isEmpty ? "ĐV phụ" : packNameCtrl.text} *',
                                    suffixText: 'VNĐ',
                                    border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                                    isDense: true,
                                  ),
                                  validator: (v) {
                                    if (enablePackUnit) {
                                      return Validators.positiveCurrency(v, 'Cần nhập giá bán');
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),

                          // 4. Giải thích trực quan
                          if (packRatioCtrl.text.isNotEmpty && double.tryParse(packRatioCtrl.text.trim().replaceAll(',', '.')) != null) ...[
                            const SizedBox(height: 8),
                            Builder(builder: (ctx) {
                              final ratio = double.tryParse(packRatioCtrl.text.trim().replaceAll(',', '.')) ?? 1.0;
                              final bUnit = unitCtrl.text.isEmpty ? 'ĐV gốc' : unitCtrl.text;
                              final pUnit = packNameCtrl.text.isEmpty ? 'ĐV phụ' : packNameCtrl.text;
                              String formulaExplanation;
                              if (conversionMode == 'BASE_IS_LARGER') {
                                final deduction = ratio > 0 ? (1.0 / ratio) : 1.0;
                                final cleanDeduction = deduction.toStringAsFixed(deduction.truncateToDouble() == deduction ? 0 : 3);
                                formulaExplanation = '💡 1 $bUnit = ${ratio % 1 == 0 ? ratio.toInt() : ratio} $pUnit. Bán 1 $pUnit sẽ trừ $cleanDeduction $bUnit trong kho.';
                              } else {
                                formulaExplanation = '💡 1 $pUnit = ${ratio % 1 == 0 ? ratio.toInt() : ratio} $bUnit. Bán 1 $pUnit sẽ trừ ${ratio % 1 == 0 ? ratio.toInt() : ratio} $bUnit trong kho.';
                              }
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue.shade200),
                                ),
                                child: Text(
                                  formulaExplanation,
                                  style: TextStyle(fontSize: 11, color: Colors.blue.shade900, fontWeight: FontWeight.w500),
                                ),
                              );
                            }),
                          ],
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Quản lý vỏ hoàn trả
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Quản lý vỏ bình / két bao bì hoàn trả', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Theo dõi nợ vỏ két bia, bình nước ngọt với khách hàng', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    value: trackShell,
                    onChanged: (v) => setDialogState(() => trackShell = v),
                  ),
                  const SizedBox(height: 6),

                  TextFormField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Ghi chú / Quy cách chi tiết',
                      hintText: 'VD: 24 lon x 330ml, HSD 12 tháng...',
                      prefixIcon: Icon(Icons.notes_outlined),
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

                double calculatedPackRate = 1.0;
                String resolvedPackName = '';
                int resolvedPackPrice = 0;

                if (enablePackUnit && packNameCtrl.text.trim().isNotEmpty) {
                  resolvedPackName = packNameCtrl.text.trim();
                  resolvedPackPrice = AppFormatters.parseVnd(packPriceCtrl.text);
                  final inputRatio = double.tryParse(packRatioCtrl.text.trim().replaceAll(',', '.')) ?? 1.0;
                  if (conversionMode == 'BASE_IS_LARGER') {
                    // 1 [Đơn vị gốc] = [inputRatio] [Đơn vị phụ] (VD: 1 Thùng = 4 Lốc -> Bán 1 Lốc trừ 0.25 Thùng)
                    calculatedPackRate = inputRatio > 0 ? (1.0 / inputRatio) : 1.0;
                  } else {
                    // 1 [Đơn vị phụ] = [inputRatio] [Đơn vị gốc] (VD: 1 Thùng = 24 Lon -> Bán 1 Thùng trừ 24 Lon)
                    calculatedPackRate = inputRatio > 0 ? inputRatio : 1.0;
                  }
                }

                ctrl.saveProduct(
                  editId: editProduct?.id,
                  name: nameCtrl.text.trim(),
                  sku: skuCtrl.text.trim(),
                  categoryId: selectedCatId,
                  primarySupplierId: selectedSupId,
                  supplierIds: selectedSupId > 0 ? [selectedSupId] : [],
                  baseUnit: unitCtrl.text.trim().isEmpty ? 'Cái' : unitCtrl.text.trim(),
                  stockQty: double.tryParse(stockCtrl.text.trim().replaceAll(',', '.')) ?? 0,
                  costPrice: AppFormatters.parseVnd(costCtrl.text),
                  retailPrice: AppFormatters.parseVnd(retailCtrl.text),
                  packUnitName: resolvedPackName,
                  packRate: calculatedPackRate,
                  packPrice: resolvedPackPrice,
                  trackReturnableShell: trackShell,
                  specNote: noteCtrl.text.trim(),
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã lưu mặt hàng: ${nameCtrl.text.trim()}'),
                    backgroundColor: Colors.teal.shade700,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              label: const Text('Lưu Mặt Hàng'),
            ),
          ],
        );
      },
    ),
  );
}
