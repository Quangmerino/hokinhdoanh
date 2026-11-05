import 'package:flutter/material.dart';
import 'core/controllers/business_controller.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/navigation/main_navigation_shell.dart';

// Exports for convenience and backwards compatibility
export 'core/controllers/business_controller.dart';
export 'core/database/app_database.dart';
export 'core/models/models.dart';
export 'core/utils/formatters.dart';
export 'features/auth/screens/login_screen.dart';
export 'features/auth/screens/register_screen.dart';
export 'features/auth/screens/forgot_password_screen.dart';
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => MaterialApp(
        title: 'Sổ Tay Hộ Kinh Doanh',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0F766E),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFF8FAFC),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF0F766E),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0F766E),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF0B1320),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF0F766E),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          cardTheme: const CardThemeData(
            color: Color(0xFF152238),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              side: BorderSide(color: Color(0xFF1E293B)),
            ),
          ),
          dialogTheme: const DialogThemeData(
            backgroundColor: Color(0xFF152238),
          ),
          useMaterial3: true,
        ),
        themeMode: _controller.themeMode,
        home: _controller.isAuthenticated
            ? MainNavigationShell(controller: _controller)
            : LoginScreen(controller: _controller),
      ),
    );
  }
}
