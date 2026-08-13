import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adhkar/features/adhkar/presentation/pages/splash_page.dart';
import 'package:adhkar/features/adhkar/presentation/pages/home_page.dart';
import 'package:adhkar/features/adhkar/presentation/pages/azkar_categories_page.dart';
import 'package:adhkar/features/adhkar/presentation/pages/single_dhikr_page.dart';
import 'package:adhkar/features/adhkar/presentation/managers/favorites_manager.dart';

class TestAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key.endsWith('.png') ||
        key.endsWith('.jpg') ||
        key.endsWith('.jpeg') ||
        key.endsWith('.gif')) {
      return ByteData.sublistView(
        Uint8List.fromList([
          137,
          80,
          78,
          71,
          13,
          10,
          26,
          10,
          0,
          0,
          0,
          13,
          73,
          72,
          68,
          82,
          0,
          0,
          0,
          1,
          0,
          0,
          0,
          1,
          8,
          6,
          0,
          0,
          0,
          31,
          21,
          108,
          137,
          0,
          0,
          0,
          10,
          73,
          68,
          65,
          84,
          120,
          156,
          99,
          96,
          0,
          0,
          0,
          2,
          0,
          1,
          226,
          33,
          188,
          51,
          0,
          0,
          0,
          0,
          73,
          69,
          78,
          68,
          174,
          66,
          96,
          130,
        ]),
      );
    }
    return rootBundle.load(key);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FavoritesManager.favoriteDhikrs.value = [];
  });

  void setLargeSurfaceSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Widget wrapWithBundle(Widget child) {
    return DefaultAssetBundle(
      bundle: TestAssetBundle(),
      child: MaterialApp(home: child),
    );
  }

  group('Widget Navigation & Interaction Tests', () {
    testWidgets(
      'SplashPage renders title and Start button navigates to HomePage',
      (WidgetTester tester) async {
        setLargeSurfaceSize(tester);
        await tester.pumpWidget(wrapWithBundle(const SplashPage()));
        await tester.pumpAndSettle();

        expect(find.text('أذكار وأدعية تصنع السكينة'), findsOneWidget);
        final startBtn = find.text('ابدأ');
        expect(startBtn, findsOneWidget);

        await tester.tap(startBtn);
        await tester.pumpAndSettle();

        expect(find.byType(HomePage), findsOneWidget);
      },
    );

    testWidgets('AzkarCategoriesPage renders list of categories', (
      WidgetTester tester,
    ) async {
      setLargeSurfaceSize(tester);
      await tester.pumpWidget(wrapWithBundle(const AzkarCategoriesPage()));
      await tester.pumpAndSettle();

      expect(find.text('أذكار الصباح'), findsOneWidget);
      expect(find.text('أذكار المساء'), findsOneWidget);
      expect(find.text('أذكار بعد الصلاة'), findsOneWidget);
    });

    testWidgets(
      'SingleDhikrPage counter increment and bookmark favorite toggle',
      (WidgetTester tester) async {
        setLargeSurfaceSize(tester);
        final testList = [
          {
            'id': 1,
            'text': 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
            'count': 3,
            'source': 'صحيح مسلم',
          },
        ];

        await tester.pumpWidget(
          wrapWithBundle(
            SingleDhikrPage(
              categoryTitle: 'أذكار الصباح',
              dhikrList: testList,
              initialIndex: 0,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('سُبْحَانَ اللَّهِ وَبِحَمْدِهِ'), findsOneWidget);
        expect(find.text('0'), findsWidgets);

        final addBtn = find.byIcon(Icons.add_rounded);
        expect(addBtn, findsOneWidget);

        await tester.tap(addBtn);
        await tester.pumpAndSettle();

        expect(find.text('1'), findsWidgets);

        final bookmarkBtn = find.byIcon(Icons.bookmark_border_rounded);
        expect(bookmarkBtn, findsOneWidget);

        await tester.tap(bookmarkBtn);
        await tester.pumpAndSettle();

        expect(FavoritesManager.favoriteDhikrs.value.length, equals(1));
      },
    );
  });
}
