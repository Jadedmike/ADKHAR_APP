import '../../data/services/compass_sensor_service.dart';
import 'qibla_calculator.dart';

/// Status of the processed compass heading sample.
enum ProcessedHeadingStatus {
  valid,
  nullReading,
  invalidIosSentinel,
  nonFinite,
}

/// Output of correcting, normalizing, and smoothing a compass sensor reading.
class ProcessedQiblaHeading {
  final ProcessedHeadingStatus status;

  /// Unsmoothed True-North heading in [0.0, 360.0), or null if invalid.
  final double? rawTrueHeading;

  /// Shortest-arc smoothed True-North heading in [0.0, 360.0), or null if invalid.
  final double? smoothedTrueHeading;

  /// Relative clockwise Qibla direction from the device's top in [0.0, 360.0).
  final double? relativeDirection;

  /// True only when corrected heading is within ±[alignmentThresholdDegrees].
  final bool isAligned;

  /// True when sensor accuracy indicates calibration is advisable.
  final bool isLowAccuracy;

  const ProcessedQiblaHeading({
    required this.status,
    this.rawTrueHeading,
    this.smoothedTrueHeading,
    this.relativeDirection,
    this.isAligned = false,
    this.isLowAccuracy = false,
  });
}

/// Applies platform-specific heading correction (WMM-2025 declination for Android
/// Magnetic North; passthrough with `-1.0` sentinel rejection for iOS True North),
/// shortest-arc smoothing across 359°/0°, relative Qibla angle calculation, and
/// ±5-degree alignment detection.
class QiblaHeadingProcessor {
  static const double alignmentThresholdDegrees = 5.0;
  static const double defaultSmoothingAlpha = 0.25;

  final double smoothingAlpha;
  double? _lastSmoothedTrueHeading;

  QiblaHeadingProcessor({this.smoothingAlpha = defaultSmoothingAlpha});

  double? get currentSmoothedTrueHeading => _lastSmoothedTrueHeading;

  void reset() {
    _lastSmoothedTrueHeading = null;
  }

  /// Processes a single [reading] against [qiblaBearingDegrees] and (for Android)
  /// [declinationDegrees].
  ProcessedQiblaHeading process({
    required CompassSensorReading reading,
    required double qiblaBearingDegrees,
    double? declinationDegrees,
  }) {
    final double? raw = reading.heading;
    if (raw == null) {
      return const ProcessedQiblaHeading(
        status: ProcessedHeadingStatus.nullReading,
      );
    }
    if (!raw.isFinite) {
      return const ProcessedQiblaHeading(
        status: ProcessedHeadingStatus.nonFinite,
      );
    }

    // iOS CLHeading.trueHeading reports -1.0 when CoreLocation has no valid true-north fix.
    if (reading.reference == CompassHeadingReference.trueNorth &&
        (raw - (-1.0)).abs() < 1e-6) {
      return const ProcessedQiblaHeading(
        status: ProcessedHeadingStatus.invalidIosSentinel,
      );
    }

    final double correctedTrueHeading;
    if (reading.reference == CompassHeadingReference.magneticNorth) {
      if (declinationDegrees == null || !declinationDegrees.isFinite) {
        throw StateError(
          'Magnetic declination is required for Android Magnetic-North readings.',
        );
      }
      // Preserve valid negative Android magnetic headings before normalizing.
      correctedTrueHeading = QiblaCalculator.normalizeAngle(
        raw + declinationDegrees,
      );
    } else {
      // iOS already supplies True North; never apply declination twice.
      correctedTrueHeading = QiblaCalculator.normalizeAngle(raw);
    }

    // Shortest-arc smoothing across 359°/0° AFTER True-North correction.
    final double smoothed;
    if (_lastSmoothedTrueHeading == null) {
      smoothed = correctedTrueHeading;
    } else {
      final delta = QiblaCalculator.shortestAngleDifference(
        _lastSmoothedTrueHeading!,
        correctedTrueHeading,
      );
      smoothed = QiblaCalculator.normalizeAngle(
        _lastSmoothedTrueHeading! + smoothingAlpha * delta,
      );
    }
    _lastSmoothedTrueHeading = smoothed;

    final double normalizedQibla = QiblaCalculator.normalizeAngle(
      qiblaBearingDegrees,
    );
    final double relativeDirection = QiblaCalculator.normalizeAngle(
      normalizedQibla - smoothed,
    );
    final double angularError = QiblaCalculator.shortestAngleDifference(
      smoothed,
      normalizedQibla,
    ).abs();

    final bool lowAccuracy = _isLowAccuracy(reading);

    return ProcessedQiblaHeading(
      status: ProcessedHeadingStatus.valid,
      rawTrueHeading: correctedTrueHeading,
      smoothedTrueHeading: smoothed,
      relativeDirection: relativeDirection,
      isAligned: angularError <= alignmentThresholdDegrees,
      isLowAccuracy: lowAccuracy,
    );
  }

  static bool _isLowAccuracy(CompassSensorReading reading) {
    final acc = reading.accuracy;
    if (acc == null || !acc.isFinite || acc < 0) {
      return true;
    }
    // Android FlutterCompass encodes: 15 (high), 30 (medium), 45 (low).
    // iOS CLHeading reports deviation in degrees (higher = less accurate).
    return acc >= 30.0;
  }
}

