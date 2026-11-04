import 'package:flutter/material.dart';
import '../../core/controllers/business_controller.dart';
import '../../core/utils/formatters.dart';
import 'dialogs/collect_debt_dialog.dart';
import 'dialogs/household_dialog.dart';
import 'dialogs/vietqr_zalo_dialog.dart';

class HouseholdDebtScreen extends StatefulWidget {
  final BusinessController controller;

  const HouseholdDebtScreen({super.key, required this.controller});

  @override
  State<HouseholdDebtScreen> createState() => _HouseholdDebtScreenState();
}

class _HouseholdDebtScreenState extends State<HouseholdDebtScreen> {
  BusinessController get ctrl => widget.controller;

  @override
  Widget build(BuildContext context) {
    final selectedHh = ctrl.households.where((h) => h.id == ctrl.selectedHouseholdId).firstOrNull ??
        ctrl.households.firstOrNull;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // KPI Summary Row
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Tổng Nợ Phải Thu',
                AppFormatters.formatVnd(ctrl.totalHouseholdDebt),
                Colors.amber.shade800,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                'Vỏ / Bao Bì Giữ',
                '${ctrl.totalContainerOwed} vỏ',
                Colors.blue.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Household List Card
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
                    const Text(
                      '👨‍👩‍👧‍👦 Danh Sách Hộ Gia Đình',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    FilledButton.icon(
                      onPressed: () => showHouseholdDialog(context, ctrl),
                      icon: const Icon(Icons.person_add_alt_1, size: 16),
                      label: const Text('+ Thêm Hộ GĐ'),
                    ),
                  ],
                ),
                const Divider(),
                if (ctrl.households.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: Text('Chưa có Hộ gia đình nào. Hãy bấm "+ Thêm Hộ GĐ" để tự tạo sổ nợ.')),
                  )
                else
                  ...ctrl.households.map((h) {
                    final isSelected = selectedHh?.id == h.id;
                    return ListTile(
                      selected: isSelected,
                      selectedTileColor: Colors.teal.shade50,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      onTap: () => setState(() => ctrl.selectedHouseholdId = h.id),
                      title: Text(h.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Chủ hộ: ${h.headName} • SĐT: ${h.phone.isEmpty ? "---" : h.phone}'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            h.currentDebt > 0 ? AppFormatters.formatVnd(h.currentDebt) : 'Hết nợ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: h.currentDebt > 0 ? Colors.deepOrange : Colors.green,
                            ),
                          ),
                          if (h.containerOwed > 0)
                            Text('Giữ ${h.containerOwed} vỏ', style: const TextStyle(fontSize: 11, color: Colors.blue)),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Selected Household Ledger Detail
        if (selectedHh != null)
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
                      Expanded(
                        child: Text(
                          selectedHh.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: () => showHouseholdDialog(context, ctrl, editHh: selectedHh),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        onPressed: () => ctrl.deleteHousehold(selectedHh.id),
                      ),
                    ],
                  ),
                  Text('Thành viên mua hàng: ${selectedHh.members.join(", ")}', style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: () => showCollectDebtDialog(context, ctrl, selectedHh),
                        icon: const Icon(Icons.payments_outlined, size: 16),
                        label: const Text('💵 Thu Nợ / Trả Vỏ'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => showVietQrZaloDialog(context, ctrl, selectedHh),
                        icon: const Icon(Icons.qr_code_2, size: 16),
                        label: const Text('📲 Phiếu Nhắc Nợ VietQR Zalo'),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  const Text(
                    '📜 Sổ Cái Lịch Sử Mua Chịu & Trả Nợ',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  if (selectedHh.ledger.isEmpty)
                    const Text('Chưa có phát sinh công nợ nào.', style: TextStyle(fontSize: 12, color: Colors.grey))
                  else
                    ...selectedHh.ledger.map((entry) {
                      final isPlus = entry.changeAmount > 0;
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text('${entry.dateStr} • 👤 ${entry.actorName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        subtitle: Text(entry.description, style: const TextStyle(fontSize: 12)),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${isPlus ? "+" : ""}${AppFormatters.formatVnd(entry.changeAmount)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isPlus ? Colors.deepOrange : Colors.green,
                              ),
                            ),
                            Text(
                              'Dư nợ: ${AppFormatters.formatVnd(entry.balanceAfter)}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
