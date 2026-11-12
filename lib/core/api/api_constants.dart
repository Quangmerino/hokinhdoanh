import 'package:flutter/foundation.dart';

class ApiConstants {
  /// Production Live API URL trên Cloud (Render & Neon PostgreSQL)
  static const String liveProductionUrl = 'https://hokinhdoanh-api.onrender.com/api';

  /// URL cục bộ khi phát triển trên máy (Local development)
  static const String localHostUrl = 'http://localhost:3000/api';
  static const String localAndroidEmulatorUrl = 'http://10.0.2.2:3000/api';

  /// Cho phép truyền URL server thật khi build app:
  /// flutter build apk --dart-define=API_URL=https://hokinhdoanh-api.onrender.com/api
  /// flutter build web --dart-define=API_URL=https://hokinhdoanh-api.onrender.com/api
  static const String _envApiUrl = String.fromEnvironment('API_URL', defaultValue: '');

  /// Cho phép người dùng chuyển đổi runtime giữa Live Cloud và Local trong màn hình Cài đặt
  static String? customBaseUrl;

  /// Base URL của Backend NestJS API
  /// Mặc định:
  /// 1. Nếu có cấu hình customBaseUrl -> dùng customBaseUrl
  /// 2. Nếu có truyền biến môi trường API_URL -> sử dụng URL đó
  /// 3. Mặc định: Trỏ trực tiếp đến Live Production API trên Cloud
  static String get baseUrl {
    if (customBaseUrl != null && customBaseUrl!.trim().isNotEmpty) {
      return customBaseUrl!.trim();
    }
    if (_envApiUrl.isNotEmpty) {
      return _envApiUrl;
    }
    // Mặc định kết nối trực tiếp Live Production Server
    return liveProductionUrl;
  }

  /// Trạng thái đang kết nối môi trường Live
  static bool get isLiveEnvironment =>
      baseUrl.contains('hokinhdoanh-api.onrender.com') || baseUrl.startsWith('https://');

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
