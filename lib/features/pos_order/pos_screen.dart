import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  int _containerOwedDelta = 0;
  String _paymentMethod = 'CASH';

  BusinessController get ctrl => widget.controller;

  int get _discount => AppFormatters.parseVnd(_discountCtrl.text);
  int get _finalTotal => (ctrl.posSubtotal - _discount).clamp(0, 999999999);
  int get _paidAmount => AppFormatters.parseVnd(_paidCtrl.text);
  int get _debtAmount => (_finalTotal - _paidAmount).clamp(0, 999999999);

  void _syncPaidAmountToTotal() {
    _paidCtrl.text = CurrencyInputFormatter.format(_finalTotal);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSale = ctrl.posOrderType == 'SALE';
    final selectedHh = ctrl.households.where((h) => h.id == _selectedHouseholdId).firstOrNull;
    final hasShellItems = ctrl.posCart.any((i) => i.product.trackReturnableShell);

    // Tính toán kiểm tra hạn mức nợ
    final willExceedCreditLimit = selectedHh != null &&
        (selectedHh.currentDebt + _debtAmount) > selectedHh.creditLimit;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Mode Switcher
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade300),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'SALE', label: Text('📤 Xuất Bán Hàng', style: TextStyle(fontWeight: FontWeight.bold))),
                    ButtonSegment(value: 'PURCHASE', label: Text('📥 Nhập Kho Từ NCC', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  selected: {ctrl.posOrderType},
                  onSelectionChanged: (v) {
                    ctrl.setPosOrderType(v.first);
                    _syncPaidAmountToTotal();
                  },
                ),
                const SizedBox(height: 12),
                const Text('Chọn nhanh mặt hàng vào phiếu:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                            _syncPaidAmountToTotal();
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
            side: BorderSide(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade300),
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
                    if (ctrl.posCart.isNotEmpty)
                      TextButton.icon(
                        icon: const Icon(Icons.delete_sweep_outlined, size: 18, color: Colors.red),
                        onPressed: () {
                          ctrl.clearCart();
                          _discountCtrl.text = '0';
                          _paidCtrl.text = '0';
                        },
                        label: const Text('Xóa giỏ', style: TextStyle(color: Colors.red)),
                      ),
                  ],
                ),
                const Divider(),
                if (ctrl.posCart.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.shopping_basket_outlined, size: 40, color: Colors.grey),
                          SizedBox(height: 6),
                          Text('Chưa có mặt hàng nào trong phiếu.', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  )
                else
                  ...List.generate(ctrl.posCart.length, (idx) {
                    final item = ctrl.posCart[idx];
                    final p = item.product;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18, color: Colors.red),
                                onPressed: () {
                                  ctrl.updateCartItem(idx, qty: 0);
                                  _syncPaidAmountToTotal();
                                },
                              ),
                            ],
                          ),
                          if (p.hasPackUnit)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  ChoiceChip(
                                    label: Text(p.baseUnit),
                                    selected: !item.usePackUnit,
                                    onSelected: (_) {
                                      ctrl.updateCartItem(idx, usePackUnit: false);
                                      _syncPaidAmountToTotal();
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  ChoiceChip(
                                    label: Text('${p.packUnitName} (x${p.packRate} ${p.baseUnit})'),
                                    selected: item.usePackUnit,
                                    onSelected: (_) {
                                      ctrl.updateCartItem(idx, usePackUnit: true);
                                      _syncPaidAmountToTotal();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline),
                                    onPressed: () {
                                      ctrl.updateCartItem(idx, qty: item.qty - 1);
                                      _syncPaidAmountToTotal();
                                    },
                                  ),
                                  Text('${item.qty} ${item.unitLabel}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: () {
                                      ctrl.updateCartItem(idx, qty: item.qty + 1);
                                      _syncPaidAmountToTotal();
                                    },
                                  ),
                                ],
                              ),
                              Text(
                                AppFormatters.formatVnd(item.lineTotal),
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                  color: isDark ? Colors.teal.shade300 : Colors.teal.shade800,
                                ),
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
            side: BorderSide(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade300),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isSale) ...[
                  DropdownButtonFormField<int>(
                    value: ctrl.households.any((h) => h.id == _selectedHouseholdId) ? _selectedHouseholdId : 0,
                    decoration: const InputDecoration(
                      labelText: 'Chọn Hộ gia đình mua hàng *',
                      prefixIcon: Icon(Icons.family_restroom),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
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
                          _syncPaidAmountToTotal();
                        }
                      });
                    },
                  ),
                  if (selectedHh != null) ...[
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedHh.members.contains(_selectedBuyerMember)
                          ? _selectedBuyerMember
                          : selectedHh.members.firstOrNull,
                      decoration: const InputDecoration(
                        labelText: 'Thành viên trực tiếp lấy hàng',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
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
                      decoration: const InputDecoration(
                        labelText: 'Chọn Nhà cung cấp nhập hàng',
                        prefixIcon: Icon(Icons.local_shipping_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                      items: ctrl.suppliers
                          .map((s) => DropdownMenuItem(value: s.id, child: Text('🚚 ${s.name} (Nợ: ${AppFormatters.formatVnd(s.payableDebt)})')))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedSupplierId = v),
                    ),
                ],
                const SizedBox(height: 14),

                // QUẢN LÝ VỎ BÌNH GIAO THÊM NẾU CÓ MẶT HÀNG TRẢ VỎ
                if (hasShellItems) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.blue.shade900.withValues(alpha: 0.3) : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? Colors.blue.shade700 : Colors.blue.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.repeat, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Giao thêm vỏ két/bình:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.blue),
                              onPressed: () {
                                if (_containerOwedDelta > 0) {
                                  setState(() => _containerOwedDelta--);
                                }
                              },
                            ),
                            Text('$_containerOwedDelta vỏ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                              onPressed: () => setState(() => _containerOwedDelta++),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // GIẢM GIÁ (FORMAT TIỀN VNĐ)
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _discountCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          CurrencyInputFormatter(),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Chiết khấu / Giảm giá',
                          prefixIcon: Icon(Icons.discount_outlined),
                          suffixText: 'VNĐ',
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                          isDense: true,
                        ),
                        onChanged: (_) {
                          setState(() {
                            if (_selectedHouseholdId == 0) {
                              _syncPaidAmountToTotal();
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // TỔNG TIỀN THANH TOÁN
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.teal.shade900.withValues(alpha: 0.3) : Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? Colors.teal.shade700 : Colors.teal.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng thanh toán:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(
                        AppFormatters.formatVnd(_finalTotal),
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          color: isDark ? Colors.teal.shade200 : Colors.teal.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // QUICK CHIPS CHỌN TIỀN TRẢ
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.check, size: 14),
                      label: const Text('Trả đủ 100%'),
                      onPressed: () => setState(() => _syncPaidAmountToTotal()),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.pie_chart_outline, size: 14),
                      label: const Text('Trả 50%'),
                      onPressed: () => setState(() => _paidCtrl.text = CurrencyInputFormatter.format(_finalTotal ~/ 2)),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.credit_card, size: 14),
                      label: const Text('Ghi nợ 100% (0đ)'),
                      onPressed: () => setState(() => _paidCtrl.text = '0'),
                    ),
                    ...[100000, 200000, 500000, 1000000, 2000000].map((amt) {
                      return ActionChip(
                        visualDensity: VisualDensity.compact,
                        label: Text('+${AppFormatters.formatCompact(amt)}'),
                        onPressed: () {
                          final curr = AppFormatters.parseVnd(_paidCtrl.text);
                          setState(() => _paidCtrl.text = CurrencyInputFormatter.format((curr + amt).clamp(0, _finalTotal)));
                        },
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 10),

                // SỐ TIỀN TRẢ NGAY & HÌNH THỨC (FORMAT 2.000.000 VNĐ)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: TextFormField(
                        controller: _paidCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          CurrencyInputFormatter(),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Số tiền trả ngay *',
                          prefixIcon: const Icon(Icons.payments_outlined),
                          suffixText: 'VNĐ',
                          suffixStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.teal.shade300 : Colors.teal.shade800,
                          ),
                          border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: DropdownButtonFormField<String>(
                        value: _paymentMethod,
                        decoration: const InputDecoration(
                          labelText: 'Phương thức',
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'CASH', child: Text('💵 Tiền mặt')),
                          DropdownMenuItem(value: 'BANK', child: Text('🏦 Chuyển khoản')),
                        ],
                        onChanged: (v) => setState(() => _paymentMethod = v ?? 'CASH'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // GHI NỢ SỔ CÁI
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _debtAmount > 0
                        ? (isDark ? Colors.deepOrange.shade900.withValues(alpha: 0.3) : Colors.deepOrange.shade50)
                        : (isDark ? Colors.green.shade900.withValues(alpha: 0.3) : Colors.green.shade50),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _debtAmount > 0
                          ? (isDark ? Colors.deepOrange.shade700 : Colors.deepOrange.shade300)
                          : (isDark ? Colors.green.shade700 : Colors.green.shade300),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _debtAmount > 0 ? 'Số tiền ghi vào Sổ nợ:' : 'Thanh toán hoàn tất:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _debtAmount > 0
                              ? (isDark ? Colors.deepOrange.shade200 : Colors.deepOrange.shade800)
                              : (isDark ? Colors.green.shade200 : Colors.green.shade800),
                        ),
                      ),
                      Text(
                        _debtAmount > 0 ? AppFormatters.formatVnd(_debtAmount) : '✨ Không ghi nợ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: _debtAmount > 0
                              ? (isDark ? Colors.deepOrange.shade200 : Colors.deepOrange.shade800)
                              : (isDark ? Colors.green.shade200 : Colors.green.shade800),
                        ),
                      ),
                    ],
                  ),
                ),

                // CẢNH BÁO VƯỢT HẠN MỨC NỢ (NẾU CÓ)
                if (willExceedCreditLimit) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.amber.shade900.withValues(alpha: 0.3) : Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isDark ? Colors.amber.shade700 : Colors.amber.shade400),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: isDark ? Colors.amber.shade300 : Colors.brown, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Lưu ý: Hộ ${selectedHh.name} sẽ có tổng nợ ${AppFormatters.formatVnd(selectedHh.currentDebt + _debtAmount)}, vượt hạn mức tối đa (${AppFormatters.formatVnd(selectedHh.creditLimit)})!',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.amber.shade200 : Colors.brown),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 10),

                TextFormField(
                  controller: _noteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú đơn hàng (tùy chọn)',
                    hintText: 'VD: Giao tận nhà, người mua là con gái...',
                    prefixIcon: Icon(Icons.notes_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                ),
                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: () {
                      if (ctrl.posCart.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Giỏ hàng đang trống! Hãy chọn mặt hàng trước khi lưu đơn.'),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                      if (isSale && _selectedHouseholdId == 0 && _debtAmount > 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Khách lẻ không có sổ nợ! Vui lòng chọn Hộ gia đình hoặc thanh toán đủ 100%.'),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                          ),
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
                      _discountCtrl.text = '0';
                      _paidCtrl.text = '0';
                      setState(() => _containerOwedDelta = 0);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isSale ? 'Đã hoàn tất đơn bán hàng & cập nhật sổ!' : 'Đã nhập kho & cập nhật công nợ NCC!'),
                          backgroundColor: Colors.teal.shade700,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('HOÀN TẤT & LƯU SỔ NGAY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
