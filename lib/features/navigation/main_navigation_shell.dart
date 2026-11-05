import 'package:flutter/material.dart';
import '../../core/controllers/business_controller.dart';
import '../../core/utils/formatters.dart';
import '../catalog/catalog_screen.dart';
import '../household_debt/household_debt_screen.dart';
import '../pos_order/pos_screen.dart';
import '../reports_cashflow/reports_screen.dart';
import '../auth/widgets/user_profile_dialog.dart';
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              'Quỹ: ${AppFormatters.formatVnd(ctrl.totalCashBalance)} • Nợ Hộ GĐ: ${AppFormatters.formatVnd(ctrl.totalHouseholdDebt)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Colors.tealAccent),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<ThemeMode>(
            tooltip: 'Chế độ giao diện (Sáng / Tối / Hệ thống)',
            icon: Icon(
              ctrl.themeMode == ThemeMode.dark
                  ? Icons.dark_mode
                  : (ctrl.themeMode == ThemeMode.light ? Icons.light_mode : Icons.brightness_auto),
            ),
            onSelected: (mode) {
              ctrl.setThemeMode(mode);
              final modeName = mode == ThemeMode.system
                  ? 'Theo hệ thống'
                  : (mode == ThemeMode.dark ? 'Chế độ tối' : 'Chế độ sáng');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã chuyển giao diện: $modeName'),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: ThemeMode.system,
                child: Row(
                  children: [
                    const Icon(Icons.brightness_auto, size: 20),
                    const SizedBox(width: 10),
                    const Text('Theo hệ thống'),
                    const Spacer(),
                    if (ctrl.themeMode == ThemeMode.system)
                      const Icon(Icons.check, size: 18, color: Colors.teal),
                  ],
                ),
              ),
              PopupMenuItem(
                value: ThemeMode.light,
                child: Row(
                  children: [
                    const Icon(Icons.light_mode, size: 20, color: Colors.orange),
                    const SizedBox(width: 10),
                    const Text('Chế độ sáng'),
                    const Spacer(),
                    if (ctrl.themeMode == ThemeMode.light)
                      const Icon(Icons.check, size: 18, color: Colors.teal),
                  ],
                ),
              ),
              PopupMenuItem(
                value: ThemeMode.dark,
                child: Row(
                  children: [
                    const Icon(Icons.dark_mode, size: 20, color: Colors.indigoAccent),
                    const SizedBox(width: 10),
                    const Text('Chế độ tối'),
                    const Spacer(),
                    if (ctrl.themeMode == ThemeMode.dark)
                      const Icon(Icons.check, size: 18, color: Colors.teal),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            tooltip: 'Tài khoản & Đăng xuất',
            icon: CircleAvatar(
              radius: 14,
              backgroundColor: Colors.teal.shade200,
              child: Text(
                ctrl.currentUser?.fullName.isNotEmpty == true
                    ? ctrl.currentUser!.fullName[0].toUpperCase()
                    : '👤',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
              ),
            ),
            onPressed: () => showUserProfileDialog(context, ctrl),
          ),
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
