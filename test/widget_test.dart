import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ointment_flutter_mvp_en/main.dart';

void main() {
  testWidgets('Ointment Care opens home screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const OintmentCareApp());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Ointment Care'), findsOneWidget);
    expect(find.text('Ointment Usage'), findsOneWidget);
    expect(find.text('Measure'), findsOneWidget);
    expect(find.text('Skin Journal'), findsOneWidget);
  });

  testWidgets('Skin tab shows diagnosis choices', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const OintmentCareApp());
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Skin'));
    await tester.pumpAndSettle();

    expect(find.text('Condition Type'), findsOneWidget);
    expect(find.text('Atopy'), findsOneWidget);
    expect(find.text('Acne'), findsOneWidget);
  });
}
