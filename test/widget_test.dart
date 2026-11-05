import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ho_kinh_doanh/core/utils/security_helper.dart';
import 'package:ho_kinh_doanh/core/utils/validators.dart';
import 'package:ho_kinh_doanh/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const HoKinhDoanhApp());
    expect(find.byType(HoKinhDoanhApp), findsOneWidget);
    // Unauthenticated user should see LoginScreen
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Đăng Nhập'), findsOneWidget);
  });

  test('StoreConfig themeMode serialization & defaults', () {
    const config = StoreConfig(storeName: 'Test Store');
    expect(config.themeMode, 'system');

    final map = config.toMap();
    expect(map['theme_mode'], 'system');

    final fromMap = StoreConfig.fromMap(map);
    expect(fromMap.themeMode, 'system');

    final darkConfig = config.copyWith(themeMode: 'dark');
    expect(darkConfig.themeMode, 'dark');
    expect(darkConfig.toMap()['theme_mode'], 'dark');
  });

  test('UserModel serialization and copyWith', () {
    const user = UserModel(
      id: 1,
      fullName: 'Nguyễn Văn A',
      phone: '0987654321',
      email: 'a@gmail.com',
      passwordHash: 'hash123',
      storeName: 'Tạp Hóa A',
      recoveryChannel: 'sms',
      createdAt: '2026-11-05',
    );

    final map = user.toMap();
    expect(map['full_name'], 'Nguyễn Văn A');
    expect(map['phone'], '0987654321');
    expect(map['email'], 'a@gmail.com');
    expect(map['recovery_channel'], 'sms');

    final fromMap = UserModel.fromMap(map);
    expect(fromMap.fullName, 'Nguyễn Văn A');
    expect(fromMap.email, 'a@gmail.com');

    final updated = user.copyWith(recoveryChannel: 'whatsapp');
    expect(updated.recoveryChannel, 'whatsapp');
  });

  test('SecurityHelper hashing and verification', () {
    final hash1 = SecurityHelper.hashPassword('mypassword123');
    final hash2 = SecurityHelper.hashPassword('mypassword123');
    final hash3 = SecurityHelper.hashPassword('different');

    expect(hash1, hash2);
    expect(hash1, isNot(hash3));
    expect(SecurityHelper.verifyPassword('mypassword123', hash1), isTrue);
    expect(SecurityHelper.verifyPassword('wrong', hash1), isFalse);
  });

  test('Auth Validators', () {
    expect(Validators.requiredEmail(''), isNotNull);
    expect(Validators.requiredEmail('invalid-email'), isNotNull);
    expect(Validators.requiredEmail('test@gmail.com'), isNull);

    expect(Validators.password('12345'), isNotNull);
    expect(Validators.password('123456'), isNull);

    expect(Validators.confirmPassword('123456', '654321'), isNotNull);
    expect(Validators.confirmPassword('123456', '123456'), isNull);
  });

  test('BusinessController theme mode changes', () async {
    final ctrl = BusinessController();
    expect(ctrl.themeMode, ThemeMode.system);

    await ctrl.setThemeMode(ThemeMode.dark);
    expect(ctrl.themeMode, ThemeMode.dark);
    expect(ctrl.storeConfig.themeMode, 'dark');

    await ctrl.setThemeMode(ThemeMode.light);
    expect(ctrl.themeMode, ThemeMode.light);
    expect(ctrl.storeConfig.themeMode, 'light');

    await ctrl.setThemeMode(ThemeMode.system);
    expect(ctrl.themeMode, ThemeMode.system);
    expect(ctrl.storeConfig.themeMode, 'system');
  });
}
