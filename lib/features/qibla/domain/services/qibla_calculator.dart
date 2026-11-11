import 'dart:math' as math;
import '../../../prayer/domain/entities/saved_prayer_location.dart';

/// Thrown when Qibla calculation receives invalid or non-finite coordinates.
class InvalidQiblaCoordinatesException implements ArgumentError {
  @override
  final dynamic invalidValue;

  @override
  final String? name;

  @override
  final String message;

  @override
  StackTrace? get stackTrace => StackTrace.current;

  InvalidQiblaCoordinatesException(
    this.message, {
    this.name,
    this.invalidValue,
  });

  @override
  String toString() => 'InvalidQiblaCoordinatesException: $message';
}

/// Result of calculating the True-North Qibla bearing from a location.
class QiblaBearingResult {
  /// Exact floating-point True-North bearing in [0.0, 360.0).
  final double exactBearingDegrees;

  /// Integer True-North bearing in 0..359.
  final int bearingDegrees;

  /// Great-circle Haversine distance to the Kaaba in kilometers.
  final double distanceKm;

  /// True when the user is within the Kaaba proximity threshold.
  final bool isNearKaaba;

  const QiblaBearingResult({
    required this.exactBearingDegrees,
    required this.bearingDegrees,
    required this.distanceKm,
    required this.isNearKaaba,
  });
}

/// Pure-Dart Qibla spherical forward-azimuth and angular math calculator.
class QiblaCalculator {
  QiblaCalculator._();

  /// Official Kaaba coordinates (Masjid al-Haram, Makkah).
  static const double kaabaLatitude = 21.422487;
  static const double kaabaLongitude = 39.826206;

  /// Distance threshold (in kilometers) below which the user is considered
  /// directly at / in immediate proximity to the Kaaba (100 meters).
  static const double nearKaabaThresholdKm = 0.1;

  static const double _earthRadiusKm = 6371.0;

  /// Normalizes any finite angle in degrees into [0.0, 360.0).
  static double normalizeAngle(double degrees) {
    if (!degrees.isFinite) {
      throw ArgumentError.value(
        degrees,
        'degrees',
        'Angle must be a finite number.',
      );
    }
    final normalized = degrees % 360.0;
    final positive = normalized < 0 ? normalized + 360.0 : normalized;
    return positive >= 360.0 || positive == -0.0 ? 0.0 : positive;
  }

  /// Returns the shortest signed angular difference from [fromDegrees] to [toDegrees]
  /// in the range (-180.0, 180.0].
  static double shortestAngleDifference(
    double fromDegrees,
    double toDegrees,
  ) {
    final from = normalizeAngle(fromDegrees);
    final to = normalizeAngle(toDegrees);
    double diff = ((to - from + 540.0) % 360.0) - 180.0;
    if (diff == -180.0) diff = 180.0;
    return diff;
  }

  /// Calculates the initial great-circle True-North Qibla bearing using
  /// the spherical forward-azimuth formula.
  static QiblaBearingResult calculate({
    required double latitude,
    required double longitude,
    double nearThresholdKm = nearKaabaThresholdKm,
  }) {
    if (!isValidWgs84Coordinates(latitude, longitude)) {
      throw InvalidQiblaCoordinatesException(
        'Invalid WGS84 coordinates for Qibla calculation: ($latitude, $longitude).',
        invalidValue: '$latitude,$longitude',
      );
    }

    final distanceKm = _haversineDistanceKm(
      latitude,
      longitude,
      kaabaLatitude,
      kaabaLongitude,
    );
    final isNear = distanceKm <= nearThresholdKm;

    final phi1 = _degToRad(latitude);
    final phi2 = _degToRad(kaabaLatitude);
    final deltaLambda = _degToRad(kaabaLongitude - longitude);

    final y = math.sin(deltaLambda) * math.cos(phi2);
    final x =
        math.cos(phi1) * math.sin(phi2) -
        math.sin(phi1) * math.cos(phi2) * math.cos(deltaLambda);

    final rawBearing = (x == 0.0 && y == 0.0)
        ? 0.0
        : _radToDeg(math.atan2(y, x));
    final exactBearing = normalizeAngle(rawBearing);
    final intBearing = exactBearing.round() % 360;

    return QiblaBearingResult(
      exactBearingDegrees: exactBearing,
      bearingDegrees: intBearing,
      distanceKm: distanceKm,
      isNearKaaba: isNear,
    );
  }

  static double _haversineDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final rLat1 = _degToRad(lat1);
    final rLat2 = _degToRad(lat2);

    final sinDLat = math.sin(dLat / 2.0);
    final sinDLon = math.sin(dLon / 2.0);
    final a =
        sinDLat * sinDLat + math.cos(rLat1) * math.cos(rLat2) * sinDLon * sinDLon;
    final c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(math.max(0.0, 1.0 - a)));
    return _earthRadiusKm * c;
  }

  static double _degToRad(double deg) => deg * (math.pi / 180.0);
  static double _radToDeg(double rad) => rad * (180.0 / math.pi);
}

