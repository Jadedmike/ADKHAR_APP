import 'dart:async';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import '../../config/theme/app_assets.dart';
import '../../config/theme/app_page_transitions.dart';
import '../../features/adhkar/presentation/pages/category_list_page.dart';
import '../../features/adhkar/presentation/pages/home_page.dart';
import '../../features/prayer/presentation/pages/prayer_times_page.dart';

/// Supported widget tap destinations inside the application.
enum WidgetDeepLinkTarget {
  prayer('/widget/prayer'),
  morningAdhkar('/widget/adhkar/morning'),
  eveningAdhkar('/widget/adhkar/evening'),
  adhkarCategories('/widget/adhkar'),
  home('/widget/home');

  final String routeName;

  const WidgetDeepLinkTarget(this.routeName);
}

/// Parses an incoming widget launch [Uri] into a verified app destination,
/// returning `null` for unknown schemes, hosts, or paths.
WidgetDeepLinkTarget? parseWidgetDeepLink(Uri? uri) {
  if (uri == null) return null;
  if (uri.scheme.toLowerCase() != 'adhkar') return null;
  if (uri.host.toLowerCase() != 'widget') return null;

  final segments = uri.pathSegments
      .map((s) => s.trim().toLowerCase())
      .where((s) => s.isNotEmpty)
      .toList();
  if (segments.length != 1) return null;

  switch (segments.first) {
    case 'prayer':
      return WidgetDeepLinkTarget.prayer;
    case 'home':
      return WidgetDeepLinkTarget.home;
    case 'adhkar':
      final period = uri.queryParameters['period']?.trim().toLowerCase();
      switch (period) {
        case 'morning':
          return WidgetDeepLinkTarget.morningAdhkar;
        case 'evening':
          return WidgetDeepLinkTarget.eveningAdhkar;
        case null:
        case '':
        case 'daily':
          return WidgetDeepLinkTarget.adhkarCategories;
        default:
          return null;
      }
    default:
      return null;
  }
}

/// Builds the [Route] matching [target] using the app's existing pages and transitions.
Route<void> buildWidgetDestinationRoute(WidgetDeepLinkTarget target) {
  final settings = RouteSettings(name: target.routeName);
  switch (target) {
    case WidgetDeepLinkTarget.prayer:
      return AppPageRoute.create(const PrayerTimesPage(), settings: settings);
    case WidgetDeepLinkTarget.morningAdhkar:
      return AppPageRoute.create(
        const CategoryListPage(
          categoryTitle: 'أذكار الصباح',
          jsonAssetPath: AppAssets.jsonMorning,
        ),
        settings: settings,
      );
    case WidgetDeepLinkTarget.eveningAdhkar:
      return AppPageRoute.create(
        const CategoryListPage(
          categoryTitle: 'أذكار المساء',
          jsonAssetPath: AppAssets.jsonEvening,
        ),
        settings: settings,
      );
    case WidgetDeepLinkTarget.adhkarCategories:
      return AppPageRoute.create(
        const HomePage(initialIndex: 3),
        settings: settings,
      );
    case WidgetDeepLinkTarget.home:
      return AppPageRoute.create(const HomePage(), settings: settings);
  }
}

/// Tracks the active top route name so widget clicks avoid duplicate pushes and
/// replace `SplashPage` cleanly only when explicitly launched from a widget.
class WidgetRouteObserver extends NavigatorObserver {
  String? currentTopRouteName = Navigator.defaultRouteName;

