import 'package:flutter/material.dart';
import '../../core/controllers/business_controller.dart';
import '../../core/utils/formatters.dart';

class PosOrderScreen extends StatefulWidget {
  final BusinessController controller;

  const PosOrderScreen({super.key, required this.controller});

  @override
  State<PosOrderScreen> createState() => _PosOrderScreenState();
}

class _PosOrderScreenState extends State<PosOrderScreen> {
  final TextEditingController _discountCtrl = TextEditingController(text: '0');
  final TextEditingController _paidCtrl = TextEditingController(text: '0');
  final TextEditingController _noteCtrl = TextEditingController();
  int _selectedHouseholdId = 0; // 0 = Walk-in customer
  String? _selectedBuyerMember;
  int? _selectedSupplierId;
  final int _containerOwedDelta = 0;
  String _paymentMethod = 'CASH';

  BusinessController get ctrl => widget.controller;

  int get _discount => int.tryParse(_discountCtrl.text.trim()) ?? 0;
  int get _finalTotal => (ctrl.posSubtotal - _discount).clamp(0, 999999999);
  int get _paidAmount => int.tryParse(_paidCtrl.text.trim()) ?? 0;
  int get _debtAmount => (_finalTotal - _paidAmount).clamp(0, 999999999);

  @override
  Widget build(BuildContext context) {
    final isSale = ctrl.posOrderType == 'SALE';
    final selectedHh = ctrl.households.where((h) => h.id == _selectedHouseholdId).firstOrNull;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Mode Switcher
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'SALE', label: Text('📤 Xuất Bán Hàng')),
                    ButtonSegment(value: 'PURCHASE', label: Text('📥 Nhập Kho Từ NCC')),
                  ],
                  selected: {ctrl.posOrderType},
                  onSelectionChanged: (v) {
                    ctrl.setPosOrderType(v.first);
                    _paidCtrl.text = _finalTotal.toString();
                  },
                ),
                const SizedBox(height: 12),
                const Text('Chọn nhanh mặt hàng:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                if (ctrl.products.isEmpty)
                  const Text('Chưa có mặt hàng nào. Hãy sang tab Danh mục để tạo mặt hàng trước.', style: TextStyle(fontSize: 12, color: Colors.grey))
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ctrl.products.map((p) {
                      return ActionChip(
                        avatar: const Icon(Icons.add_shopping_cart, size: 16),
                        label: Text('${p.name} (${AppFormatters.formatVnd(isSale ? p.retailPrice : p.costPrice)}/${p.baseUnit})'),
                        onPressed: () {
                          ctrl.addProductToCart(p);
                          if (_selectedHouseholdId == 0) {
                            _paidCtrl.text = _finalTotal.toString();
                          }
                        },
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Cart Items Card
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isSale ? '🧾 Giỏ Hàng Bán & Ghi Sổ' : '📥 Danh Sách Hàng Nhập Kho',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    TextButton(
                      onPressed: () => ctrl.clearCart(),
                      child: const Text('Xóa giỏ', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
                const Divider(),
                if (ctrl.posCart.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: Text('Chưa có mặt hàng nào trong phiếu.')),
                  )
                else
                  ...List.generate(ctrl.posCart.length, (idx) {
                    final item = ctrl.posCart[idx];
                    final p = item.product;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () => ctrl.updateCartItem(idx, qty: 0),
                              ),
                            ],
                          ),
                          if (p.hasPackUnit)
                            Row(
                              children: [
                                ChoiceChip(
                                  label: Text(p.baseUnit),
                                  selected: !item.usePackUnit,
                                  onSelected: (_) => ctrl.updateCartItem(idx, usePackUnit: false),
                                ),
                                const SizedBox(width: 8),
                                ChoiceChip(
                                  label: Text(p.packUnitName),
                                  selected: item.usePackUnit,
                                  onSelected: (_) => ctrl.updateCartItem(idx, usePackUnit: true),
                                ),
                              ],
                            ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline),
                                    onPressed: () => ctrl.updateCartItem(idx, qty: item.qty - 1),
                                  ),
                                  Text('${item.qty} ${item.unitLabel}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: () => ctrl.updateCartItem(idx, qty: item.qty + 1),
                                  ),
                                ],
                              ),
                              Text(
                                AppFormatters.formatVnd(item.lineTotal),
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade800),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Household / Supplier & Payment Checkout Card
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isSale) ...[
                  DropdownButtonFormField<int>(
                    value: ctrl.households.any((h) => h.id == _selectedHouseholdId) ? _selectedHouseholdId : 0,
                    decoration: const InputDecoration(labelText: 'Chọn Hộ gia đình mua hàng'),
                    items: [
                      const DropdownMenuItem(value: 0, child: Text('🚶 Khách lẻ vãng lai (Trả đủ 100%)')),
                      ...ctrl.households.map((h) => DropdownMenuItem(
                            value: h.id,
                            child: Text('🏠 ${h.name} (Nợ: ${AppFormatters.formatVnd(h.currentDebt)})'),
                          )),
                    ],
                    onChanged: (v) {
                      setState(() {
                        _selectedHouseholdId = v ?? 0;
                        final hh = ctrl.households.where((h) => h.id == _selectedHouseholdId).firstOrNull;
                        _selectedBuyerMember = hh?.members.firstOrNull;
                        if (_selectedHouseholdId == 0) {
                          _paidCtrl.text = _finalTotal.toString();
                        }
                      });
                    },
                  ),
                  if (selectedHh != null) ...[
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedHh.members.contains(_selectedBuyerMember)
                          ? _selectedBuyerMember
                          : selectedHh.members.firstOrNull,
                      decoration: const InputDecoration(labelText: 'Thành viên trực tiếp lấy hàng'),
                      items: selectedHh.members
                          .map((m) => DropdownMenuItem(value: m, child: Text('👤 $m')))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedBuyerMember = v),
                    ),
                  ],
                ] else ...[
                  if (ctrl.suppliers.isNotEmpty)
                    DropdownButtonFormField<int>(
                      value: _selectedSupplierId ?? ctrl.suppliers.first.id,
                      decoration: const InputDecoration(labelText: 'Chọn Nhà cung cấp nhập hàng'),
                      items: ctrl.suppliers
                          .map((s) => DropdownMenuItem(value: s.id, child: Text('🚚 ${s.name}')))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedSupplierId = v),
                    ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tổng thanh toán:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(
                      AppFormatters.formatVnd(_finalTotal),
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.teal.shade800),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ActionChip(
                      label: const Text('Trả đủ 100%'),
                      onPressed: () => setState(() => _paidCtrl.text = _finalTotal.toString()),
                    ),
                    ActionChip(
                      label: const Text('Trả 50%'),
                      onPressed: () => setState(() => _paidCtrl.text = (_finalTotal ~/ 2).toString()),
                    ),
                    ActionChip(
                      label: const Text('Ghi nợ 100% (0đ)'),
                      onPressed: () => setState(() => _paidCtrl.text = '0'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _paidCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Số tiền trả ngay (VNĐ)'),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _paymentMethod,
                      items: const [
                        DropdownMenuItem(value: 'CASH', child: Text('💵 Tiền mặt')),
                        DropdownMenuItem(value: 'BANK', child: Text('🏦 Chuyển khoản')),
                      ],
                      onChanged: (v) => setState(() => _paymentMethod = v ?? 'CASH'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Số tiền ghi vào Sổ nợ:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                    Text(
                      AppFormatters.formatVnd(_debtAmount),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.deepOrange),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteCtrl,
                  decoration: const InputDecoration(labelText: 'Ghi chú đơn hàng'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      if (ctrl.posCart.isEmpty) return;
                      if (isSale && _selectedHouseholdId == 0 && _debtAmount > 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Khách lẻ không có sổ nợ! Hãy chọn Hộ gia đình hoặc trả đủ 100%.')),
                        );
                        return;
                      }
                      ctrl.submitPosOrder(
                        discount: _discount,
                        paidAmount: _paidAmount,
                        paymentMethod: _paymentMethod,
                        dateStr: AppFormatters.todayIsoDate(),
                        householdId: _selectedHouseholdId > 0 ? _selectedHouseholdId : null,
                        buyerMemberName: _selectedBuyerMember,
                        supplierId: _selectedSupplierId ?? ctrl.suppliers.firstOrNull?.id,
                        containerOwedDelta: _containerOwedDelta,
                        note: _noteCtrl.text.trim(),
                      );
                      _noteCtrl.clear();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã hoàn tất đơn hàng & cập nhật sổ!')),
                      );
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('HOÀN TẤT & LƯU SỔ NGAY'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
