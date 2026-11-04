import 'package:flutter/material.dart';
import 'core/controllers/business_controller.dart';
import 'features/navigation/main_navigation_shell.dart';

// Exports for convenience and backwards compatibility
export 'core/controllers/business_controller.dart';
export 'core/database/app_database.dart';
export 'core/models/models.dart';
export 'core/utils/formatters.dart';
export 'features/catalog/catalog_screen.dart';
export 'features/household_debt/household_debt_screen.dart';
export 'features/navigation/main_navigation_shell.dart';
export 'features/pos_order/pos_screen.dart';
export 'features/reports_cashflow/reports_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HoKinhDoanhApp());
}

class HoKinhDoanhApp extends StatefulWidget {
  const HoKinhDoanhApp({super.key});

  @override
  State<HoKinhDoanhApp> createState() => _HoKinhDoanhAppState();
}

class _HoKinhDoanhAppState extends State<HoKinhDoanhApp> {
  final BusinessController _controller = BusinessController();

  @override
  void initState() {
    super.initState();
    _controller.init();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sổ Tay Hộ Kinh Doanh',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F766E),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => MainNavigationShell(controller: _controller),
      ),
    );
  }
}
