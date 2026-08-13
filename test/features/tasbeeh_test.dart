import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adhkar/features/adhkar/presentation/pages/tasbeeh_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Tasbeeh Counter Widget & Persistence Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    void setLargeSurfaceSize(WidgetTester tester) {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    }

    testWidgets('TasbeehPage renders title and initial zero counts', (
      WidgetTester tester,
    ) async {
      setLargeSurfaceSize(tester);
      await tester.pumpWidget(const MaterialApp(home: TasbeehPage()));
      await tester.pumpAndSettle();

      expect(find.text('المسبحة'), findsOneWidget);
      expect(find.text('0'), findsWidgets);
    });

    testWidgets(
      'Tapping tap button increments session and daily total counts',
      (WidgetTester tester) async {
        setLargeSurfaceSize(tester);
        await tester.pumpWidget(const MaterialApp(home: TasbeehPage()));
        await tester.pumpAndSettle();

        final tapFinder = find.byIcon(Icons.touch_app_rounded);
        expect(tapFinder, findsOneWidget);

        await tester.tap(tapFinder);
        await tester.pumpAndSettle();

        expect(find.text('1'), findsWidgets);
      },
    );

    testWidgets('Reset button resets current session count to zero', (
      WidgetTester tester,
    ) async {
      setLargeSurfaceSize(tester);
      await tester.pumpWidget(const MaterialApp(home: TasbeehPage()));
      await tester.pumpAndSettle();

      final tapFinder = find.byIcon(Icons.touch_app_rounded);
      await tester.tap(tapFinder);
      await tester.tap(tapFinder);
      await tester.pumpAndSettle();

      final resetFinder = find.byIcon(Icons.refresh_rounded);
      expect(resetFinder, findsOneWidget);

      await tester.tap(resetFinder);
      await tester.pumpAndSettle();

      expect(find.text('0'), findsWidgets);
    });

    testWidgets(
      'Daily total count loads from SharedPreferences when date matches',
      (WidgetTester tester) async {
        setLargeSurfaceSize(tester);
        final now = DateTime.now();
        final dateStr = '${now.year}-${now.month}-${now.day}';

        SharedPreferences.setMockInitialValues({
          'tasbeeh_today_date': dateStr,
          'tasbeeh_today_count': 150,
        });

        await tester.pumpWidget(const MaterialApp(home: TasbeehPage()));
        await tester.pumpAndSettle();

        expect(find.textContaining('150'), findsOneWidget);
      },
    );

    testWidgets(
      'Daily total resets to 0 when saved date belongs to a previous day',
      (WidgetTester tester) async {
        setLargeSurfaceSize(tester);
        SharedPreferences.setMockInitialValues({
          'tasbeeh_today_date': '2020-1-1',
          'tasbeeh_today_count': 500,
        });

        await tester.pumpWidget(const MaterialApp(home: TasbeehPage()));
        await tester.pumpAndSettle();

        expect(find.textContaining('500'), findsNothing);
        expect(find.textContaining('إجمالي التسبيح اليوم: 0'), findsOneWidget);
      },
    );
  });
}
