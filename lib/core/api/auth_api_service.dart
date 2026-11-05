import '../models/user_model.dart';
import 'api_client.dart';
import 'api_constants.dart';

class AuthApiService {
  final ApiClient apiClient;

  AuthApiService({required this.apiClient});

  /// Đăng ký tài khoản chủ hộ kinh doanh qua API Backend
  Future<Map<String, dynamic>> register({
    required String fullName,
    required String storeName,
    required String phone,
    required String email,
    required String password,
    String recoveryChannel = 'sms',
  }) async {
    final response = await apiClient.post(
      ApiConstants.register,
      body: {
        'fullName': fullName.trim(),
        'storeName': storeName.trim(),
        'phone': phone.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
        'recoveryChannel': recoveryChannel,
      },
    );

    final map = response as Map<String, dynamic>;
    final userMap = map['user'] as Map<String, dynamic>;
    final token = map['accessToken'] as String?;

    if (token != null) {
      apiClient.setAccessToken(token);
    }

    final user = UserModel(
      id: userMap['id'] as int? ?? 0,
      fullName: userMap['fullName'] as String? ?? fullName,
      phone: userMap['phone'] as String? ?? phone,
      email: userMap['email'] as String? ?? email,
      passwordHash: '', // Backend không trả passwordHash vì bảo mật
      storeName: userMap['storeName'] as String? ?? storeName,
      recoveryChannel: userMap['recoveryChannel'] as String? ?? recoveryChannel,
      createdAt: userMap['createdAt'] as String? ?? DateTime.now().toIso8601String(),
    );

    return {
      'user': user,
      'accessToken': token,
      'message': map['message'] as String? ?? 'Đăng ký thành công',
    };
  }

  /// Đăng nhập tài khoản qua SĐT hoặc Email
  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) async {
    final response = await apiClient.post(
      ApiConstants.login,
      body: {
        'identifier': identifier.trim(),
        'password': password,
      },
    );

    final map = response as Map<String, dynamic>;
    final userMap = map['user'] as Map<String, dynamic>;
    final token = map['accessToken'] as String?;

    if (token != null) {
      apiClient.setAccessToken(token);
    }

    final user = UserModel(
      id: userMap['id'] as int? ?? 0,
      fullName: userMap['fullName'] as String? ?? '',
      phone: userMap['phone'] as String? ?? '',
      email: userMap['email'] as String? ?? '',
      passwordHash: '',
      storeName: userMap['storeName'] as String? ?? '',
      recoveryChannel: userMap['recoveryChannel'] as String? ?? 'sms',
      createdAt: userMap['createdAt'] as String? ?? '',
    );

    return {
      'user': user,
      'accessToken': token,
      'message': map['message'] as String? ?? 'Đăng nhập thành công',
    };
  }

  /// Lấy thông tin tài khoản hiện tại với Bearer token
  Future<UserModel> getProfile() async {
    final response = await apiClient.get(ApiConstants.me);
    final map = response as Map<String, dynamic>;

    return UserModel(
      id: map['id'] as int? ?? 0,
      fullName: map['fullName'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      passwordHash: '',
      storeName: map['storeName'] as String? ?? '',
      recoveryChannel: map['recoveryChannel'] as String? ?? 'sms',
      createdAt: map['createdAt'] as String? ?? '',
    );
  }

  /// Yêu cầu gửi OTP khôi phục mật khẩu (SMS / Gmail / WhatsApp / Facebook)
  Future<Map<String, dynamic>> sendRecoveryOtp({
    required String identifier,
    required String channel,
  }) async {
    final response = await apiClient.post(
      ApiConstants.sendRecoveryOtp,
      body: {
        'identifier': identifier.trim(),
        'channel': channel.toLowerCase(),
      },
    );

    final map = response as Map<String, dynamic>;
    return {
      'success': map['success'] as bool? ?? true,
      'channel': map['channel'] as String? ?? channel,
      'target': map['target'] as String? ?? identifier,
      'message': map['message'] as String? ?? '',
      'simulatedOtp': map['simulatedOtp'] as String? ?? '',
    };
  }

  /// Xác thực mã OTP 6 số
  Future<Map<String, dynamic>> verifyRecoveryOtp({
    required String identifier,
    required String code,
  }) async {
    final response = await apiClient.post(
      ApiConstants.verifyRecoveryOtp,
      body: {
        'identifier': identifier.trim(),
        'code': code.trim(),
      },
    );

    final map = response as Map<String, dynamic>;
    return {
      'success': map['success'] as bool? ?? true,
      'message': map['message'] as String? ?? '',
    };
  }

  /// Đặt lại mật khẩu mới
  Future<Map<String, dynamic>> resetPassword({
    required String identifier,
    required String code,
    required String newPassword,
  }) async {
    final response = await apiClient.post(
      ApiConstants.resetPassword,
      body: {
        'identifier': identifier.trim(),
        'code': code.trim(),
        'newPassword': newPassword,
      },
    );

    final map = response as Map<String, dynamic>;
    return {
      'success': map['success'] as bool? ?? true,
      'message': map['message'] as String? ?? 'Đổi mật khẩu thành công',
    };
  }
}
