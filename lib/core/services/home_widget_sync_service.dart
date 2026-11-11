import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import '../../config/theme/app_assets.dart';
import '../../features/adhkar/presentation/managers/settings_manager.dart';
import '../../features/prayer/data/services/country_method_resolver.dart';
import '../../features/prayer/data/services/prayer_location_cache_service.dart';
import '../../features/prayer/data/services/prayer_times_calculator.dart';
import '../../features/prayer/domain/entities/prayer_calculation_method.dart';
import '../../features/prayer/domain/entities/prayer_madhab.dart';
import '../../features/prayer/domain/entities/prayer_settings.dart';
import '../../features/prayer/domain/entities/saved_prayer_location.dart';
import '../../features/prayer/presentation/managers/prayer_settings_manager.dart';
import '../utils/daily_content_helper.dart';
import 'home_widget_snapshot.dart';

/// Outcome status of a [HomeWidgetSyncService.sync] call.
enum WidgetSyncStatus {
  updated,
  partialWrite,
  skippedDuplicate,
  preservedPreviousOnError,
  failed,
}

/// Structured result describing what [HomeWidgetSyncService.sync] published or preserved.
class WidgetSyncResult {
  final WidgetSyncStatus status;
  final WidgetSnapshot? snapshot;
  final String? errorMessage;
  final Object? error;

  const WidgetSyncResult({
    required this.status,
    this.snapshot,
    this.errorMessage,
    this.error,
  });

  bool get didWrite =>
      status == WidgetSyncStatus.updated ||
      status == WidgetSyncStatus.partialWrite;
}

/// Result returned by [WidgetTransport.writeSnapshotData] to distinguish total
/// persistence failure from a partial write where `snapshotKey` succeeded but
/// `schemaVersionKey` failed.
class WidgetWriteResult {
  final bool snapshotPersisted;
  final bool schemaVersionPersisted;
  final String? errorMessage;

  const WidgetWriteResult({
    required this.snapshotPersisted,
    required this.schemaVersionPersisted,
    this.errorMessage,
  });

  bool get isFullSuccess => snapshotPersisted && schemaVersionPersisted;
  bool get isPartialWrite => snapshotPersisted && !schemaVersionPersisted;
}

/// Current Adhkar & UI preference state read by [HomeWidgetSyncService].
class WidgetAdhkarRuntimePreferences {
  final String themeModeLabel;
  final TimeOfDay morningTime;
  final TimeOfDay eveningTime;
  final bool morningReminderEnabled;
  final bool eveningReminderEnabled;

  const WidgetAdhkarRuntimePreferences({
    required this.themeModeLabel,
    required this.morningTime,
    required this.eveningTime,
    required this.morningReminderEnabled,
    required this.eveningReminderEnabled,
  });

  factory WidgetAdhkarRuntimePreferences.fromSettingsManager() {
    return WidgetAdhkarRuntimePreferences(
      themeModeLabel: SettingsManager.themeModeOption.value,
      morningTime: SettingsManager.morningTime.value,
      eveningTime: SettingsManager.eveningTime.value,
      morningReminderEnabled: SettingsManager.morningReminder.value,
      eveningReminderEnabled: SettingsManager.eveningReminder.value,
    );
  }
}

/// Bridge abstraction over `package:home_widget` key-value storage and widget reloads.
abstract class WidgetTransport {
  Future<void> initialize({required String appGroupId});

  Future<String?> readSnapshotJson(String snapshotKey);

  Future<WidgetWriteResult> writeSnapshotData({
    required String snapshotKey,
    required String snapshotJson,
    required String schemaVersionKey,
    required int schemaVersion,
  });

  Future<void> requestWidgetUpdates();
}

/// Thin static wrapper over [HomeWidget] calls to enable deterministic transport tests.
class HomeWidgetPluginAdapter {
  const HomeWidgetPluginAdapter();

  Future<bool?> setAppGroupId(String groupId) =>
      HomeWidget.setAppGroupId(groupId);

