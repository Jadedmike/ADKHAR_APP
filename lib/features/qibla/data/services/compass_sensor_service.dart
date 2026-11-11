import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_compass/flutter_compass.dart';

/// Identifies which North reference the platform compass sensor reports.
enum CompassHeadingReference {
  /// Android SensorManager orientation reports Magnetic North (often -180..180).
  magneticNorth,

  /// iOS CLHeading.trueHeading reports True North (or -1.0 sentinel when unavailable).
  trueNorth,
}

/// Raw reading emitted by [CompassSensorService].
class CompassSensorReading {
  final double? heading;
  final double? accuracy;
  final CompassHeadingReference reference;

  const CompassSensorReading({
    required this.heading,
    required this.accuracy,
    required this.reference,
  });
}

/// Injectable source of platform compass events.
abstract class CompassEventSource {
  TargetPlatform get platform;
  Stream<CompassEvent>? get events;
}

/// Default [FlutterCompass]-backed implementation of [CompassEventSource].
class FlutterCompassEventSource implements CompassEventSource {
  const FlutterCompassEventSource();

  @override
  TargetPlatform get platform => defaultTargetPlatform;

  @override
  Stream<CompassEvent>? get events => FlutterCompass.events;
}

/// Manages a single active subscription to the device compass sensor stream.
class CompassSensorService {
  final CompassEventSource _source;
  StreamSubscription<CompassEvent>? _subscription;
  bool _isDisposed = false;

  CompassSensorService({CompassEventSource? source})
    : _source = source ?? const FlutterCompassEventSource();

  CompassHeadingReference get headingReference {
    return _source.platform == TargetPlatform.iOS
        ? CompassHeadingReference.trueNorth
        : CompassHeadingReference.magneticNorth;
  }

  bool get isSupportedPlatform {
    return !kIsWeb &&
        (_source.platform == TargetPlatform.android ||
            _source.platform == TargetPlatform.iOS);
  }

  bool get hasActiveSubscription => _subscription != null;

  /// Starts listening to the compass stream, ensuring only one subscription
  /// is active at a time.
  ///
  /// Returns `false` if the sensor stream is unavailable on this device.
  bool startListening({
    required void Function(CompassSensorReading reading) onReading,
    required void Function(Object error, StackTrace stackTrace) onError,
    void Function()? onUnavailable,
  }) {
    if (_isDisposed) return false;

    cancelListening();

    if (!isSupportedPlatform) {
      onUnavailable?.call();
      return false;
    }

    final Stream<CompassEvent>? stream = _source.events;
    if (stream == null) {
      onUnavailable?.call();
      return false;
    }

    _subscription = stream.listen(
      (CompassEvent event) {
        onReading(
          CompassSensorReading(
            heading: event.heading,
            accuracy: event.accuracy,
            reference: headingReference,
          ),
        );
      },
      onError: (Object error, StackTrace stackTrace) {
        onError(error, stackTrace);
      },
      onDone: () {
        _subscription = null;
        onUnavailable?.call();
      },
      cancelOnError: false,
    );

    return true;
  }

  Future<void> cancelListening() async {
    final sub = _subscription;
    _subscription = null;
    if (sub != null) {
      await sub.cancel();
    }
  }

  Future<void> dispose() async {
    _isDisposed = true;
    await cancelListening();
  }
}

