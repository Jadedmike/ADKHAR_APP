import 'daily_prayer_times.dart';

/// Sound mode for local prayer notifications (never full Adhan audio).
enum PrayerNotificationSoundMode {
  shortAlert('short', 'تنبيه قصير'),
  silent('silent', 'صامت');

  final String storageKey;
  final String arabicLabel;

  const PrayerNotificationSoundMode(this.storageKey, this.arabicLabel);

  static PrayerNotificationSoundMode? tryFromStorageKey(Object? key) {
    if (key is! String) return null;
    for (final mode in values) {
      if (mode.storageKey == key) return mode;
    }
    return null;
  }
}

/// Typed base exception for prayer notification settings errors.
sealed class PrayerNotificationSettingsException implements Exception {
  final String message;
  final Object? cause;

  const PrayerNotificationSettingsException(this.message, [this.cause]);

  @override
  String toString() =>
      '$runtimeType: $message${cause != null ? ' ($cause)' : ''}';
}

class PrayerNotificationSchemaException
    extends PrayerNotificationSettingsException {
  final int? foundVersion;

  const PrayerNotificationSchemaException(
    String message, {
    this.foundVersion,
    Object? cause,
  }) : super(message, cause);
}

class PrayerNotificationFormatException
    extends PrayerNotificationSettingsException {
  const PrayerNotificationFormatException(super.message, [super.cause]);
}

class PrayerNotificationWriteException
    extends PrayerNotificationSettingsException {
  const PrayerNotificationWriteException(super.message, [super.cause]);
}

/// Immutable configuration for prayer local notifications.
class PrayerNotificationSettings {
  static const int currentSchemaVersion = 1;

  final int schemaVersion;
  final bool masterEnabled;
  final Map<ObligatoryPrayer, bool> enabledPrayers;
  final PrayerNotificationSoundMode soundMode;

  PrayerNotificationSettings({
    this.schemaVersion = currentSchemaVersion,
    this.masterEnabled = false,
    Map<ObligatoryPrayer, bool>? enabledPrayers,
    this.soundMode = PrayerNotificationSoundMode.shortAlert,
  }) : enabledPrayers = Map.unmodifiable({
         for (final prayer in ObligatoryPrayer.values)
           prayer: enabledPrayers?[prayer] ?? true,
       });

  /// Default settings: master disabled, all 5 obligatory prayers enabled, short sound.
  factory PrayerNotificationSettings.defaults() => PrayerNotificationSettings();

  bool isPrayerEnabled(ObligatoryPrayer prayer) =>
      enabledPrayers[prayer] ?? true;

  PrayerNotificationSettings copyWith({
    bool? masterEnabled,
    Map<ObligatoryPrayer, bool>? enabledPrayers,
    PrayerNotificationSoundMode? soundMode,
  }) {
    return PrayerNotificationSettings(
      schemaVersion: currentSchemaVersion,
      masterEnabled: masterEnabled ?? this.masterEnabled,
      enabledPrayers: enabledPrayers ?? this.enabledPrayers,
      soundMode: soundMode ?? this.soundMode,
    );
  }

  PrayerNotificationSettings withPrayerEnabled(
    ObligatoryPrayer prayer,
    bool enabled,
  ) {
    final next = Map<ObligatoryPrayer, bool>.from(enabledPrayers);
    next[prayer] = enabled;
    return copyWith(enabledPrayers: next);
  }

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'masterEnabled': masterEnabled,
      'soundMode': soundMode.storageKey,
      'enabledPrayers': {
        for (final entry in enabledPrayers.entries)
          entry.key.storageKey: entry.value,
      },
    };
  }

  factory PrayerNotificationSettings.fromJson(Map<String, dynamic> json) {
    final rawVersion = json['schemaVersion'];
    if (rawVersion is! int) {
      throw const PrayerNotificationSchemaException(
        'Missing or non-integer schemaVersion in prayer notification settings.',
      );
    }
    if (rawVersion != currentSchemaVersion) {
      throw PrayerNotificationSchemaException(
        'Unsupported prayer notification settings schemaVersion: $rawVersion.',
        foundVersion: rawVersion,
      );
    }

    final master = json['masterEnabled'];
    if (master is! bool) {
      throw const PrayerNotificationFormatException(
        'Invalid masterEnabled in prayer notification settings.',
      );
    }

    final soundMode = PrayerNotificationSoundMode.tryFromStorageKey(
      json['soundMode'],
    );
    if (soundMode == null) {
      throw PrayerNotificationFormatException(
        'Invalid soundMode: ${json['soundMode']}.',
      );
    }

    final rawPrayers = json['enabledPrayers'];
    if (rawPrayers is! Map) {
      throw const PrayerNotificationFormatException(
        'Invalid enabledPrayers map in prayer notification settings.',
      );
    }

    final parsedPrayers = <ObligatoryPrayer, bool>{};
    for (final prayer in ObligatoryPrayer.values) {
      final val = rawPrayers[prayer.storageKey];
      if (val is! bool) {
        throw PrayerNotificationFormatException(
          'Missing or non-boolean switch for ${prayer.storageKey}.',
        );
      }
      parsedPrayers[prayer] = val;
    }

    return PrayerNotificationSettings(
      schemaVersion: rawVersion,
      masterEnabled: master,
      enabledPrayers: parsedPrayers,
      soundMode: soundMode,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PrayerNotificationSettings) return false;
    if (other.schemaVersion != schemaVersion ||
        other.masterEnabled != masterEnabled ||
        other.soundMode != soundMode) {
      return false;
    }
    for (final prayer in ObligatoryPrayer.values) {
      if (other.enabledPrayers[prayer] != enabledPrayers[prayer]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    schemaVersion,
    masterEnabled,
    soundMode,
    Object.hashAll(
      ObligatoryPrayer.values.map((p) => enabledPrayers[p]),
    ),
  );
}