  Future<T?> getWidgetData<T>(String id) => HomeWidget.getWidgetData<T>(id);

  Future<bool?> saveWidgetData<T>(String id, T? data) =>
      HomeWidget.saveWidgetData<T>(id, data);

  Future<bool?> updateWidget({
    String? qualifiedAndroidName,
    String? iOSName,
  }) => HomeWidget.updateWidget(
    qualifiedAndroidName: qualifiedAndroidName,
    iOSName: iOSName,
  );
}

/// Default `package:home_widget` transport backed by shared Android SharedPreferences
/// (`HomeWidgetPreferences`) and iOS App Group `UserDefaults`.
class HomeWidgetPlatformTransport implements WidgetTransport {
  static const List<({String qualifiedAndroidName, String iOSName})>
  plannedProviders = [
    (
      qualifiedAndroidName:
          'com.adhkar.adkhar.widget.AdhkarHomeWidgetProvider',
      iOSName: 'AdhkarWidget',
    ),
    (
      qualifiedAndroidName:
          'com.adhkar.adkhar.widget.PrayerTimesWidgetProvider',
      iOSName: 'PrayerTimesWidget',
    ),
    (
      qualifiedAndroidName: 'com.adhkar.adkhar.widget.CombinedWidgetProvider',
      iOSName: 'CombinedWidget',
    ),
  ];

  final HomeWidgetPluginAdapter _plugin;
  final TargetPlatform? _platformOverride;
  bool _appGroupConfigured = false;

  HomeWidgetPlatformTransport({
    HomeWidgetPluginAdapter? plugin,
    TargetPlatform? platformOverride,
  }) : _plugin = plugin ?? const HomeWidgetPluginAdapter(),
       _platformOverride = platformOverride;

  @override
  Future<void> initialize({required String appGroupId}) async {
    if (_appGroupConfigured || kIsWeb) return;
    final platform = _platformOverride ?? defaultTargetPlatform;
    if (platform != TargetPlatform.iOS) {
      _appGroupConfigured = true;
      return;
    }
    try {
      await _plugin.setAppGroupId(appGroupId);
      _appGroupConfigured = true;
    } catch (_) {
      // Non-fatal in environments without iOS App Group plugin wiring yet.
    }
  }

