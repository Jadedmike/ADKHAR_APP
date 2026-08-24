import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:adhkar/config/theme/app_theme.dart';
import 'package:adhkar/core/services/notification_service.dart';
import 'package:adhkar/features/adhkar/presentation/managers/favorites_manager.dart';
import 'package:adhkar/features/adhkar/presentation/managers/settings_manager.dart';
import 'package:adhkar/features/adhkar/presentation/pages/splash_page.dart';

import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar', null);
  await SettingsManager.init();
  await FavoritesManager.init();
  await NotificationService.init();
  runApp(const AdhkarApp());
}

class AdhkarApp extends StatelessWidget {
  const AdhkarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: SettingsManager.themeModeOption,
      builder: (context, themeOpt, child) {
        return MaterialApp(
          title: 'Adhkar',
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
