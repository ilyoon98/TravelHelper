// Basic smoke test: the app boots and shows the number tab with its numpad.

import 'package:flutter_test/flutter_test.dart';

import 'package:travel_helper/main.dart';

void main() {
  testWidgets('App boots and shows the number tab by default', (WidgetTester tester) async {
    await tester.pumpWidget(const TravelHelperApp());
    await tester.pumpAndSettle();

    expect(find.text('숫자 발음'), findsOneWidget);
    expect(find.text('환율'), findsOneWidget);
    expect(find.text('회화'), findsOneWidget);
    expect(find.text('설정'), findsOneWidget);
  });
}
