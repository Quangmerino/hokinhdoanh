import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:ho_kinh_doanh/core/api/api_client.dart';
import 'package:ho_kinh_doanh/core/api/api_constants.dart';
import 'package:ho_kinh_doanh/core/api/api_exception.dart';
import 'package:ho_kinh_doanh/core/api/auth_api_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('ApiClient & AuthApiService Tests', () {
    test('ApiConstants provides valid base URL and endpoints', () {
      expect(ApiConstants.baseUrl, contains('http'));
      expect(ApiConstants.register, '/auth/register');
      expect(ApiConstants.login, '/auth/login');
      expect(ApiConstants.me, '/auth/me');
      expect(ApiConstants.sendRecoveryOtp, '/auth/recovery/send-otp');
      expect(ApiConstants.verifyRecoveryOtp, '/auth/recovery/verify-otp');
      expect(ApiConstants.resetPassword, '/auth/recovery/reset-password');
    });

    test('AuthApiService.register sends proper payload and parses response', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, contains('/auth/register'));
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['phone'], '0987654321');
        expect(body['email'], 'test@gmail.com');

        return http.Response(
          jsonEncode({
            'message': 'Đăng ký tài khoản thành công',
            'accessToken': 'jwt_test_token_123',
            'user': {
              'id': 1,
              'fullName': 'Nguyễn Văn A',
              'storeName': 'Tạp Hóa A',
              'phone': '0987654321',
              'email': 'test@gmail.com',
              'recoveryChannel': 'sms',
              'createdAt': '2026-11-05T00:00:00.000Z',
            },
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(httpClient: mockClient);
      final service = AuthApiService(apiClient: apiClient);

      final result = await service.register(
        fullName: 'Nguyễn Văn A',
        storeName: 'Tạp Hóa A',
        phone: '0987654321',
        email: 'test@gmail.com',
        password: 'password123',
        recoveryChannel: 'sms',
      );

      expect(result['accessToken'], 'jwt_test_token_123');
      expect(result['user'], isNotNull);
      expect(apiClient.accessToken, 'jwt_test_token_123');
    });

    test('AuthApiService.login sends proper payload and saves access token', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, contains('/auth/login'));
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['identifier'], '0987654321');
        expect(body['password'], 'password123');

        return http.Response(
          jsonEncode({
            'message': 'Đăng nhập thành công',
            'accessToken': 'logged_in_token_xyz',
            'user': {
              'id': 2,
              'fullName': 'Trần Văn B',
              'storeName': 'Đại Lý B',
              'phone': '0987654321',
              'email': 'b@gmail.com',
              'recoveryChannel': 'email',
              'createdAt': '2026-11-05T00:00:00.000Z',
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = ApiClient(httpClient: mockClient);
      final service = AuthApiService(apiClient: apiClient);

      final result = await service.login(
        identifier: '0987654321',
        password: 'password123',
      );

      expect(result['accessToken'], 'logged_in_token_xyz');
      expect(apiClient.accessToken, 'logged_in_token_xyz');
    });

    test('AuthApiService password recovery flow (send OTP, verify, reset)', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/auth/recovery/send-otp')) {
          return http.Response(
            jsonEncode({
              'message': 'Mã OTP khôi phục đã được gửi qua SMS',
              'target': '0987***321',
              'simulatedOtp': '654321',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        } else if (request.url.path.contains('/auth/recovery/verify-otp')) {
          return http.Response(
            jsonEncode({
              'valid': true,
              'message': 'Xác thực mã OTP thành công',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        } else if (request.url.path.contains('/auth/recovery/reset-password')) {
          return http.Response(
            jsonEncode({
              'message': 'Mật khẩu đã được đặt lại thành công',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(httpClient: mockClient);
      final service = AuthApiService(apiClient: apiClient);

      final sendRes = await service.sendRecoveryOtp(
        identifier: '0987654321',
        channel: 'sms',
      );
      expect(sendRes['simulatedOtp'], '654321');

      final verifyRes = await service.verifyRecoveryOtp(
        identifier: '0987654321',
        code: '654321',
      );
      expect(verifyRes['success'], isTrue);

      final resetRes = await service.resetPassword(
        identifier: '0987654321',
        code: '654321',
        newPassword: 'newpassword123',
      );
      expect(resetRes['message'], contains('thành công'));
    });

    test('ApiException parses message and statusCode properly', () {
      const ex = ApiException(
        message: 'Số điện thoại này đã được sử dụng để đăng ký tài khoản',
        statusCode: 409,
      );
      expect(ex.message, 'Số điện thoại này đã được sử dụng để đăng ký tài khoản');
      expect(ex.statusCode, 409);
      expect(ex.toString(), 'Số điện thoại này đã được sử dụng để đăng ký tài khoản');
    });
  });
}
