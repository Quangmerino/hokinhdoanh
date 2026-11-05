import 'package:flutter/material.dart';
import '../../core/controllers/business_controller.dart';
import '../../core/utils/formatters.dart';
import 'dialogs/manual_cash_dialog.dart';

class ReportsCashflowScreen extends StatefulWidget {
  final BusinessController controller;

  const ReportsCashflowScreen({super.key, required this.controller});

  @override
  State<ReportsCashflowScreen> createState() => _ReportsCashflowScreenState();
}

class _ReportsCashflowScreenState extends State<ReportsCashflowScreen> {
  BusinessController get ctrl => widget.controller;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final anchor = ctrl.reportAnchorDate;
    final gran = ctrl.reportGranularity;

    // Filter orders & cash transactions by Day / Week / Month / Year
    final filteredOrders = ctrl.orders.where((o) {
      if (gran == 'DAY') return o.dateStr.startsWith(anchor);
      if (gran == 'MONTH') return o.dateStr.startsWith(anchor.substring(0, 7));
      if (gran == 'YEAR') return o.dateStr.startsWith(anchor.substring(0, 4));
      return true;
    }).toList();

    final filteredCash = ctrl.cashTransactions.where((c) {
      if (gran == 'DAY') return c.dateStr.startsWith(anchor);
      if (gran == 'MONTH') return c.dateStr.startsWith(anchor.substring(0, 7));
      if (gran == 'YEAR') return c.dateStr.startsWith(anchor.substring(0, 4));
      return true;
    }).toList();

    final totalRev = filteredOrders.fold<int>(0, (s, o) => s + o.totalAmount);
    final totalCogs = filteredOrders.fold<int>(0, (s, o) => s + o.cogs);
    final grossProfit = totalRev - totalCogs;
    final cashIn = filteredCash.where((c) => c.flow == 'IN').fold<int>(0, (s, c) => s + c.amount);
    final cashOut = filteredCash.where((c) => c.flow == 'OUT').fold<int>(0, (s, c) => s + c.amount);
    final netCash = cashIn - cashOut;

    final roots = ctrl.categories.where((c) => c.parentId == null).toList();

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Granularity Filter Bar
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade300),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 'DAY', label: Text('Ngày')),
                    ButtonSegment(value: 'WEEK', label: Text('Tuần')),
                    ButtonSegment(value: 'MONTH', label: Text('Tháng')),
                    ButtonSegment(value: 'YEAR', label: Text('Năm')),
                  ],
                  selected: {ctrl.reportGranularity},
                  onSelectionChanged: (v) => setState(() => ctrl.reportGranularity = v.first),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                      onPressed: () => showManualCashModal(context, ctrl, 'IN'),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Phiếu Thu'),
                    ),
                    const SizedBox(width: 6),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                      onPressed: () => showManualCashModal(context, ctrl, 'OUT'),
                      icon: const Icon(Icons.remove, size: 16),
                      label: const Text('Phiếu Chi'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 4 KPI Cards
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.6,
          children: [
            _buildKpiBox(context, '1. Tổng Doanh Thu', AppFormatters.formatVnd(totalRev), isDark ? Colors.teal.shade300 : Colors.teal.shade900),
            _buildKpiBox(context, '2. Lợi Nhuận Gộp', AppFormatters.formatVnd(grossProfit), isDark ? Colors.green.shade300 : Colors.green.shade700),
            _buildKpiBox(context, '3. Dòng Tiền VÀO', AppFormatters.formatVnd(cashIn), isDark ? Colors.blue.shade300 : Colors.blue.shade700),
            _buildKpiBox(context, '4. Dòng Tiền RA', '${AppFormatters.formatVnd(cashOut)}\n(Thuần: ${AppFormatters.formatVnd(netCash)})', isDark ? Colors.red.shade300 : Colors.red.shade700),
          ],
        ),
        const SizedBox(height: 12),

        // Dynamic Category Revenue Breakdown
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
                const Text(
                  '📊 Tỷ Trọng Doanh Thu Theo Danh Mục Bạn Tạo',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const Divider(),
                if (roots.isEmpty)
                  const Text('Chưa có danh mục gốc nào.', style: TextStyle(fontSize: 12, color: Colors.grey))
                else
                  ...roots.map((r) {
                    final catRev = filteredOrders
                        .where((o) => o.categoryRootId == r.id)
                        .fold<int>(0, (s, o) => s + o.totalAmount);
                    final pct = totalRev > 0 ? (catRev / totalRev) : 0.0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${r.icon} ${r.name}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              Text('${AppFormatters.formatVnd(catRev)} (${(pct * 100).round()}%)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: pct,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
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

        // Cashflow Ledger
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
                const Text(
                  '📒 Sổ Quỹ Dòng Tiền Ra / Vào Chi Tiết',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const Divider(),
                if (filteredCash.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: Text('Chưa có giao dịch dòng tiền nào trong kỳ.')),
                  )
                else
                  ...filteredCash.map((tx) {
                    final isIn = tx.flow == 'IN';
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: isIn
                            ? (isDark ? Colors.green.shade900 : Colors.green.shade100)
                            : (isDark ? Colors.red.shade900 : Colors.red.shade100),
                        child: Text(
                          isIn ? '+' : '-',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isIn
                                ? (isDark ? Colors.green.shade200 : Colors.green.shade800)
                                : (isDark ? Colors.red.shade200 : Colors.red.shade800),
                          ),
                        ),
                      ),
                      title: Text(tx.note, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text('${tx.dateStr} • ${tx.method == "BANK" ? "Chuyển khoản" : "Tiền mặt"}'),
                      trailing: Text(
                        '${isIn ? "+" : "-"}${AppFormatters.formatVnd(tx.amount)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isIn
                              ? (isDark ? Colors.green.shade300 : Colors.green.shade700)
                              : (isDark ? Colors.red.shade300 : Colors.red.shade700),
                        ),
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

  Widget _buildKpiBox(BuildContext context, String title, String value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF152238) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black54)),
          const SizedBox(height: 4),
          Text(value, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
