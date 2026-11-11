import 'dart:convert';

/// Whether coordinates were obtained from an active GPS/provider fix or a last-known cache.
enum LocationSourceType {
  fresh('fresh', 'موقع محدّث'),
  cached('cached', 'آخر موقع معروف');

  final String storageKey;
  final String arabicLabel;

  const LocationSourceType(this.storageKey, this.arabicLabel);

  static LocationSourceType? tryFromStorageKey(Object? key) {
    if (key is! String) return null;
    for (final value in values) {
      if (value.storageKey == key) return value;
    }
    return null;
  }
}

/// Validates that [latitude] and [longitude] are finite WGS84 coordinates.
bool isValidWgs84Coordinates(double latitude, double longitude) {
  return latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90.0 &&
      latitude <= 90.0 &&
      longitude >= -180.0 &&
      longitude <= 180.0;
}

/// Persistent representation of the user's saved geographic location for prayer times & Qibla.
class SavedPrayerLocation {
  static const int currentSchemaVersion = 1;
  static const String fallbackDisplayName = 'الموقع المحفوظ';

  final int schemaVersion;
  final double latitude;
  final double longitude;
  final String? isoCountryCode;
  final String? countryName;
  final String? city;
  final String? district;
  final DateTime timestamp;
  final LocationSourceType source;

  SavedPrayerLocation({
    this.schemaVersion = currentSchemaVersion,
    required this.latitude,
    required this.longitude,
    this.isoCountryCode,
    this.countryName,
    this.city,
    this.district,
    required this.timestamp,
    required this.source,
  }) {
    if (!isValidWgs84Coordinates(latitude, longitude)) {
      throw ArgumentError(
        'Invalid WGS84 coordinates: ($latitude, $longitude).',
      );
    }
  }

  bool get hasValidCoordinates => isValidWgs84Coordinates(latitude, longitude);

  /// Whether at least one human-readable address component is present.
  bool get hasReadableAddress {
    return _cleanPart(countryName) != null ||
        _cleanPart(city) != null ||
        _cleanPart(district) != null;
  }

  /// Human-readable location name formatted for Arabic RTL display (e.g. "تركيا، إسطنبول، إسنيورت").
  /// Never exposes raw latitude/longitude coordinates.
  String get displayName {
    final parts = <String>[];
    for (final raw in [countryName, city, district]) {
      final cleaned = _cleanPart(raw);
      if (cleaned != null && !parts.contains(cleaned)) {
        parts.add(cleaned);
      }
    }
    if (parts.isEmpty) {
      return fallbackDisplayName;
    }
    return parts.join('، ');
  }

  SavedPrayerLocation copyWith({
    double? latitude,
    double? longitude,
    String? isoCountryCode,
    String? countryName,
    String? city,
    String? district,
    DateTime? timestamp,
    LocationSourceType? source,
  }) {
    return SavedPrayerLocation(
      schemaVersion: currentSchemaVersion,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isoCountryCode: isoCountryCode ?? this.isoCountryCode,
      countryName: countryName ?? this.countryName,
      city: city ?? this.city,
      district: district ?? this.district,
      timestamp: timestamp ?? this.timestamp,
      source: source ?? this.source,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'latitude': latitude,
      'longitude': longitude,
      'isoCountryCode': _cleanPart(isoCountryCode)?.toUpperCase(),
      'countryName': _cleanPart(countryName),
      'city': _cleanPart(city),
      'district': _cleanPart(district),
      'timestamp': timestamp.toUtc().toIso8601String(),
      'source': source.storageKey,
    };
  }

  String toEncodedJson() => jsonEncode(toJson());

  static SavedPrayerLocation? tryFromJson(Map<String, dynamic> json) {
    final version = json['schemaVersion'];
    if (version is! int || version != currentSchemaVersion) {
      return null;
    }

    final rawLat = json['latitude'];
    final rawLon = json['longitude'];
    if (rawLat is! num || rawLon is! num) {
      return null;
    }
    final lat = rawLat.toDouble();
    final lon = rawLon.toDouble();
    if (!isValidWgs84Coordinates(lat, lon)) {
      return null;
    }

    final rawTimestamp = json['timestamp'];
    if (rawTimestamp is! String) {
      return null;
    }
    final parsedTimestamp = DateTime.tryParse(rawTimestamp);
    if (parsedTimestamp == null) {
      return null;
    }

    final source =
        LocationSourceType.tryFromStorageKey(json['source']) ??
        LocationSourceType.cached;

    return SavedPrayerLocation(
      schemaVersion: version,
      latitude: lat,
      longitude: lon,
      isoCountryCode: _cleanPart(json['isoCountryCode'] as String?),
      countryName: _cleanPart(json['countryName'] as String?),
      city: _cleanPart(json['city'] as String?),
      district: _cleanPart(json['district'] as String?),
      timestamp: parsedTimestamp,
      source: source,
    );
  }

  static String? _cleanPart(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is SavedPrayerLocation &&
            other.schemaVersion == schemaVersion &&
            other.latitude == latitude &&
            other.longitude == longitude &&
            other.isoCountryCode == isoCountryCode &&
            other.countryName == countryName &&
            other.city == city &&
            other.district == district &&
            other.timestamp.toUtc() == timestamp.toUtc() &&
            other.source == source);
  }

  @override
  int get hashCode => Object.hash(
    schemaVersion,
    latitude,
    longitude,
    isoCountryCode,
    countryName,
    city,
    district,
    timestamp.toUtc(),
    source,
  );
}

