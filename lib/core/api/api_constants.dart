import 'package:flutter/foundation.dart';

class ApiConstants {
  /// Cho phép truyền URL server thật khi build app:
  /// flutter build apk --dart-define=API_URL=https://your-domain.com/api
  /// flutter build web --dart-define=API_URL=https://your-domain.com/api
  static const String _envApiUrl = String.fromEnvironment('API_URL', defaultValue: '');

  /// Base URL của Backend NestJS API
  /// Mặc định:
  /// - Nếu có truyền biến môi trường API_URL -> sử dụng URL đó
  /// - Windows / macOS / Linux / Web: http://localhost:3000/api
  /// - Android Emulator: http://10.0.2.2:3000/api
  static String get baseUrl {
    if (_envApiUrl.isNotEmpty) {
      return _envApiUrl;
    }
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // 10.0.2.2 trỏ về localhost máy host từ Android Emulator
        return 'http://10.0.2.2:3000/api';
      case TargetPlatform.iOS:
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      default:
        return 'http://localhost:3000/api';
    }
  }

  // Auth Endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String me = '/auth/me';
  static const String sendRecoveryOtp = '/auth/recovery/send-otp';
  static const String verifyRecoveryOtp = '/auth/recovery/verify-otp';
  static const String resetPassword = '/auth/recovery/reset-password';

  // Catalog & Inventory Endpoints
  static const String categories = '/categories';
  static const String suppliers = '/suppliers';
  static const String products = '/products';

  // Households & Debt Endpoints
  static const String households = '/households';

  // Orders & POS Endpoints
  static const String orders = '/orders';
  static const String checkout = '/orders/checkout';

  // Cashflow & Reports
  static const String cashflow = '/cashflow';
  static const String reportsPnl = '/reports/pnl';
  static const String reportsDailyTrend = '/reports/daily-trend';

  // Store Settings
  static const String settings = '/settings';
}
