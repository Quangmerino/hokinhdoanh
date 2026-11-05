import '../models/store_config.dart';
import 'api_client.dart';
import 'api_constants.dart';

class SettingsApiService {
  final ApiClient apiClient;

  SettingsApiService({required this.apiClient});

  /// Lấy cấu hình cửa hàng từ backend
  Future<StoreConfig> getSettings() async {
    final response = await apiClient.get(ApiConstants.settings);
    final map = response as Map<String, dynamic>;

    return StoreConfig(
      storeName: map['storeName'] as String? ?? 'HỘ KINH DOANH CỦA TÔI',
      storeSubtitle: map['storeSubtitle'] as String? ?? 'Sổ Bán Hàng & Công Nợ Gia Đình',
      bankName: map['bankName'] as String? ?? 'MBBank',
      bankAccount: map['bankAccount'] as String? ?? '',
      bankHolder: map['bankHolder'] as String? ?? '',
      themeMode: map['themeMode'] as String? ?? 'system',
    );
  }

  /// Cập nhật cấu hình cửa hàng
  Future<StoreConfig> updateSettings(StoreConfig config) async {
    final response = await apiClient.patch(
      ApiConstants.settings,
      body: {
        'storeName': config.storeName,
        'storeSubtitle': config.storeSubtitle,
        'bankName': config.bankName,
        'bankAccount': config.bankAccount,
        'bankHolder': config.bankHolder,
        'themeMode': config.themeMode,
      },
    );

    final map = response as Map<String, dynamic>;
    final sMap = (map['settings'] as Map<String, dynamic>?) ?? map;

    return StoreConfig(
      storeName: sMap['storeName'] as String? ?? config.storeName,
      storeSubtitle: sMap['storeSubtitle'] as String? ?? config.storeSubtitle,
      bankName: sMap['bankName'] as String? ?? config.bankName,
      bankAccount: sMap['bankAccount'] as String? ?? config.bankAccount,
      bankHolder: sMap['bankHolder'] as String? ?? config.bankHolder,
      themeMode: sMap['themeMode'] as String? ?? config.themeMode,
    );
  }
}
