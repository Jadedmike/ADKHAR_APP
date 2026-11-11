import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:adhkar/config/theme/app_theme.dart';
import 'package:adhkar/core/navigation/widget_deep_link_handler.dart';
import 'package:adhkar/core/services/home_widget_sync_service.dart';
import 'package:adhkar/core/services/notification_service.dart';
import 'package:adhkar/features/adhkar/presentation/managers/favorites_manager.dart';
import 'package:adhkar/features/adhkar/presentation/managers/settings_manager.dart';
import 'package:adhkar/features/adhkar/presentation/pages/splash_page.dart';
import 'package:adhkar/features/prayer/presentation/managers/prayer_notification_manager.dart';

import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar', null);
  await SettingsManager.init();
  await FavoritesManager.init();
  await NotificationService.init();
  unawaited(PrayerNotificationManager.instance.syncOnStartup());
  unawaited(HomeWidgetSyncService.instance.initializeAndSync());
  runApp(const AdhkarApp());
}

class AdhkarApp extends StatefulWidget {
  const AdhkarApp({super.key});

  @override
  State<AdhkarApp> createState() => _AdhkarAppState();
}

class _AdhkarAppState extends State<AdhkarApp> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final WidgetRouteObserver _routeObserver = WidgetRouteObserver();
  late final WidgetDeepLinkCoordinator _deepLinkCoordinator;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _deepLinkCoordinator = WidgetDeepLinkCoordinator(
      navigatorKey: _navigatorKey,
      routeObserver: _routeObserver,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_deepLinkCoordinator.initialize());
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_deepLinkCoordinator.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(HomeWidgetSyncService.instance.sync());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: SettingsManager.themeModeOption,
      builder: (context, themeOpt, child) {
        return MaterialApp(
          title: 'Adhkar',
          navigatorKey: _navigatorKey,
          navigatorObservers: [_routeObserver],
          debugShowCheckedModeBanner: false,

          // Material 3 Themes & Dynamic Theme Mode
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: SettingsManager.themeMode,

          // Localization: RTL Arabic by default and Arabic only
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          home: const SplashPage(),

          builder: (context, child) {
            return MediaQuery.withClampedTextScaling(
              minScaleFactor: 0.9,
              maxScaleFactor: 1.2,
              child: child!,
            );
          },
        );
      },
    );
  }
}
