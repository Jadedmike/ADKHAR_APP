import 'dart:math' as math;
import '../../../prayer/domain/entities/saved_prayer_location.dart';

/// Base exception for WMM-2025 geomagnetic calculation errors.
sealed class WmmException implements Exception {
  final String message;

  const WmmException(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

/// Thrown when the requested calculation date falls outside [2025.0, 2030.0).
class WmmOutOfRangeException extends WmmException {
  final double decimalYear;

  const WmmOutOfRangeException(this.decimalYear)
    : super(
        'Date ($decimalYear) is outside the supported WMM-2025 interval [2025.0, 2030.0).',
      );
}

/// Thrown when coordinates or altitude passed to WMM-2025 are invalid.
class WmmInvalidInputException extends WmmException {
  const WmmInvalidInputException(super.message);
}

/// Full geomagnetic field elements returned by [Wmm2025].
class WmmMagneticField {
  /// Magnetic declination in degrees (East positive, West negative).
  final double declinationDegrees;

  /// Magnetic inclination (dip angle) in degrees (Down positive).
  final double inclinationDegrees;

  /// Horizontal field intensity in nanoTesla (nT).
  final double horizontalIntensityNt;

  /// Total magnetic field intensity in nanoTesla (nT).
  final double totalIntensityNt;

  /// Geodetic North component X in nanoTesla (nT).
  final double xNt;

  /// Geodetic East component Y in nanoTesla (nT).
  final double yNt;

  /// Geodetic Down component Z in nanoTesla (nT).
  final double zNt;

  /// Decimal year used in the calculation.
  final double decimalYear;

  const WmmMagneticField({
    required this.declinationDegrees,
    required this.inclinationDegrees,
    required this.horizontalIntensityNt,
    required this.totalIntensityNt,
    required this.xNt,
    required this.yNt,
    required this.zNt,
    required this.decimalYear,
  });
}

class _WmmCoefficient {
  final int n;
  final int m;
  final double g;
  final double h;
  final double gDot;
  final double hDot;

  const _WmmCoefficient(this.n, this.m, this.g, this.h, this.gDot, this.hDot);
}

/// Pure-Dart offline implementation of the **World Magnetic Model 2025 (WMM-2025)**.
///
/// Specifications & Documentation:
/// - **Model Version**: WMM-2025 (Epoch 2025.0), degree & order $N = 12$.
/// - **Reference Data**: Official NOAA NCEI WMM-2025 (`WMM.COF`, Epoch 2025.0, 11/13/2024) Gauss coefficients and secular variation rates.
/// - **Supported Date Interval**: `2025.0 <= decimalYear < 2030.0`.
/// - **Datum & Units**: WGS-84 ellipsoidal-to-spherical geocentric conversion; altitude in kilometers above WGS-84 ellipsoid; magnetic components in nanoTesla (nT); angles in degrees.
/// - **Sign Convention**: East magnetic declination is positive (`+`); West magnetic declination is negative (`-`).
/// - **Failure Mode**: Never silently returns zero declination on invalid inputs or out-of-range dates; throws [WmmOutOfRangeException] or [WmmInvalidInputException].
class Wmm2025 {
  Wmm2025._();

  static const String modelVersion = 'WMM-2025';
  static const double epoch = 2025.0;
  static const double minDecimalYear = 2025.0;
  static const double maxExclusiveDecimalYear = 2030.0;
  static const int maxDegree = 12;

  // WGS-84 ellipsoid parameters (in km) and geomagnetic reference radius.
  static const double _wgs84A = 6378.137;
  static const double _wgs84Flattening = 1.0 / 298.257223563;
  static const double _wgs84E2 = _wgs84Flattening * (2.0 - _wgs84Flattening);
  static const double _geomagneticReferenceRadiusKm = 6371.2;

  /// Converts a [DateTime] to decimal year in UTC using actual year length (leap-year aware).
  static double toDecimalYear(DateTime date) {
    final utc = date.toUtc();
    final yearStart = DateTime.utc(utc.year, 1, 1);
    final nextYearStart = DateTime.utc(utc.year + 1, 1, 1);
    final elapsedMicros = utc.difference(yearStart).inMicroseconds;
    final totalYearMicros = nextYearStart.difference(yearStart).inMicroseconds;
    return utc.year + (elapsedMicros / totalYearMicros);
  }

  /// Calculates magnetic declination in degrees (East positive, West negative)
  /// for the given WGS-84 [latitude], [longitude], [date], and optional [altitudeKm].
  static double calculateDeclination({
    required double latitude,
    required double longitude,
    required DateTime date,
    double altitudeKm = 0.0,
  }) {
    return calculateFieldForDate(
      latitude: latitude,
      longitude: longitude,
      date: date,
      altitudeKm: altitudeKm,
    ).declinationDegrees;
  }

  /// Calculates the full geomagnetic field vector for a [DateTime].
  static WmmMagneticField calculateFieldForDate({
    required double latitude,
    required double longitude,
    required DateTime date,
    double altitudeKm = 0.0,
  }) {
    return calculateField(
      latitude: latitude,
      longitude: longitude,
      decimalYear: toDecimalYear(date),
      altitudeKm: altitudeKm,
    );
  }

  /// Calculates the full geomagnetic field vector for an explicit [decimalYear].
  static WmmMagneticField calculateField({
    required double latitude,
    required double longitude,
    required double decimalYear,
    double altitudeKm = 0.0,
  }) {
    if (!isValidWgs84Coordinates(latitude, longitude)) {
      throw WmmInvalidInputException(
        'Invalid WGS-84 coordinates: ($latitude, $longitude).',
      );
    }
    if (!altitudeKm.isFinite) {
      throw const WmmInvalidInputException('Altitude must be finite.');
    }
    if (!decimalYear.isFinite ||
        decimalYear < minDecimalYear ||
        decimalYear >= maxExclusiveDecimalYear) {
      throw WmmOutOfRangeException(decimalYear);
    }

    final double dt = decimalYear - epoch;

    // Guard exact poles against cos(phi') == 0 division in Y component.
    final double clampedLat = latitude.clamp(-89.999999, 89.999999);
    final double latRad = clampedLat * (math.pi / 180.0);
    final double lonRad = longitude * (math.pi / 180.0);

    // 1. WGS-84 ellipsoidal-to-spherical geocentric coordinate conversion.
    final double sinLat = math.sin(latRad);
    final double cosLat = math.cos(latRad);
    final double rc = _wgs84A / math.sqrt(1.0 - _wgs84E2 * sinLat * sinLat);
    final double p = (rc + altitudeKm) * cosLat;
    final double zCoord = (rc * (1.0 - _wgs84E2) + altitudeKm) * sinLat;
    final double r = math.sqrt(p * p + zCoord * zCoord);
    final double sinPhiPrime = zCoord / r;
    final double cosPhiPrime = p / r;
    final double phiPrime = math.atan2(zCoord, p);

    // 2. Schmidt semi-normalized associated Legendre functions P[n][m](sin phi')
    //    and derivatives dP[n][m] / d(phi').
    final List<List<double>> pnm = List.generate(
      maxDegree + 1,
      (_) => List<double>.filled(maxDegree + 1, 0.0),
    );
    final List<List<double>> dpnm = List.generate(
      maxDegree + 1,
      (_) => List<double>.filled(maxDegree + 1, 0.0),
    );

    pnm[0][0] = 1.0;
    dpnm[0][0] = 0.0;
    pnm[1][0] = sinPhiPrime;
    dpnm[1][0] = cosPhiPrime;
    pnm[1][1] = cosPhiPrime;
    dpnm[1][1] = -sinPhiPrime;

    for (int n = 2; n <= maxDegree; n++) {
      for (int m = 0; m <= n; m++) {
        if (m == n) {
          final factor = math.sqrt((2.0 * n - 1.0) / (2.0 * n));
          pnm[n][n] = factor * cosPhiPrime * pnm[n - 1][n - 1];
          dpnm[n][n] =
              factor *
              (cosPhiPrime * dpnm[n - 1][n - 1] -
                  sinPhiPrime * pnm[n - 1][n - 1]);
        } else {
          final denom = math.sqrt((n * n - m * m).toDouble());
          final kPrev = ((n - 1) >= m)
              ? math.sqrt(((n - 1) * (n - 1) - m * m).toDouble())
              : 0.0;
          final pPrev2 = (n - 2 >= m) ? pnm[n - 2][m] : 0.0;
          final dpPrev2 = (n - 2 >= m) ? dpnm[n - 2][m] : 0.0;

          pnm[n][m] =
              ((2.0 * n - 1.0) * sinPhiPrime * pnm[n - 1][m] -
                  kPrev * pPrev2) /
              denom;
          dpnm[n][m] =
              ((2.0 * n - 1.0) *
                      (cosPhiPrime * pnm[n - 1][m] +
                          sinPhiPrime * dpnm[n - 1][m]) -
                  kPrev * dpPrev2) /
              denom;
        }
      }
    }

    // Precompute cos(m * lon) and sin(m * lon).
    final cosMLon = List<double>.filled(maxDegree + 1, 1.0);
    final sinMLon = List<double>.filled(maxDegree + 1, 0.0);
    for (int m = 1; m <= maxDegree; m++) {
      cosMLon[m] = math.cos(m * lonRad);
      sinMLon[m] = math.sin(m * lonRad);
    }

    // 3. Spherical harmonic summation up to N = 12 with secular variation.
    final double ratio = _geomagneticReferenceRadiusKm / r;
    final ratioPow = List<double>.filled(maxDegree + 1, 0.0);
    double currentPow = ratio * ratio; // (Re/r)^2
    for (int n = 1; n <= maxDegree; n++) {
      currentPow *= ratio; // (Re/r)^(n+2)
      ratioPow[n] = currentPow;
    }

    double xPrime = 0.0;
    double yPrime = 0.0;
    double zPrime = 0.0;

    for (final c in _coefficients) {
      final double g = c.g + dt * c.gDot;
      final double h = c.h + dt * c.hDot;
      final double cosM = cosMLon[c.m];
      final double sinM = sinMLon[c.m];
      final double rFactor = ratioPow[c.n];

      final double gCosPlusHSin = g * cosM + h * sinM;
      xPrime -= rFactor * gCosPlusHSin * dpnm[c.n][c.m];
      zPrime -= (c.n + 1) * rFactor * gCosPlusHSin * pnm[c.n][c.m];

      if (c.m > 0) {
        final double gSinMinusHCos = g * sinM - h * cosM;
        yPrime += rFactor * c.m * gSinMinusHCos * pnm[c.n][c.m];
      }
    }
    yPrime /= cosPhiPrime;

    // 4. Rotate geocentric (X', Y', Z') back to geodetic (X, Y, Z).
    final double psi = phiPrime - latRad;
    final double cosPsi = math.cos(psi);
    final double sinPsi = math.sin(psi);

    final double x = xPrime * cosPsi - zPrime * sinPsi;
    final double y = yPrime;
    final double z = xPrime * sinPsi + zPrime * cosPsi;

    final double hIntensity = math.sqrt(x * x + y * y);
    final double fIntensity = math.sqrt(hIntensity * hIntensity + z * z);

    final double declinationDeg = math.atan2(y, x) * (180.0 / math.pi);
    final double inclinationDeg =
        math.atan2(z, hIntensity) * (180.0 / math.pi);

    return WmmMagneticField(
      declinationDegrees: declinationDeg,
      inclinationDegrees: inclinationDeg,
      horizontalIntensityNt: hIntensity,
      totalIntensityNt: fIntensity,
      xNt: x,
      yNt: y,
      zNt: z,
      decimalYear: decimalYear,
    );
  }

  // Official WMM-2025 Gauss coefficients (Epoch 2025.0, Degree N = 12).
  // Format: (n, m, g_nm [nT], h_nm [nT], dg_nm/dt [nT/yr], dh_nm/dt [nT/yr])
  static const List<_WmmCoefficient> _coefficients = [
    // Degree 1
    _WmmCoefficient(1, 0, -29351.8, 0.0, 12.0, 0.0),
    _WmmCoefficient(1, 1, -1410.8, 4545.4, 9.7, -21.5),
    // Degree 2
    _WmmCoefficient(2, 0, -2556.6, 0.0, -11.6, 0.0),
    _WmmCoefficient(2, 1, 2951.1, -3133.6, -5.2, -27.7),
    _WmmCoefficient(2, 2, 1649.3, -815.1, -8.0, -12.1),
    // Degree 3
    _WmmCoefficient(3, 0, 1361.0, 0.0, -1.3, 0.0),
    _WmmCoefficient(3, 1, -2404.1, -56.6, -4.2, 4.0),
    _WmmCoefficient(3, 2, 1243.8, 237.5, 0.4, -0.3),
    _WmmCoefficient(3, 3, 453.6, -549.5, -15.6, -4.1),
    // Degree 4
    _WmmCoefficient(4, 0, 895.0, 0.0, -1.6, 0.0),
    _WmmCoefficient(4, 1, 799.5, 278.6, -2.4, -1.1),
    _WmmCoefficient(4, 2, 55.7, -133.9, -6.0, 4.1),
    _WmmCoefficient(4, 3, -281.1, 212.0, 5.6, 1.6),
    _WmmCoefficient(4, 4, 12.1, -375.6, -7.0, -4.4),
    // Degree 5
    _WmmCoefficient(5, 0, -233.2, 0.0, 0.6, 0.0),
    _WmmCoefficient(5, 1, 368.9, 45.4, 1.4, -0.5),
    _WmmCoefficient(5, 2, 187.2, 220.2, 0.0, 2.2),
    _WmmCoefficient(5, 3, -138.7, -122.9, 0.6, 0.4),
    _WmmCoefficient(5, 4, -142.0, 43.0, 2.2, 1.7),
    _WmmCoefficient(5, 5, 20.9, 106.1, 0.9, 1.9),
    // Degree 6
    _WmmCoefficient(6, 0, 64.4, 0.0, -0.2, 0.0),
    _WmmCoefficient(6, 1, 63.8, -18.4, -0.4, 0.3),
    _WmmCoefficient(6, 2, 76.9, 16.8, 0.9, -1.6),
    _WmmCoefficient(6, 3, -115.7, 48.8, 1.2, -0.4),
    _WmmCoefficient(6, 4, -40.9, -59.8, -0.9, 0.9),
    _WmmCoefficient(6, 5, 14.9, 10.9, 0.3, 0.7),
    _WmmCoefficient(6, 6, -60.7, 72.7, 0.9, 0.9),
    // Degree 7
    _WmmCoefficient(7, 0, 79.5, 0.0, 0.0, 0.0),
    _WmmCoefficient(7, 1, -77.0, -48.9, -0.1, 0.6),
    _WmmCoefficient(7, 2, -8.8, -14.4, -0.1, 0.5),
    _WmmCoefficient(7, 3, 59.3, -1.0, 0.5, -0.8),
    _WmmCoefficient(7, 4, 15.8, 23.4, -0.1, 0.0),
    _WmmCoefficient(7, 5, 2.5, -7.4, -0.8, -1.0),
    _WmmCoefficient(7, 6, -11.1, -25.1, -0.8, 0.6),
    _WmmCoefficient(7, 7, 14.2, -2.3, 0.8, -0.2),
    // Degree 8
    _WmmCoefficient(8, 0, 23.2, 0.0, -0.1, 0.0),
    _WmmCoefficient(8, 1, 10.8, 7.1, 0.2, -0.2),
    _WmmCoefficient(8, 2, -17.5, -12.6, 0.0, 0.5),
    _WmmCoefficient(8, 3, 2.0, 11.4, 0.5, -0.4),
    _WmmCoefficient(8, 4, -21.7, -9.7, -0.1, 0.4),
    _WmmCoefficient(8, 5, 16.9, 12.7, 0.3, -0.5),
    _WmmCoefficient(8, 6, 15.0, 0.7, 0.2, -0.6),
    _WmmCoefficient(8, 7, -16.8, -5.2, 0.0, 0.3),
    _WmmCoefficient(8, 8, 0.9, 3.9, 0.2, 0.2),
    // Degree 9
    _WmmCoefficient(9, 0, 4.6, 0.0, 0.0, 0.0),
    _WmmCoefficient(9, 1, 7.8, -24.8, -0.1, -0.3),
    _WmmCoefficient(9, 2, 3.0, 12.2, 0.1, 0.3),
    _WmmCoefficient(9, 3, -0.2, 8.3, 0.3, -0.3),
    _WmmCoefficient(9, 4, -2.5, -3.3, -0.3, 0.3),
    _WmmCoefficient(9, 5, -13.1, -5.2, 0.0, 0.2),
    _WmmCoefficient(9, 6, 2.4, 7.2, 0.3, -0.1),
    _WmmCoefficient(9, 7, 8.6, -0.6, -0.1, -0.2),
    _WmmCoefficient(9, 8, -8.7, 0.8, 0.1, 0.4),
    _WmmCoefficient(9, 9, -12.9, 10.0, -0.1, 0.1),
    // Degree 10
    _WmmCoefficient(10, 0, -1.3, 0.0, 0.1, 0.0),
    _WmmCoefficient(10, 1, -6.4, 3.3, 0.0, 0.0),
    _WmmCoefficient(10, 2, 0.2, 0.0, 0.1, 0.0),
    _WmmCoefficient(10, 3, 2.0, 2.4, 0.1, -0.2),
    _WmmCoefficient(10, 4, -1.0, 5.3, 0.0, 0.1),
    _WmmCoefficient(10, 5, -0.6, -9.1, -0.3, -0.1),
    _WmmCoefficient(10, 6, -0.9, 0.4, 0.0, 0.1),
    _WmmCoefficient(10, 7, 1.5, -4.2, -0.1, 0.0),
    _WmmCoefficient(10, 8, 0.9, -3.8, -0.1, -0.1),
    _WmmCoefficient(10, 9, -2.7, 0.9, 0.0, 0.2),
    _WmmCoefficient(10, 10, -3.9, -9.1, 0.0, 0.0),
    // Degree 11
    _WmmCoefficient(11, 0, 2.9, 0.0, 0.0, 0.0),
    _WmmCoefficient(11, 1, -1.5, 0.0, 0.0, 0.0),
    _WmmCoefficient(11, 2, -2.5, 2.9, 0.0, 0.1),
    _WmmCoefficient(11, 3, 2.4, -0.6, 0.0, 0.0),
    _WmmCoefficient(11, 4, -0.6, 0.2, 0.0, 0.1),
    _WmmCoefficient(11, 5, -0.1, 0.5, -0.1, 0.0),
    _WmmCoefficient(11, 6, -0.6, -0.3, 0.0, 0.0),
    _WmmCoefficient(11, 7, -0.1, -1.2, 0.0, 0.1),
    _WmmCoefficient(11, 8, 1.1, -1.7, -0.1, 0.0),
    _WmmCoefficient(11, 9, -1.0, -2.9, -0.1, 0.0),
    _WmmCoefficient(11, 10, -0.2, -1.8, -0.1, 0.0),
    _WmmCoefficient(11, 11, 2.6, -2.3, -0.1, 0.0),
    // Degree 12
    _WmmCoefficient(12, 0, -2.0, 0.0, 0.0, 0.0),
    _WmmCoefficient(12, 1, -0.2, -1.3, 0.0, 0.0),
    _WmmCoefficient(12, 2, 0.3, 0.7, 0.0, 0.0),
    _WmmCoefficient(12, 3, 1.2, 1.0, 0.0, -0.1),
    _WmmCoefficient(12, 4, -1.3, -1.4, 0.0, 0.1),
    _WmmCoefficient(12, 5, 0.6, 0.0, 0.0, 0.0),
    _WmmCoefficient(12, 6, 0.6, 0.6, 0.1, 0.0),
    _WmmCoefficient(12, 7, 0.5, -0.1, 0.0, 0.0),
    _WmmCoefficient(12, 8, -0.1, 0.8, 0.0, 0.0),
    _WmmCoefficient(12, 9, -0.4, 0.1, 0.0, 0.0),
    _WmmCoefficient(12, 10, -0.2, -1.0, -0.1, 0.0),
    _WmmCoefficient(12, 11, -1.3, 0.1, 0.0, 0.0),
    _WmmCoefficient(12, 12, -0.7, 0.2, -0.1, -0.1),
  ];
}
