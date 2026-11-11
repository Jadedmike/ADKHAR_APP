import 'prayer_calculation_method.dart';
import 'prayer_madhab.dart';

/// Whether prayer calculation method is chosen automatically by country or manually by the user.
enum PrayerCalculationMode {
  auto(storageKey: 'auto', arabicName: 'تلقائي حسب البلد'),
  manual(storageKey: 'manual', arabicName: 'يدوي');

  final String storageKey;
  final String arabicName;

  const PrayerCalculationMode({
    required this.storageKey,
    required this.arabicName,
  });

  static PrayerCalculationMode? tryFromStorageKey(Object? key) {
    if (key is! String) return null;
    for (final mode in values) {
      if (mode.storageKey == key) return mode;
    }
    return null;
  }
}

/// Typed base exception for prayer settings serialization and storage errors.
sealed class PrayerSettingsException implements Exception {
  final String message;
  final Object? cause;

  const PrayerSettingsException(this.message, [this.cause]);

  @override
  String toString() => '$runtimeType: $message${cause != null ? ' ($cause)' : ''}';
}

/// Thrown when persisted prayer settings JSON has an unsupported or invalid schema version.
class PrayerSettingsSchemaException extends PrayerSettingsException {
  final int? foundVersion;

  const PrayerSettingsSchemaException(
    String message, {
    this.foundVersion,
    Object? cause,
  }) : super(message, cause);
}

/// Thrown when persisted prayer settings JSON is malformed or has invalid field values.
class PrayerSettingsFormatException extends PrayerSettingsException {
  const PrayerSettingsFormatException(super.message, [super.cause]);
}

/// Thrown when reading prayer settings from persistent storage fails.
class PrayerSettingsReadException extends PrayerSettingsException {
  const PrayerSettingsReadException(super.message, [super.cause]);
}

/// Thrown when writing prayer settings to persistent storage fails.
class PrayerSettingsWriteException extends PrayerSettingsException {
  const PrayerSettingsWriteException(super.message, [super.cause]);
}

/// Immutable prayer calculation configuration persisted with schema versioning.
class PrayerSettings {
  static const int currentSchemaVersion = 1;

  final int schemaVersion;
  final PrayerCalculationMode calculationMode;
  final PrayerCalculationMethod manualMethod;
  final PrayerMadhab madhab;

  const PrayerSettings({
    this.schemaVersion = currentSchemaVersion,
    this.calculationMode = PrayerCalculationMode.auto,
    this.manualMethod = PrayerCalculationMethod.muslimWorldLeague,
    this.madhab = PrayerMadhab.shafi,
  });

  /// Default approved configuration: Auto mode, MWL fallback, Shafi madhab.
  factory PrayerSettings.defaults() => const PrayerSettings();

  PrayerSettings copyWith({
    PrayerCalculationMode? calculationMode,
    PrayerCalculationMethod? manualMethod,
    PrayerMadhab? madhab,
  }) {
    return PrayerSettings(
      schemaVersion: currentSchemaVersion,
      calculationMode: calculationMode ?? this.calculationMode,
      manualMethod: manualMethod ?? this.manualMethod,
      madhab: madhab ?? this.madhab,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'calculationMode': calculationMode.storageKey,
      'manualMethod': manualMethod.storageKey,
      'madhab': madhab.storageKey,
    };
  }

  /// Validates and deserializes a JSON map into [PrayerSettings].
  /// Rejects unsupported future or unknown schema versions and invalid fields.
  factory PrayerSettings.fromJson(Map<String, dynamic> json) {
    final Object? rawVersion = json['schemaVersion'];
    if (rawVersion is! int) {
      throw const PrayerSettingsSchemaException(
        'Missing or non-integer schemaVersion in prayer settings.',
      );
    }
    if (rawVersion != currentSchemaVersion) {
      throw PrayerSettingsSchemaException(
        'Unsupported prayer settings schemaVersion: $rawVersion.',
        foundVersion: rawVersion,
      );
    }

    final mode = PrayerCalculationMode.tryFromStorageKey(json['calculationMode']);
    if (mode == null) {
      throw PrayerSettingsFormatException(
        'Invalid calculationMode: ${json['calculationMode']}.',
      );
    }

    final method = PrayerCalculationMethod.tryFromStorageKey(json['manualMethod']);
    if (method == null) {
      throw PrayerSettingsFormatException(
        'Invalid manualMethod: ${json['manualMethod']}.',
      );
    }

    final madhab = PrayerMadhab.tryFromStorageKey(json['madhab']);
    if (madhab == null) {
      throw PrayerSettingsFormatException(
        'Invalid madhab: ${json['madhab']}.',
      );
    }

    return PrayerSettings(
      schemaVersion: rawVersion,
      calculationMode: mode,
      manualMethod: method,
      madhab: madhab,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PrayerSettings &&
            other.schemaVersion == schemaVersion &&
            other.calculationMode == calculationMode &&
            other.manualMethod == manualMethod &&
            other.madhab == madhab);
  }

  @override
  int get hashCode =>
      Object.hash(schemaVersion, calculationMode, manualMethod, madhab);
}

