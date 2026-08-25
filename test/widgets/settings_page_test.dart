import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adhkar/features/adhkar/presentation/managers/settings_manager.dart';
import 'package:adhkar/features/adhkar/presentation/pages/settings_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsManager.init();
  });

  testWidgets('SettingsPage - morning and evening time pickers show when ON and hide when OFF', (WidgetTester tester) async {
    SettingsManager.morningReminder.value = true;
    SettingsManager.eveningReminder.value = true;

    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('ar')],
        home: SettingsPage(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify time pickers are present when toggles are ON
    expect(find.text('وقت تذكير الصباح'), findsOneWidget);
    expect(find.text('وقت تذكير المساء'), findsOneWidget);

    // Turn OFF evening reminder toggle
    SettingsManager.eveningReminder.value = false;
    await tester.pumpAndSettle();

    // Verify evening time picker disappears immediately while morning time picker remains
    expect(find.text('وقت تذكير الصباح'), findsOneWidget);
    expect(find.text('وقت تذكير المساء'), findsNothing);

    // Turn OFF morning reminder toggle
    SettingsManager.morningReminder.value = false;
    await tester.pumpAndSettle();

    // Verify morning time picker disappears as well
    expect(find.text('وقت تذكير الصباح'), findsNothing);
    expect(find.text('وقت تذكير المساء'), findsNothing);

    // Turn evening reminder back ON
    SettingsManager.eveningReminder.value = true;
    await tester.pumpAndSettle();

    // Verify evening time picker reappears
    expect(find.text('وقت تذكير الصباح'), findsNothing);
    expect(find.text('وقت تذكير المساء'), findsOneWidget);
  });
}
