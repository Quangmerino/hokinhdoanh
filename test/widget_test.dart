import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ho_kinh_doanh/core/controllers/business_controller.dart';
import 'package:ho_kinh_doanh/core/models/models.dart';
import 'package:ho_kinh_doanh/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const HoKinhDoanhApp());
    expect(find.byType(HoKinhDoanhApp), findsOneWidget);
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
