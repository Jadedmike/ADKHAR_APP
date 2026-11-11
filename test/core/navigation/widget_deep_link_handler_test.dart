import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adhkar/core/navigation/widget_deep_link_handler.dart';
import 'package:adhkar/features/adhkar/presentation/pages/category_list_page.dart';
import 'package:adhkar/features/adhkar/presentation/pages/home_page.dart';
import 'package:adhkar/features/adhkar/presentation/pages/splash_page.dart';
import 'package:adhkar/features/prayer/presentation/pages/prayer_times_page.dart';

class _TestAssetBundle extends CachingAssetBundle {
  static final Uint8List _transparentPng = Uint8List.fromList(const [
    137, 80, 78, 71, 13, 10, 26, 10,
    0, 0, 0, 13, 73, 72, 68, 82,
    0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0,
    31, 21, 108, 137,
    0, 0, 0, 10, 73, 68, 65, 84,
    120, 156, 99, 96, 0, 0, 0, 2, 0, 1,
    226, 33, 188, 51,
    0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130,
  ]);

  @override
  Future<ByteData> load(String key) async {
    if (key.endsWith('.png')) {
      return ByteData.sublistView(_transparentPng);
    }
    return rootBundle.load(key);
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  void setPhoneViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('parseWidgetDeepLink', () {
    test('parses valid prayer, morning, evening, daily adhkar, and home URIs', () {
      expect(
        parseWidgetDeepLink(Uri.parse('adhkar://widget/prayer')),
        WidgetDeepLinkTarget.prayer,
      );
      expect(
        parseWidgetDeepLink(Uri.parse('adhkar://widget/adhkar?period=morning')),
        WidgetDeepLinkTarget.morningAdhkar,
      );
      expect(
        parseWidgetDeepLink(Uri.parse('adhkar://widget/adhkar?period=evening')),
        WidgetDeepLinkTarget.eveningAdhkar,
      );
      expect(
        parseWidgetDeepLink(Uri.parse('adhkar://widget/adhkar')),
        WidgetDeepLinkTarget.adhkarCategories,
      );
      expect(
        parseWidgetDeepLink(Uri.parse('adhkar://widget/adhkar?period=daily')),
        WidgetDeepLinkTarget.adhkarCategories,
      );
      expect(
        parseWidgetDeepLink(Uri.parse('adhkar://widget/home')),
        WidgetDeepLinkTarget.home,
      );
    });

    test('returns null for invalid, unknown, or malformed URIs', () {
      expect(parseWidgetDeepLink(null), isNull);
      expect(
        parseWidgetDeepLink(Uri.parse('https://widget/prayer')),
        isNull,
      );
      expect(
        parseWidgetDeepLink(Uri.parse('adhkar://other/prayer')),
        isNull,
      );
      expect(
        parseWidgetDeepLink(Uri.parse('adhkar://widget/unknown')),
        isNull,
      );
      expect(
        parseWidgetDeepLink(Uri.parse('adhkar://widget/adhkar?period=night')),
        isNull,
      );
      expect(parseWidgetDeepLink(Uri.parse('adhkar://widget')), isNull);
    });
  });

  group('WidgetDeepLinkCoordinator', () {
    Widget buildTestHost({
      required GlobalKey<NavigatorState> navKey,
      required WidgetRouteObserver observer,
    }) {
      return DefaultAssetBundle(
        bundle: _TestAssetBundle(),
        child: MaterialApp(
          navigatorKey: navKey,
          navigatorObservers: [observer],
          locale: const Locale('ar'),
          home: const Directionality(
            textDirection: TextDirection.rtl,
            child: SplashPage(),
          ),
        ),
      );
    }

    Future<void> pumpRouteTransition(WidgetTester tester) async {
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));
    }

    testWidgets(
      'preserves SplashPage when initial URI is null or unknown',
      (tester) async {
        setPhoneViewport(tester);
        final navKey = GlobalKey<NavigatorState>();
        final observer = WidgetRouteObserver();
        final clicks = StreamController<Uri?>.broadcast();
        addTearDown(clicks.close);

        await tester.pumpWidget(
          buildTestHost(navKey: navKey, observer: observer),
        );

        final coordinator = WidgetDeepLinkCoordinator(
          navigatorKey: navKey,
          routeObserver: observer,
          getInitialUri: () async => Uri.parse('adhkar://widget/unknown'),
          clickStream: () => clicks.stream,
        );
        addTearDown(coordinator.dispose);

        await coordinator.initialize();
        await pumpRouteTransition(tester);

        expect(find.byType(SplashPage), findsOneWidget);
        expect(find.byType(PrayerTimesPage), findsNothing);
      },
    );

    testWidgets(
      'cold start to prayer deep link opens PrayerTimesPage and suppresses immediate duplicate click',
      (tester) async {
        setPhoneViewport(tester);
        final navKey = GlobalKey<NavigatorState>();
        final observer = WidgetRouteObserver();
        final clicks = StreamController<Uri?>.broadcast();
        addTearDown(clicks.close);

        await tester.pumpWidget(
          buildTestHost(navKey: navKey, observer: observer),
        );

        var now = DateTime(2026, 11, 11, 9, 0, 0);
        final prayerUri = Uri.parse('adhkar://widget/prayer');

        final coordinator = WidgetDeepLinkCoordinator(
          navigatorKey: navKey,
          routeObserver: observer,
          getInitialUri: () async => prayerUri,
          clickStream: () => clicks.stream,
          nowProvider: () => now,
        );
        addTearDown(coordinator.dispose);

        await coordinator.initialize();
        // Emit duplicate stream event within suppression window.
        clicks.add(prayerUri);
        await pumpRouteTransition(tester);

        expect(find.byType(PrayerTimesPage), findsOneWidget);
        expect(find.byType(SplashPage), findsNothing);

        // Even after suppression window expires, do not push a second PrayerTimesPage on top of itself.
        now = now.add(const Duration(seconds: 5));
        clicks.add(prayerUri);
        await pumpRouteTransition(tester);
        expect(find.byType(PrayerTimesPage), findsOneWidget);

        // Popping returns cleanly to HomePage rather than SplashPage.
        navKey.currentState!.pop();
        await pumpRouteTransition(tester);
        expect(find.byType(HomePage), findsOneWidget);
      },
    );

    testWidgets(
      'warm start routes to morning and evening CategoryListPage and HomePage',
      (tester) async {
        setPhoneViewport(tester);
        final navKey = GlobalKey<NavigatorState>();
        final observer = WidgetRouteObserver();
        final clicks = StreamController<Uri?>.broadcast();
        addTearDown(clicks.close);

        await tester.pumpWidget(
          buildTestHost(navKey: navKey, observer: observer),
        );

        var now = DateTime(2026, 11, 11, 9, 0, 0);
        final coordinator = WidgetDeepLinkCoordinator(
          navigatorKey: navKey,
          routeObserver: observer,
          getInitialUri: () async => null,
          clickStream: () => clicks.stream,
          nowProvider: () => now,
        );
        addTearDown(coordinator.dispose);

        await coordinator.initialize();
        await tester.pump();
        expect(find.byType(SplashPage), findsOneWidget);

        // Warm click -> morning Adhkar.
        clicks.add(Uri.parse('adhkar://widget/adhkar?period=morning'));
        await pumpRouteTransition(tester);
        expect(find.byType(CategoryListPage), findsOneWidget);
        expect(find.text('أذكار الصباح'), findsOneWidget);

        // Warm click -> evening Adhkar.
        now = now.add(const Duration(seconds: 5));
        clicks.add(Uri.parse('adhkar://widget/adhkar?period=evening'));
        await pumpRouteTransition(tester);
        expect(find.byType(CategoryListPage), findsOneWidget);
        expect(find.text('أذكار المساء'), findsOneWidget);

        // Warm click -> home.
        now = now.add(const Duration(seconds: 5));
        clicks.add(Uri.parse('adhkar://widget/home'));
        await pumpRouteTransition(tester);
        expect(find.byType(HomePage), findsOneWidget);
      },
    );
  });
}