  void _syncTop(Route<dynamic>? route) {
    currentTopRouteName = route?.settings.name;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _syncTop(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _syncTop(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _syncTop(previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _syncTop(previousRoute);
  }
}

/// Coordinates cold-start and warm-start navigation when the user taps an Android/iOS widget.
class WidgetDeepLinkCoordinator {
  static const Duration duplicateSuppressionWindow = Duration(
    milliseconds: 1500,
  );
  static const int maxNavigatorWaitFrames = 5;

  final GlobalKey<NavigatorState> navigatorKey;
  final WidgetRouteObserver routeObserver;
  final Future<Uri?> Function() _getInitialUri;
  final Stream<Uri?> Function() _clickStream;
  final DateTime Function() _now;

  StreamSubscription<Uri?>? _subscription;
  String? _lastHandledUri;
  DateTime? _lastHandledAt;
  bool _disposed = false;

  WidgetDeepLinkCoordinator({
    required this.navigatorKey,
    required this.routeObserver,
    Future<Uri?> Function()? getInitialUri,
    Stream<Uri?> Function()? clickStream,
    DateTime Function()? nowProvider,
  }) : _getInitialUri =
           getInitialUri ?? HomeWidget.initiallyLaunchedFromHomeWidget,
       _clickStream = clickStream ?? (() => HomeWidget.widgetClicked),
       _now = nowProvider ?? DateTime.now;

  /// Subscribes to warm widget clicks and inspects cold-start launch URI safely.
  Future<void> initialize() async {
    if (_disposed) return;

    await _subscription?.cancel();
    try {
      _subscription = _clickStream().listen(
        (uri) {
          unawaited(handleUri(uri));
        },
        onError: (_) {
          // Ignore platform stream errors in unsupported environments/tests.
        },
      );
    } catch (_) {
      // Safe no-op when home_widget EventChannel is unavailable (e.g., widget tests).
    }

    try {
      final initialUri = await _getInitialUri();
      if (!_disposed && initialUri != null) {
        await handleUri(initialUri);
      }
    } catch (_) {
      // Safe no-op when plugin channel is unavailable; preserves normal SplashPage startup.
    }
  }

  /// Resolves [uri] and navigates once the [NavigatorState] is mounted.
  Future<void> handleUri(Uri? uri, {int remainingFrameRetries = maxNavigatorWaitFrames}) async {
    if (_disposed) return;
    final target = parseWidgetDeepLink(uri);
    if (target == null) return;

    final String uriKey = uri.toString();
    final DateTime currentNow = _now();
    if (_lastHandledUri == uriKey &&
        _lastHandledAt != null &&
        currentNow.difference(_lastHandledAt!) < duplicateSuppressionWindow) {
      return;
    }

    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      if (remainingFrameRetries > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          unawaited(
            handleUri(uri, remainingFrameRetries: remainingFrameRetries - 1),
          );
        });
      }
      return;
    }

    _lastHandledUri = uriKey;
    _lastHandledAt = currentNow;

    final currentTop = routeObserver.currentTopRouteName;
    if (currentTop == target.routeName) {
      return;
    }

    final bool isStillOnSplash =
        currentTop == Navigator.defaultRouteName && !navigator.canPop();

    switch (target) {
      case WidgetDeepLinkTarget.home:
      case WidgetDeepLinkTarget.adhkarCategories:
        if (isStillOnSplash) {
          unawaited(
            navigator.pushReplacement(buildWidgetDestinationRoute(target)),
          );
        } else if (target == WidgetDeepLinkTarget.home &&
            currentTop == '/home') {
          return;
        } else {
          unawaited(
            navigator.pushAndRemoveUntil(
              buildWidgetDestinationRoute(target),
              (_) => false,
            ),
          );
        }
        break;
      case WidgetDeepLinkTarget.prayer:
      case WidgetDeepLinkTarget.morningAdhkar:
      case WidgetDeepLinkTarget.eveningAdhkar:
        if (isStillOnSplash) {
          unawaited(
            navigator.pushReplacement(
              AppPageRoute.create(
                const HomePage(),
                settings: const RouteSettings(name: '/home'),
              ),
            ),
          );
        }
        unawaited(navigator.push(buildWidgetDestinationRoute(target)));
        break;
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    await _subscription?.cancel();
    _subscription = null;
  }
}