  @override
  Future<String?> readSnapshotJson(String snapshotKey) async {
    try {
      return await _plugin.getWidgetData<String>(snapshotKey);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<WidgetWriteResult> writeSnapshotData({
    required String snapshotKey,
    required String snapshotJson,
    required String schemaVersionKey,
    required int schemaVersion,
  }) async {
    bool? savedVersion;
    try {
      savedVersion = await _plugin.saveWidgetData<int>(
        schemaVersionKey,
        schemaVersion,
      );
    } catch (error) {
      return WidgetWriteResult(
        snapshotPersisted: false,
        schemaVersionPersisted: false,
        errorMessage: 'Failed to persist schema version metadata: $error',
      );
    }

    // Abort before modifying the snapshot if metadata write explicitly returned false.
    if (savedVersion == false) {
      return const WidgetWriteResult(
        snapshotPersisted: false,
        schemaVersionPersisted: false,
        errorMessage: 'Schema version persistence returned false.',
      );
    }

    bool? savedJson;
    try {
      savedJson = await _plugin.saveWidgetData<String>(
        snapshotKey,
        snapshotJson,
      );
    } catch (error) {
      return WidgetWriteResult(
        snapshotPersisted: false,
        schemaVersionPersisted: true,
        errorMessage: 'Failed to persist widget snapshot JSON: $error',
      );
    }

    if (savedJson == false) {
      return const WidgetWriteResult(
        snapshotPersisted: false,
        schemaVersionPersisted: true,
        errorMessage: 'Widget snapshot JSON persistence returned false.',
      );
    }

    return const WidgetWriteResult(
      snapshotPersisted: true,
      schemaVersionPersisted: true,
    );
  }

  @override
  Future<void> requestWidgetUpdates() async {
    for (final provider in plannedProviders) {
      try {
        await _plugin.updateWidget(
          qualifiedAndroidName: provider.qualifiedAndroidName,
          iOSName: provider.iOSName,
        );
      } catch (_) {
        // Safe no-op before native widget receivers / WidgetKit bundle exist.
      }
    }
  }
}

/// Builds, validates, deduplicates, and publishes shared widget snapshots
/// using only existing Adhkar and Prayer services (no GPS, no background loops).
class HomeWidgetSyncService {
  static const String iosAppGroupId = 'group.com.adhkar.adkhar';
  static const String snapshotStorageKey = 'adhkar_widget_snapshot_v1_json';
  static const String schemaVersionStorageKey = 'adhkar_widget_schema_version';

  final WidgetTransport _transport;
  final PrayerLocationCacheService _locationCache;
  final PrayerSettingsManager _prayerSettingsManager;
  final PrayerTimesCalculator _calculator;
  final Future<String> Function(String assetPath) _assetLoader;
  final DateTime Function() _now;
  final WidgetAdhkarRuntimePreferences Function() _preferencesReader;

  String? _lastPublishedSemanticSignature;
  List<WidgetPeriodDhikrItem>? _cachedMorningAdhkar;
  List<WidgetPeriodDhikrItem>? _cachedEveningAdhkar;

  bool _isSyncing = false;
  bool _followUpRequested = false;
  bool _followUpForce = false;
  Completer<WidgetSyncResult>? _followUpCompleter;
  bool _listenersAttached = false;

  HomeWidgetSyncService({
    WidgetTransport? transport,
    PrayerLocationCacheService? locationCache,
    PrayerSettingsManager? prayerSettingsManager,
    PrayerTimesCalculator? calculator,
    Future<String> Function(String assetPath)? assetLoader,
    DateTime Function()? nowProvider,
    WidgetAdhkarRuntimePreferences Function()? preferencesReader,
  }) : _transport = transport ?? HomeWidgetPlatformTransport(),
       _locationCache = locationCache ?? PrayerLocationCacheService.instance,
       _prayerSettingsManager =
           prayerSettingsManager ?? PrayerSettingsManager.instance,
       _calculator = calculator ?? PrayerTimesCalculator.instance,
       _assetLoader = assetLoader ?? rootBundle.loadString,
       _now = nowProvider ?? DateTime.now,
       _preferencesReader =
           preferencesReader ??
           WidgetAdhkarRuntimePreferences.fromSettingsManager;

  static final HomeWidgetSyncService instance = HomeWidgetSyncService();

  /// Loads prayer settings, attaches reactive change listeners, and performs initial sync.
  Future<WidgetSyncResult> initializeAndSync() async {
    try {
      await _prayerSettingsManager.loadSafely();
    } catch (_) {
      // Safe fallback to defaults already held in manager.
    }
    attachListeners();
    return sync();
  }

  /// Attaches idempotent listeners for location, prayer settings, Adhkar cutoffs, and theme.
  void attachListeners() {
    if (_listenersAttached) return;
    _listenersAttached = true;

    _locationCache.revision.addListener(_onReactiveChange);
    _prayerSettingsManager.current.addListener(_onReactiveChange);
    SettingsManager.themeModeOption.addListener(_onReactiveChange);
    SettingsManager.morningTime.addListener(_onReactiveChange);
    SettingsManager.eveningTime.addListener(_onReactiveChange);
    SettingsManager.morningReminder.addListener(_onReactiveChange);
    SettingsManager.eveningReminder.addListener(_onReactiveChange);
  }

  /// Detaches listeners (primarily for tests or controlled teardown).
  void detachListeners() {
    if (!_listenersAttached) return;
    _listenersAttached = false;

    _locationCache.revision.removeListener(_onReactiveChange);
    _prayerSettingsManager.current.removeListener(_onReactiveChange);
    SettingsManager.themeModeOption.removeListener(_onReactiveChange);
    SettingsManager.morningTime.removeListener(_onReactiveChange);
    SettingsManager.eveningTime.removeListener(_onReactiveChange);
    SettingsManager.morningReminder.removeListener(_onReactiveChange);
    SettingsManager.eveningReminder.removeListener(_onReactiveChange);
  }

  void _onReactiveChange() {
    unawaited(sync());
  }

  /// Computes, validates, deduplicates, and writes the shared widget snapshot.
  ///
  /// Concurrent calls never overlap: any update arriving while a sync is in
  /// flight triggers one coalesced follow-up sync after the active run finishes.
  Future<WidgetSyncResult> sync({bool force = false}) {
    if (!_isSyncing) {
      return _runSyncLoop(initialForce: force);
    }

    _followUpRequested = true;
    _followUpForce = _followUpForce || force;
    final completer = _followUpCompleter ??= Completer<WidgetSyncResult>();
    return completer.future;
  }

  Future<WidgetSyncResult> _runSyncLoop({required bool initialForce}) async {
    _isSyncing = true;
    try {
      final WidgetSyncResult firstResult = await _performSyncSafe(
        force: initialForce,
      );

      while (_followUpRequested) {
        final followUpForce = _followUpForce;
        final followUpCompleter = _followUpCompleter;
        _followUpRequested = false;
        _followUpForce = false;
        _followUpCompleter = null;

        final followUpResult = await _performSyncSafe(force: followUpForce);
        if (followUpCompleter != null && !followUpCompleter.isCompleted) {
          followUpCompleter.complete(followUpResult);
        }
      }

      return firstResult;
    } finally {
      final remainingCompleter = _followUpCompleter;
      _followUpRequested = false;
      _followUpForce = false;
      _followUpCompleter = null;
      _isSyncing = false;
      if (remainingCompleter != null && !remainingCompleter.isCompleted) {
        remainingCompleter.complete(
          const WidgetSyncResult(
            status: WidgetSyncStatus.failed,
            errorMessage: 'Widget sync aborted unexpectedly.',
          ),
        );
      }
    }
  }

  Future<WidgetSyncResult> _performSyncSafe({required bool force}) async {
    try {
      return await _performSync(force: force);
    } catch (error) {
      return WidgetSyncResult(
        status: WidgetSyncStatus.failed,
        errorMessage: 'Unexpected error during widget sync.',
        error: error,
      );
    }
  }

  Future<WidgetSyncResult> _performSync({required bool force}) async {
    await _transport.initialize(appGroupId: iosAppGroupId);

    final DateTime nowLocal = _now().toLocal();
    final DateTime todayLocal = DateTime(
      nowLocal.year,
      nowLocal.month,
      nowLocal.day,
    );

    final WidgetAdhkarRuntimePreferences prefs = _preferencesReader();
    final String themePreference = _mapThemePreference(prefs.themeModeLabel);
    final WidgetAdhkarCutoffs cutoffs = _buildCutoffs(prefs);

    final List<WidgetDailyAdhkarDay> dailyAdhkarDays = _buildDailyAdhkarHorizon(
      todayLocal,
    );
    final List<WidgetPeriodDhikrItem> morningAdhkar = await _loadPeriodAdhkar(
      assetPath: AppAssets.jsonMorning,
      cached: _cachedMorningAdhkar,
      onLoaded: (items) => _cachedMorningAdhkar = items,
    );
    final List<WidgetPeriodDhikrItem> eveningAdhkar = await _loadPeriodAdhkar(
      assetPath: AppAssets.jsonEvening,
      cached: _cachedEveningAdhkar,
      onLoaded: (items) => _cachedEveningAdhkar = items,
    );

    final SavedPrayerLocation? savedLocation = await _locationCache.load();
    final bool hasLocation =
        savedLocation != null && savedLocation.hasValidCoordinates;

    final WidgetSnapshot snapshot;
    if (!hasLocation) {
      snapshot = WidgetSnapshot(
        generatedAtUtcEpochMs: nowLocal.toUtc().millisecondsSinceEpoch,
        hasSavedLocation: false,
        prayerDataAvailable: false,
        themePreference: themePreference,
        themeModeLabel: prefs.themeModeLabel,
        location: const WidgetLocationInfo(hasSavedLocation: false),
        cutoffs: cutoffs,
        dailyAdhkarDays: dailyAdhkarDays,
        morningAdhkar: morningAdhkar,
        eveningAdhkar: eveningAdhkar,
        prayerDays: const [],
      );
    } else {
      final PrayerSettings prayerSettings = _prayerSettingsManager.value;
      final PrayerCalculationMethod effectiveMethod =
          CountryMethodResolver.resolveEffective(
            prayerSettings,
            isoCountryCode: savedLocation.isoCountryCode,
          );
      final String locationFingerprint =
          WidgetSnapshot.computeLocationFingerprint(
            latitude: savedLocation.latitude,
            longitude: savedLocation.longitude,
            isoCountryCode: savedLocation.isoCountryCode,
          );

      try {
        final List<WidgetPrayerDaySchedule> prayerDays = [];

        for (int offset = 0; offset < WidgetSnapshot.horizonDays; offset++) {
          final targetDate = DateTime(
            todayLocal.year,
            todayLocal.month,
            todayLocal.day + offset,
          );
          final dailyTimes = _calculator.calculate(
            latitude: savedLocation.latitude,
            longitude: savedLocation.longitude,
            settings: prayerSettings,
            isoCountryCode: savedLocation.isoCountryCode,
            localDate: targetDate,
          );
          prayerDays.add(
            WidgetPrayerDaySchedule.fromDailyPrayerTimes(
              dailyTimes,
              WidgetSnapshot.formatLocalDate(targetDate),
            ),
          );
        }

        snapshot = WidgetSnapshot(
          generatedAtUtcEpochMs: nowLocal.toUtc().millisecondsSinceEpoch,
          hasSavedLocation: true,
          prayerDataAvailable: true,
          themePreference: themePreference,
          themeModeLabel: prefs.themeModeLabel,
          location: WidgetLocationInfo(
            hasSavedLocation: true,
            locationFingerprint: locationFingerprint,
            displayName: savedLocation.displayName,
            isoCountryCode: savedLocation.isoCountryCode,
            calculationMethodKey: effectiveMethod.storageKey,
            calculationMethodLabel: effectiveMethod.arabicName,
            madhabKey: prayerSettings.madhab.storageKey,
            madhabLabel: prayerSettings.madhab.arabicName,
          ),
          cutoffs: cutoffs,
          dailyAdhkarDays: dailyAdhkarDays,
          morningAdhkar: morningAdhkar,
          eveningAdhkar: eveningAdhkar,
          prayerDays: prayerDays,
        );
        snapshot.validate();
      } catch (error) {
        return _handleCalculationFailure(
          nowLocal: nowLocal,
          todayLocal: todayLocal,
          savedLocation: savedLocation,
          expectedFingerprint: locationFingerprint,
          expectedMethod: effectiveMethod,
          expectedMadhab: prayerSettings.madhab,
          themePreference: themePreference,
          themeModeLabel: prefs.themeModeLabel,
          cutoffs: cutoffs,
          dailyAdhkarDays: dailyAdhkarDays,
          morningAdhkar: morningAdhkar,
          eveningAdhkar: eveningAdhkar,
          error: error,
          force: force,
        );
      }
    }

    return _publishSnapshot(snapshot: snapshot, force: force);
  }

  Future<WidgetSyncResult> _publishSnapshot({
    required WidgetSnapshot snapshot,
    required bool force,
    WidgetSyncStatus successStatus = WidgetSyncStatus.updated,
    String? overrideErrorMessage,
    Object? overrideError,
  }) async {
    final String encodedSnapshot;
    try {
      encodedSnapshot = snapshot.toEncodedJson();
    } catch (error) {
      return WidgetSyncResult(
        status: WidgetSyncStatus.failed,
        errorMessage: 'Widget snapshot validation failed before publishing.',
        error: error,
      );
    }

    final String semanticSignature = snapshot.toSemanticSignatureJson();
    if (!force && await _matchesExistingSignature(semanticSignature)) {
      _lastPublishedSemanticSignature = semanticSignature;
      return WidgetSyncResult(
        status: successStatus == WidgetSyncStatus.preservedPreviousOnError
            ? WidgetSyncStatus.preservedPreviousOnError
            : WidgetSyncStatus.skippedDuplicate,
        snapshot: snapshot,
        errorMessage: overrideErrorMessage,
        error: overrideError,
      );
    }

    final WidgetWriteResult writeResult = await _transport.writeSnapshotData(
      snapshotKey: snapshotStorageKey,
      snapshotJson: encodedSnapshot,
      schemaVersionKey: schemaVersionStorageKey,
      schemaVersion: WidgetSnapshot.currentSchemaVersion,
    );

    if (!writeResult.snapshotPersisted) {
      return WidgetSyncResult(
        status: WidgetSyncStatus.failed,
        errorMessage:
            writeResult.errorMessage ??
            'Failed to persist widget snapshot to shared storage.',
        error: overrideError,
      );
    }

    // Whenever the snapshot JSON itself was written (even in a partial write
    // where schemaVersionKey failed), keep our semantic cache aligned and notify
    // native widgets so they never stay permanently stale.
    _lastPublishedSemanticSignature = semanticSignature;
    await _transport.requestWidgetUpdates();

    if (writeResult.isPartialWrite) {
      return WidgetSyncResult(
        status: WidgetSyncStatus.partialWrite,
        snapshot: snapshot,
        errorMessage:
            writeResult.errorMessage ??
            'Snapshot JSON persisted, but schema version key write failed.',
        error: overrideError,
      );
    }

    return WidgetSyncResult(
      status: successStatus,
      snapshot: snapshot,
      errorMessage: overrideErrorMessage,
      error: overrideError,
    );
  }

  Future<bool> _matchesExistingSignature(String candidateSignature) async {
    if (_lastPublishedSemanticSignature == candidateSignature) {
      return true;
    }
    if (_lastPublishedSemanticSignature != null) {
      return false;
    }
    final existingRaw = await _transport.readSnapshotJson(snapshotStorageKey);
    final existingSnapshot = WidgetSnapshot.tryFromEncodedJson(existingRaw);
    if (existingSnapshot == null) {
      return false;
    }
    final existingSignature = existingSnapshot.toSemanticSignatureJson();
    _lastPublishedSemanticSignature = existingSignature;
    return existingSignature == candidateSignature;
  }

  bool _isExistingSnapshotSafeToPreserve({
    required WidgetSnapshot? existingSnapshot,
    required DateTime nowLocal,
    required DateTime todayLocal,
    required String expectedFingerprint,
    required PrayerCalculationMethod expectedMethod,
    required PrayerMadhab expectedMadhab,
  }) {
    if (existingSnapshot == null) return false;
    if (!existingSnapshot.hasSavedLocation ||
        !existingSnapshot.prayerDataAvailable) {
      return false;
    }
    if (!existingSnapshot.coversLocalDate(todayLocal)) {
      return false;
    }
    if (!existingSnapshot.isFreshAt(nowLocal)) {
      return false;
    }

    final loc = existingSnapshot.location;
    if (loc.locationFingerprint == null ||
        loc.locationFingerprint != expectedFingerprint) {
      return false;
    }
    if (loc.calculationMethodKey == null ||
        loc.calculationMethodKey != expectedMethod.storageKey) {
      return false;
    }
    if (loc.madhabKey == null || loc.madhabKey != expectedMadhab.storageKey) {
      return false;
    }
    return true;
  }

  Future<WidgetSyncResult> _handleCalculationFailure({
    required DateTime nowLocal,
    required DateTime todayLocal,
    required SavedPrayerLocation savedLocation,
    required String expectedFingerprint,
    required PrayerCalculationMethod expectedMethod,
    required PrayerMadhab expectedMadhab,
    required String themePreference,
    required String themeModeLabel,
    required WidgetAdhkarCutoffs cutoffs,
    required List<WidgetDailyAdhkarDay> dailyAdhkarDays,
    required List<WidgetPeriodDhikrItem> morningAdhkar,
    required List<WidgetPeriodDhikrItem> eveningAdhkar,
    required Object error,
    required bool force,
  }) async {
    final existingRaw = await _transport.readSnapshotJson(snapshotStorageKey);
    final existingSnapshot = WidgetSnapshot.tryFromEncodedJson(existingRaw);

    if (_isExistingSnapshotSafeToPreserve(
      existingSnapshot: existingSnapshot,
      nowLocal: nowLocal,
      todayLocal: todayLocal,
      expectedFingerprint: expectedFingerprint,
      expectedMethod: expectedMethod,
      expectedMadhab: expectedMadhab,
    )) {
      final preservedWithFreshNonPrayer = existingSnapshot!
          .copyWithRefreshedNonPrayerFields(
            themePreference: themePreference,
            themeModeLabel: themeModeLabel,
            cutoffs: cutoffs,
            dailyAdhkarDays: dailyAdhkarDays,
            morningAdhkar: morningAdhkar,
            eveningAdhkar: eveningAdhkar,
          );

      final publishResult = await _publishSnapshot(
        snapshot: preservedWithFreshNonPrayer,
        force: force,
        successStatus: WidgetSyncStatus.preservedPreviousOnError,
        overrideErrorMessage:
            'Prayer calculation failed; preserved validated previous prayer snapshot.',
        overrideError: error,
      );

      if (publishResult.status == WidgetSyncStatus.failed) {
        return publishResult;
      }
      return WidgetSyncResult(
        status: WidgetSyncStatus.preservedPreviousOnError,
        snapshot: preservedWithFreshNonPrayer,
        errorMessage:
            publishResult.errorMessage ??
            'Prayer calculation failed; preserved validated previous prayer snapshot.',
        error: error,
      );
    }

    // Unsafe to preserve stale prayer data (mismatch in location, method,
    // madhab, missing identity metadata, expired age, or missing prior snapshot):
    // clear stale prayer schedules while preserving fresh non-prayer Adhkar/theme.
    final safeFallback = WidgetSnapshot(
      generatedAtUtcEpochMs: nowLocal.toUtc().millisecondsSinceEpoch,
      hasSavedLocation: true,
      prayerDataAvailable: false,
      prayerUnavailablePrompt: WidgetSnapshot.prayerUnavailableArabicPrompt,
      themePreference: themePreference,
      themeModeLabel: themeModeLabel,
      location: WidgetLocationInfo(
        hasSavedLocation: true,
        locationFingerprint: expectedFingerprint,
        displayName: savedLocation.displayName,
        isoCountryCode: savedLocation.isoCountryCode,
        calculationMethodKey: expectedMethod.storageKey,
        calculationMethodLabel: expectedMethod.arabicName,
        madhabKey: expectedMadhab.storageKey,
        madhabLabel: expectedMadhab.arabicName,
      ),
      cutoffs: cutoffs,
      dailyAdhkarDays: dailyAdhkarDays,
      morningAdhkar: morningAdhkar,
      eveningAdhkar: eveningAdhkar,
      prayerDays: const [],
    );

    await _publishSnapshot(snapshot: safeFallback, force: force);

    return WidgetSyncResult(
      status: WidgetSyncStatus.failed,
      snapshot: safeFallback,
      errorMessage:
          'Prayer calculation failed and previous prayer snapshot could not be safely preserved.',
      error: error,
    );
  }

  List<WidgetDailyAdhkarDay> _buildDailyAdhkarHorizon(DateTime todayLocal) {
    final days = <WidgetDailyAdhkarDay>[];
    for (int offset = 0; offset < WidgetSnapshot.horizonDays; offset++) {
      final date = DateTime(
        todayLocal.year,
        todayLocal.month,
        todayLocal.day + offset,
      );
      final dhikr = DailyContentHelper.getDhikrOfTheDay(date);
      final dua = DailyContentHelper.getDuaOfTheDay(date);
      final ayah = DailyContentHelper.getAyahOfTheDay(date);
      final quote = DailyContentHelper.getQuoteOfTheDay(date);

      days.add(
        WidgetDailyAdhkarDay(
          localDate: WidgetSnapshot.formatLocalDate(date),
          dhikr: _toWidgetTextItem(dhikr),
          dua: _toWidgetTextItem(dua),
          ayah: _toWidgetTextItem(ayah),
          quote: _toWidgetTextItem(quote),
        ),
      );
    }
    return days;
  }

  static WidgetTextItem _toWidgetTextItem(DailyContentItem item) {
    return WidgetTextItem(
      text: item.text,
      source: item.source,
      categoryTitle: item.categoryTitle,
    );
  }

  Future<List<WidgetPeriodDhikrItem>> _loadPeriodAdhkar({
    required String assetPath,
    required List<WidgetPeriodDhikrItem>? cached,
    required void Function(List<WidgetPeriodDhikrItem> items) onLoaded,
  }) async {
    if (cached != null) return cached;
    try {
      final jsonString = await _assetLoader(assetPath);
      final parsed = jsonDecode(jsonString);
      if (parsed is! List) return const [];

      final items = <WidgetPeriodDhikrItem>[];
      for (int i = 0; i < parsed.length; i++) {
        final raw = parsed[i];
        if (raw is! Map) continue;
        final text = (raw['content'] ?? raw['text'] ?? raw['dhikr'] ?? '')
            .toString()
            .trim();
        if (text.isEmpty) continue;

        final id = (raw['id'] ?? 'item_$i').toString().trim();
        final rawOrder = raw['order'];
        final order = rawOrder is int
            ? rawOrder
            : int.tryParse(rawOrder?.toString() ?? '') ?? (i + 1);
        final rawCount = raw['count'];
        final parsedCount = rawCount is int
            ? rawCount
            : int.tryParse(rawCount?.toString() ?? '') ?? 1;
        final count = parsedCount < 1 ? 1 : parsedCount;
        final source = (raw['source'] ?? '').toString().trim();
        final countDesc = (raw['count_description'] ?? '').toString().trim();

        items.add(
          WidgetPeriodDhikrItem(
            id: id.isEmpty ? 'item_$i' : id,
            order: order,
            text: text,
            source: source,
            count: count,
            countDescription: countDesc,
          ),
        );
      }

      if (items.isNotEmpty) {
        onLoaded(items);
      }
      return items;
    } catch (_) {
      return const [];
    }
  }

  static WidgetAdhkarCutoffs _buildCutoffs(
    WidgetAdhkarRuntimePreferences prefs,
  ) {
    final morningMinutes =
        (prefs.morningTime.hour * 60) + prefs.morningTime.minute;
    final eveningMinutes =
        (prefs.eveningTime.hour * 60) + prefs.eveningTime.minute;
    return WidgetAdhkarCutoffs(
      morningStartMinutes: morningMinutes,
      eveningStartMinutes: eveningMinutes,
      morningStartFormatted: _formatTimeOfDay(prefs.morningTime),
      eveningStartFormatted: _formatTimeOfDay(prefs.eveningTime),
      morningReminderEnabled: prefs.morningReminderEnabled,
      eveningReminderEnabled: prefs.eveningReminderEnabled,
    );
  }

  static String _formatTimeOfDay(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String _mapThemePreference(String option) {
    switch (option) {
      case 'داكن':
        return 'dark';
      case 'تكيّف حسب النظام':
        return 'system';
      case 'فاتح':
      default:
        return 'light';
    }
  }
}
