import 'package:flutter/material.dart';
import '../../core/controllers/business_controller.dart';
import '../../core/utils/formatters.dart';
import '../catalog/catalog_screen.dart';
import '../household_debt/household_debt_screen.dart';
import '../pos_order/pos_screen.dart';
import '../reports_cashflow/reports_screen.dart';
import 'dialogs/store_settings_dialog.dart';

class MainNavigationShell extends StatefulWidget {
  final BusinessController controller;

  const MainNavigationShell({super.key, required this.controller});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _selectedIndex = 0;

  BusinessController get ctrl => widget.controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ctrl.storeConfig.storeName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              'Quỹ: ${AppFormatters.formatVnd(ctrl.totalCashBalance)} • Nợ Hộ GĐ: ${AppFormatters.formatVnd(ctrl.totalHouseholdDebt)}',
              style: const TextStyle(fontSize: 11, color: Colors.tealAccent),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Cài đặt cửa hàng & VietQR',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => showStoreSettingsDialog(context, ctrl),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          CatalogScreen(
            controller: ctrl,
            onSwitchToPos: () => setState(() => _selectedIndex = 1),
          ),
          PosOrderScreen(controller: ctrl),
          HouseholdDebtScreen(controller: ctrl),
          ReportsCashflowScreen(controller: ctrl),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.account_tree_outlined), label: 'Danh mục'),
          NavigationDestination(icon: Icon(Icons.point_of_sale), label: 'Bán / Nhập'),
          NavigationDestination(icon: Icon(Icons.family_restroom), label: 'Sổ nợ Hộ GĐ'),
          NavigationDestination(icon: Icon(Icons.bar_chart_rounded), label: 'Dòng tiền'),
        ],
      ),
    );
  }
}
