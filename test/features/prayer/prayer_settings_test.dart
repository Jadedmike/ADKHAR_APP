import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:adhkar/features/prayer/data/services/country_method_resolver.dart';
import 'package:adhkar/features/prayer/data/services/prayer_settings_storage.dart';
import 'package:adhkar/features/prayer/domain/entities/prayer_calculation_method.dart';
import 'package:adhkar/features/prayer/domain/entities/prayer_madhab.dart';
import 'package:adhkar/features/prayer/domain/entities/prayer_settings.dart';
import 'package:adhkar/features/prayer/presentation/managers/prayer_settings_manager.dart';

class _InMemoryKeyValueStore implements KeyValueStore {
  final Map<String, String> data = {};
  bool failReads = false;
  bool failWrites = false;
  bool returnFalseOnWrite = false;

  @override
  Future<String?> getString(String key) async {
    if (failReads) {
      throw Exception('Simulated read failure');
    }
    return data[key];
  }

  @override
  Future<bool> setString(String key, String value) async {
    if (failWrites) {
      throw Exception('Simulated write failure');
    }
    if (returnFalseOnWrite) {
      return false;
    }
    data[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    data.remove(key);
    return true;
  }
}

void main() {
  group('PrayerSettings & CountryMethodResolver', () {
    test('defaults match approved Phase 2 configuration', () {
      final defaults = PrayerSettings.defaults();
      expect(defaults.schemaVersion, 1);
      expect(defaults.calculationMode, PrayerCalculationMode.auto);
      expect(defaults.manualMethod, PrayerCalculationMethod.muslimWorldLeague);
      expect(defaults.madhab, PrayerMadhab.shafi);
    });

    test('supports all 12 calculation methods and both madhabs in JSON round-trip', () async {
      final store = _InMemoryKeyValueStore();
      final storage = PrayerSettingsStorage(store: store);

      for (final method in PrayerCalculationMethod.values) {
        for (final madhab in PrayerMadhab.values) {
          final original = PrayerSettings(
            calculationMode: PrayerCalculationMode.manual,
            manualMethod: method,
            madhab: madhab,
          );
          await storage.save(original);
          final loaded = await storage.load();
          expect(loaded, equals(original));
        }
      }

      expect(PrayerCalculationMethod.values.length, 12);
    });

    test('rejects unsupported future schema version and malformed JSON', () async {
      final store = _InMemoryKeyValueStore();
      final storage = PrayerSettingsStorage(store: store);

      store.data[PrayerSettingsStorage.storageKey] = jsonEncode({
        'schemaVersion': 2,
        'calculationMode': 'auto',
        'manualMethod': 'muslim_world_league',
        'madhab': 'shafi',
      });
      expect(
        () => storage.load(),
        throwsA(isA<PrayerSettingsSchemaException>()),
      );

      store.data[PrayerSettingsStorage.storageKey] = '{not valid json';
      expect(
        () => storage.load(),
        throwsA(isA<PrayerSettingsFormatException>()),
      );

      store.data[PrayerSettingsStorage.storageKey] = jsonEncode([1, 2, 3]);
      expect(
        () => storage.load(),
        throwsA(isA<PrayerSettingsFormatException>()),
      );

      expect(await storage.loadOrDefault(), equals(PrayerSettings.defaults()));
    });

    test('storage write failure throws typed exception and does not mutate in-memory state', () async {
      final store = _InMemoryKeyValueStore();
      final storage = PrayerSettingsStorage(store: store);
      final manager = PrayerSettingsManager(storage: storage);

      final initial = PrayerSettings.defaults();
      expect(manager.value, equals(initial));

      store.failWrites = true;
      await expectLater(
        manager.setMadhab(PrayerMadhab.hanafi),
        throwsA(isA<PrayerSettingsWriteException>()),
      );
      expect(manager.value, equals(initial));

      store.failWrites = false;
      store.returnFalseOnWrite = true;
      await expectLater(
        manager.setCalculationMode(PrayerCalculationMode.manual),
        throwsA(isA<PrayerSettingsWriteException>()),
      );
      expect(manager.value, equals(initial));
    });

    test('storage read failure throws typed PrayerSettingsReadException', () async {
      final store = _InMemoryKeyValueStore()..failReads = true;
      final storage = PrayerSettingsStorage(store: store);

      await expectLater(
        storage.load(),
        throwsA(isA<PrayerSettingsReadException>()),
      );
    });

    test('CountryMethodResolver maps supported ISO codes and falls back to MWL', () {
      expect(CountryMethodResolver.resolve('SA'), PrayerCalculationMethod.ummAlQura);
      expect(CountryMethodResolver.resolve(' ae '), PrayerCalculationMethod.dubai);
      expect(CountryMethodResolver.resolve('KW'), PrayerCalculationMethod.kuwait);
      expect(CountryMethodResolver.resolve('QA'), PrayerCalculationMethod.qatar);
      expect(CountryMethodResolver.resolve('EG'), PrayerCalculationMethod.egyptian);
      expect(CountryMethodResolver.resolve('PK'), PrayerCalculationMethod.karachi);
      expect(CountryMethodResolver.resolve('TR'), PrayerCalculationMethod.turkey);
      expect(CountryMethodResolver.resolve('IR'), PrayerCalculationMethod.tehran);
      expect(CountryMethodResolver.resolve('SG'), PrayerCalculationMethod.singapore);
      expect(CountryMethodResolver.resolve('MY'), PrayerCalculationMethod.singapore);
      expect(CountryMethodResolver.resolve('ID'), PrayerCalculationMethod.singapore);
      expect(CountryMethodResolver.resolve('BN'), PrayerCalculationMethod.singapore);

      // Unsupported / missing / invalid country codes fall back to MWL
      expect(CountryMethodResolver.resolve('US'), PrayerCalculationMethod.muslimWorldLeague);
      expect(CountryMethodResolver.resolve('GB'), PrayerCalculationMethod.muslimWorldLeague);
      expect(CountryMethodResolver.resolve(''), PrayerCalculationMethod.muslimWorldLeague);
      expect(CountryMethodResolver.resolve(null), PrayerCalculationMethod.muslimWorldLeague);
      expect(CountryMethodResolver.resolve('TUR'), PrayerCalculationMethod.muslimWorldLeague);
    });

    test('manual selection overrides automatic country resolution', () {
      const manualSettings = PrayerSettings(
        calculationMode: PrayerCalculationMode.manual,
        manualMethod: PrayerCalculationMethod.egyptian,
        madhab: PrayerMadhab.shafi,
      );
      expect(
        CountryMethodResolver.resolveEffective(
          manualSettings,
          isoCountryCode: 'TR',
        ),
        PrayerCalculationMethod.egyptian,
      );

      const autoSettings = PrayerSettings(
        calculationMode: PrayerCalculationMode.auto,
        manualMethod: PrayerCalculationMethod.egyptian,
        madhab: PrayerMadhab.shafi,
      );
      expect(
        CountryMethodResolver.resolveEffective(
          autoSettings,
          isoCountryCode: 'TR',
        ),
        PrayerCalculationMethod.turkey,
      );
    });
  });
}

