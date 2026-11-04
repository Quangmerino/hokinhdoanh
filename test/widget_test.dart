import 'package:flutter_test/flutter_test.dart';
import 'package:ho_kinh_doanh/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const HoKinhDoanhApp());
    expect(find.byType(HoKinhDoanhApp), findsOneWidget);
  });
}
