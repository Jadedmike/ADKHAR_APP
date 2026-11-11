import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import '../../../../config/theme/app_colors.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/glass_button.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/glass_modal.dart';
import '../../../../shared/widgets/screen_header.dart';
import '../../../prayer/data/services/prayer_location_cache_service.dart';
import '../../../prayer/data/services/prayer_location_service.dart';
import '../../../prayer/domain/entities/saved_prayer_location.dart';
import '../../data/services/compass_sensor_service.dart';
import '../../domain/services/qibla_calculator.dart';
import '../../domain/services/qibla_heading_processor.dart';
import '../../domain/services/wmm_2025.dart';

enum _SensorUiStatus {
  waitingForReading,
  active,
  nullOrInvalidReading,
  unavailable,
  streamError,
  wmmError,
}

/// Dedicated Qibla Compass screen reusing the Phase 5.5 saved location cache,
/// offline WMM-2025 declination (Android Magnetic-North), and iOS True-North passthrough.
class QiblaPage extends StatefulWidget {
  final PrayerLocationCacheService? locationCache;
  final PrayerLocationService? locationService;
  final CompassSensorService? sensorService;
  final QiblaHeadingProcessor? headingProcessor;
  final DateTime Function()? nowProvider;
  final double altitudeKm;

  const QiblaPage({
    super.key,
    this.locationCache,
    this.locationService,
    this.sensorService,
    this.headingProcessor,
    this.nowProvider,
    this.altitudeKm = 0.0,
  });

  @override
  State<QiblaPage> createState() => _QiblaPageState();
}

class _QiblaPageState extends State<QiblaPage> {
  late final PrayerLocationCacheService _locationCache;
  late final PrayerLocationService _locationService;
  late final CompassSensorService _sensorService;
  late final QiblaHeadingProcessor _headingProcessor;
  late final DateTime Function() _nowProvider;

  bool _isLoading = true;
  bool _isRefreshingLocation = false;
  String? _locationError;

  SavedPrayerLocation? _savedLocation;
  QiblaBearingResult? _bearingResult;
  String? _wmmErrorMessage;

  _SensorUiStatus _sensorStatus = _SensorUiStatus.waitingForReading;
  ProcessedQiblaHeading? _lastValidHeading;
  bool _isLowAccuracy = false;

  @override
  void initState() {
    super.initState();
    _locationCache =
        widget.locationCache ?? PrayerLocationCacheService.instance;
    _locationService = widget.locationService ?? PrayerLocationService.instance;
    _sensorService = widget.sensorService ?? CompassSensorService();
    _headingProcessor = widget.headingProcessor ?? QiblaHeadingProcessor();
    _nowProvider = widget.nowProvider ?? DateTime.now;
    _initializeFromSavedLocation();
  }

  @override
  void dispose() {
    _sensorService.dispose();
    super.dispose();
  }

  Future<void> _initializeFromSavedLocation() async {
    try {
      final cached = await _locationCache.load();
      if (!mounted) return;

      if (cached == null || !cached.hasValidCoordinates) {
        setState(() {
          _savedLocation = null;
          _bearingResult = null;
          _isLoading = false;
          _locationError = null;
        });
        return;
      }

      _configureLocationAndStartCompass(cached);

      // Enrich missing readable address metadata from saved coordinates only (no GPS).
      if (!cached.hasReadableAddress) {
        final enriched = await _locationService.resolveAddressForSavedLocation(
          cached,
        );
        if (mounted && enriched != cached) {
          setState(() => _savedLocation = enriched);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _locationError = 'حدث خطأ أثناء قراءة الموقع المحفوظ.';
        });
      }
    }
  }

  void _configureLocationAndStartCompass(SavedPrayerLocation location) {
    QiblaBearingResult? bearing;
    String? locErr;
    try {
      bearing = QiblaCalculator.calculate(
        latitude: location.latitude,
        longitude: location.longitude,
      );
    } on InvalidQiblaCoordinatesException {
      locErr = 'إحداثيات الموقع المحفوظ غير صالحة لحساب اتجاه القبلة.';
    }

    double? declination;
    String? wmmErr;
    if (bearing != null &&
        _sensorService.headingReference ==
            CompassHeadingReference.magneticNorth) {
      try {
        declination = Wmm2025.calculateDeclination(
          latitude: location.latitude,
          longitude: location.longitude,
          date: _nowProvider(),
          altitudeKm: widget.altitudeKm,
        );
      } on WmmOutOfRangeException {
        wmmErr =
            'تاريخ الجهاز خارج النطاق المدعوم لنموذج الانحراف المغناطيسي (2025–2029). تعذر تصحيح البوصلة تلقائياً.';
      } on WmmException {
        wmmErr =
            'تعذر حساب الانحراف المغناطيسي للموقع الحالي. لا يمكن عرض سهم البوصلة المباشر بأمان.';
      } catch (_) {
        wmmErr = 'حدث خطأ غير متوقع أثناء حساب الانحراف المغناطيسي.';
      }
    }

    _headingProcessor.reset();

    setState(() {
      _savedLocation = location;
      _bearingResult = bearing;
      _locationError = locErr;
      _wmmErrorMessage = wmmErr;
      _lastValidHeading = null;
      _isLowAccuracy = false;
      _isLoading = false;
    });

    if (bearing == null) {
      _sensorService.cancelListening();
      return;
    }

    if (wmmErr != null) {
      _sensorService.cancelListening();
      setState(() => _sensorStatus = _SensorUiStatus.wmmError);
      return;
    }

    _startCompassStream(bearing, declination);
  }

  void _startCompassStream(
    QiblaBearingResult bearing,
    double? declinationDegrees,
  ) {
    setState(() => _sensorStatus = _SensorUiStatus.waitingForReading);

    final started = _sensorService.startListening(
      onReading: (reading) {
        if (!mounted) return;
        try {
          final processed = _headingProcessor.process(
            reading: reading,
            qiblaBearingDegrees: bearing.exactBearingDegrees,
            declinationDegrees: declinationDegrees,
          );

          if (processed.status != ProcessedHeadingStatus.valid) {
            setState(() {
              _sensorStatus = _SensorUiStatus.nullOrInvalidReading;
              _lastValidHeading = null;
            });
            return;
          }

          setState(() {
            _sensorStatus = _SensorUiStatus.active;
            _lastValidHeading = processed;
            _isLowAccuracy = processed.isLowAccuracy;
          });
        } catch (_) {
          setState(() {
            _sensorStatus = _SensorUiStatus.wmmError;
            _wmmErrorMessage = 'تعذر تطبيق تصحيح الانحراف المغناطيسي على قراءة البوصلة.';
            _lastValidHeading = null;
          });
        }
      },
      onError: (error, stackTrace) {
        if (!mounted) return;
        setState(() {
          _sensorStatus = _SensorUiStatus.streamError;
          _lastValidHeading = null;
        });
      },
      onUnavailable: () {
        if (!mounted) return;
        setState(() {
          _sensorStatus = _SensorUiStatus.unavailable;
          _lastValidHeading = null;
        });
      },
    );

    if (!started && mounted) {
      setState(() {
        _sensorStatus = _SensorUiStatus.unavailable;
        _lastValidHeading = null;
      });
    }
  }

  Future<bool> _confirmLocationExplanation() async {
    final permission = await _locationService.checkPermission();
    if (permission == geolocator.LocationPermission.whileInUse ||
        permission == geolocator.LocationPermission.always) {
      return true;
    }

    if (!mounted) return false;
    final confirmed = await showGlassDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
        return Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.explore_outlined,
                size: 36,
                color: isDark
                    ? const Color(0xFFC9A15B)
                    : const Color(0xFF4E5B4E),
              ),
              const SizedBox(height: 12),
              Text(
                'تحديد الموقع لاتجاه القبلة',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Fustat',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? const Color(0xFFF6F1E7)
                      : const Color(0xFF1E281F),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'يحتاج التطبيق إلى موقعك الحالي لمرة واحدة لحساب زاوية القبلة بدقة وتطبيق التصحيح المغناطيسي المناسب لمنطقتك.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Fustat',
                  fontSize: 13.5,
                  height: 1.6,
                  color: isDark
                      ? const Color(0xFFD8CEBE)
                      : const Color(0xFF707973),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: GlassButton(
                      label: 'إلغاء',
                      height: 46,
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GlassButton(
                      label: 'متابعة',
                      height: 46,
                      borderColor: isDark
                          ? const Color(0xFFC9A15B)
                          : const Color(0xFF4E5B4E),
                      textColor: isDark
                          ? const Color(0xFFC9A15B)
                          : const Color(0xFF4E5B4E),
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
    return confirmed ?? false;
  }

  Future<void> _acquireLocationExplicitly() async {
    if (_isRefreshingLocation) return;
    final confirmed = await _confirmLocationExplanation();
    if (!confirmed || !mounted) return;

    setState(() => _isRefreshingLocation = true);

    try {
      final acquired = await _locationService.acquireAndSaveLocation();
      if (!mounted) return;
      setState(() => _isRefreshingLocation = false);
      _configureLocationAndStartCompass(acquired);
      _showSnackBar('تم تحديث الموقع: ${acquired.displayName}');
    } on LocationAcquisitionException catch (error) {
      if (!mounted) return;
      setState(() {
        _isRefreshingLocation = false;
        if (_savedLocation == null) {
          _locationError = error.arabicMessage;
        }
      });
      if (_savedLocation != null) {
        _showSnackBar(error.arabicMessage, isError: true);
      }
    } catch (_) {
      if (!mounted) return;
      const msg = 'تعذر تحديد الموقع حالياً. يرجى المحاولة مرة أخرى.';
      setState(() {
        _isRefreshingLocation = false;
        if (_savedLocation == null) {
          _locationError = msg;
        }
      });
      if (_savedLocation != null) {
        _showSnackBar(msg, isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Fustat',
            fontWeight: FontWeight.bold,
            color: Color(0xFFFFFDF9),
          ),
        ),
        backgroundColor: isError
            ? const Color(0xFFC94A4A)
            : const Color(0xFF4E5B4E),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF161A15) : const Color(0xFFF8F4EC);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        body: Stack(
          children: [
            const AppBackground(),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                child: Column(
                  children: [
                    ScreenHeader(
                      title: 'اتجاه القبلة',
                      trailing: GlassIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onPressed: () => Navigator.of(context).pop(),
                        size: 42,
                        iconSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(child: _buildBody(context)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_savedLocation == null) {
      if (_locationError != null) {
        return _buildLocationErrorCard(context, _locationError!);
      }
      return _buildMissingLocationCard(context);
    }

    if (_bearingResult == null) {
      return _buildLocationErrorCard(
        context,
        _locationError ?? 'تعذر حساب زاوية القبلة للموقع المحفوظ.',
      );
    }

    return _buildCompassView(context, _savedLocation!, _bearingResult!);
  }

  Widget _buildMissingLocationCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: GlassCard(
        radius: 24,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.explore_off_outlined,
              size: 48,
              color: isDark
                  ? const Color(0xFFC9A15B)
                  : const Color(0xFF4E5B4E),
            ),
            const SizedBox(height: 14),
            Text(
              'لا يوجد موقع محفوظ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Fustat',
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? const Color(0xFFF6F1E7)
                    : AppColors.primaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'لحساب اتجاه القبلة بدقة وتطبيق التصحيح المغناطيسي، يرجى تحديد موقعك الحالي لمرة واحدة.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Fustat',
                fontSize: 13.5,
                height: 1.6,
                color: isDark
                    ? const Color(0xFFD8CEBE)
                    : const Color(0xFF707973),
              ),
            ),
            const SizedBox(height: 20),
            GlassButton(
              label: _isRefreshingLocation
                  ? 'جاري تحديد الموقع...'
                  : 'تحديد الموقع الآن',
              icon: _isRefreshingLocation
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location_rounded, size: 18),
              isFullWidth: true,
              onPressed: _isRefreshingLocation
                  ? null
                  : _acquireLocationExplicitly,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationErrorCard(BuildContext context, String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: GlassCard(
        radius: 24,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 46,
              color: AppColors.error,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Fustat',
                fontSize: 14,
                height: 1.6,
                color: isDark
                    ? const Color(0xFFF6F1E7)
                    : const Color(0xFF1E281F),
              ),
            ),
            const SizedBox(height: 18),
            GlassButton(
              label: 'إعادة المحاولة',
              icon: const Icon(Icons.refresh_rounded, size: 18),
              isFullWidth: true,
              onPressed: _isRefreshingLocation
                  ? null
                  : _acquireLocationExplicitly,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompassView(
    BuildContext context,
    SavedPrayerLocation location,
    QiblaBearingResult bearing,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool hasLiveCompass =
        _sensorStatus == _SensorUiStatus.active &&
        _lastValidHeading != null &&
        _wmmErrorMessage == null;

    final double? correctedHeading = _lastValidHeading?.smoothedTrueHeading;
    final double? relativeDir = _lastValidHeading?.relativeDirection;
    final bool isAligned =
        hasLiveCompass && (_lastValidHeading?.isAligned ?? false);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Saved location bar
          GlassCard(
            radius: 20,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.place_outlined,
                  size: 20,
                  color: isDark
                      ? const Color(0xFFC9A15B)
                      : const Color(0xFF4E5B4E),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    location.displayName,
                    style: TextStyle(
                      fontFamily: 'Fustat',
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? const Color(0xFFF6F1E7)
                          : const Color(0xFF1E281F),
                    ),
                  ),
                ),
                GlassIconButton(
                  icon: _isRefreshingLocation
                      ? Icons.hourglass_top_rounded
                      : Icons.my_location_rounded,
                  tooltip: 'تحديث الموقع',
                  onPressed: _isRefreshingLocation
                      ? null
                      : _acquireLocationExplicitly,
                  size: 38,
                  iconSize: 18,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          if (bearing.isNearKaaba) ...[
            GlassCard(
              radius: 18,
              borderColor: isDark
                  ? const Color(0xFFC9A15B)
                  : const Color(0xFFC5A059),
              padding: const EdgeInsets.all(14),
              child: Text(
                'أنت قريب جداً من الكعبة المشرفة (${(bearing.distanceKm * 1000).round()} متر).',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Fustat',
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? const Color(0xFFC9A15B)
                      : const Color(0xFF4E5B4E),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Calculated Qibla Reference Bearing & Live Heading cards
          Row(
            children: [
              Expanded(
                child: GlassCard(
                  radius: 20,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  child: Column(
                    children: [
                      Text(
                        'اتجاه القبلة',
                        style: TextStyle(
                          fontFamily: 'Fustat',
                          fontSize: 12.5,
                          color: isDark
                              ? const Color(0xFFD8CEBE)
                              : const Color(0xFF707973),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${bearing.bearingDegrees}°',
                        style: TextStyle(
                          fontFamily: 'Fustat',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? const Color(0xFFC9A15B)
                              : AppColors.primaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GlassCard(
                  radius: 20,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  child: Column(
                    children: [
                      Text(
                        'اتجاه الجهاز',
                        style: TextStyle(
                          fontFamily: 'Fustat',
                          fontSize: 12.5,
                          color: isDark
                              ? const Color(0xFFD8CEBE)
                              : const Color(0xFF707973),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasLiveCompass && correctedHeading != null
                            ? '${correctedHeading.round() % 360}°'
                            : '--',
                        style: TextStyle(
                          fontFamily: 'Fustat',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? const Color(0xFFF6F1E7)
                              : const Color(0xFF1E281F),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Live Compass Dial or Honest Sensor/WMM Fallback State
          if (hasLiveCompass &&
              correctedHeading != null &&
              relativeDir != null)
            _buildLiveCompassCard(
              context,
              correctedHeading: correctedHeading,
              relativeDirection: relativeDir,
              isAligned: isAligned,
            )
          else
            _buildSensorUnavailableCard(context, bearing),

          const SizedBox(height: 14),

          // Calibration Guidance (always helpful; emphasized when low accuracy)
          GlassCard(
            radius: 18,
            borderColor: _isLowAccuracy
                ? const Color(0xFFC5A059)
                : null,
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(
                  _isLowAccuracy
                      ? Icons.warning_amber_rounded
                      : Icons.info_outline_rounded,
                  size: 20,
                  color: _isLowAccuracy
                      ? const Color(0xFFC5A059)
                      : (isDark
                            ? const Color(0xFFD8CEBE)
                            : const Color(0xFF707973)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _isLowAccuracy
                        ? 'دقة مستشعر البوصلة منخفضة حالياً. حرّك الهاتف على شكل رقم 8 في الهواء وابتعد عن الأجسام المعدنية والمغناطيسية.'
                        : 'للحصول على أدق قراءة، أمسك الهاتف بشكل مسطح وبعيداً عن المعادن، وحرّكه على شكل رقم 8 للمعايرة عند الحاجة.',
                    style: TextStyle(
                      fontFamily: 'Fustat',
                      fontSize: 12,
                      height: 1.5,
                      color: isDark
                          ? const Color(0xFFD8CEBE)
                          : const Color(0xFF707973),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveCompassCard(
    BuildContext context, {
    required double correctedHeading,
    required double relativeDirection,
    required bool isAligned,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentGold = isDark
        ? const Color(0xFFC9A15B)
        : const Color(0xFFC5A059);
    final primaryOlive = isDark
        ? const Color(0xFFF6F1E7)
        : AppColors.primaryLight;

    return GlassCard(
      radius: 28,
      borderColor: isAligned ? AppColors.success : accentGold.withValues(alpha: 0.45),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          if (isAligned) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.success),
              ),
              child: const Text(
                'أنت متجه نحو القبلة',
                style: TextStyle(
                  fontFamily: 'Fustat',
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: 240,
            height: 240,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Rotating Compass Dial aligned to corrected True North
                Transform.rotate(
                  angle: -correctedHeading * (math.pi / 180.0),
                  child: CustomPaint(
                    size: const Size(240, 240),
                    painter: _CompassDialPainter(
                      ringColor: accentGold,
                      textColor: primaryOlive,
                      subtleColor: isDark
                          ? const Color(0xFF4D5849)
                          : const Color(0xFFD5C8B3),
                    ),
                  ),
                ),
                // Qibla Pointer Needle rotated to relativeDirection
                Transform.rotate(
                  angle: relativeDirection * (math.pi / 180.0),
                  child: CustomPaint(
                    size: const Size(170, 170),
                    painter: _QiblaNeedlePainter(
                      needleColor: isAligned ? AppColors.success : accentGold,
                      tailColor: isDark
                          ? const Color(0xFF707973)
                          : const Color(0xFFB3AA99),
                    ),
                  ),
                ),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isAligned ? AppColors.success : primaryOlive,
                    border: Border.all(color: accentGold, width: 2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorUnavailableCard(
    BuildContext context,
    QiblaBearingResult bearing,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String title;
    final String subtitle;

    switch (_sensorStatus) {
      case _SensorUiStatus.waitingForReading:
        title = 'جاري تهيئة مستشعر البوصلة...';
        subtitle =
            'في انتظار قراءة صالحة من مستشعر الاتجاه. زاوية القبلة المرجعية من الشمال الحقيقي هي ${bearing.bearingDegrees}°.';
        break;
      case _SensorUiStatus.nullOrInvalidReading:
        title = 'قراءة البوصلة غير جاهزة';
        subtitle =
            'تعذر استلام اتجاه صالح من المستشعر حالياً (أو يلزم تفعيل خدمة الموقع لتحديد الشمال الحقيقي على iOS). زاوية القبلة المرجعية هي ${bearing.bearingDegrees}°.';
        break;
      case _SensorUiStatus.wmmError:
        title = 'تعذر تصحيح الانحراف المغناطيسي';
        subtitle =
            _wmmErrorMessage ??
            'تعذر حساب الانحراف المغناطيسي. زاوية القبلة المرجعية من الشمال الحقيقي هي ${bearing.bearingDegrees}°.';
        break;
      case _SensorUiStatus.streamError:
        title = 'حدث خطأ في مستشعر البوصلة';
        subtitle =
            'تعذرت قراءة مستشعر البوصلة على الجهاز. زاوية القبلة المرجعية هي ${bearing.bearingDegrees}°.';
        break;
      case _SensorUiStatus.unavailable:
      case _SensorUiStatus.active:
        title = 'مستشعر البوصلة غير متاح';
        subtitle =
            'لا يتوفر مستشعر بوصلة فعال على هذا الجهاز. لا يمكن عرض سهم اتجاه حي، ولكن زاوية القبلة المرجعية من الشمال الحقيقي هي ${bearing.bearingDegrees}°.';
        break;
    }

    return GlassCard(
      radius: 24,
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Icon(
            Icons.sensors_off_rounded,
            size: 44,
            color: _sensorStatus == _SensorUiStatus.wmmError
                ? AppColors.error
                : (isDark ? const Color(0xFFC9A15B) : const Color(0xFF4E5B4E)),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Fustat',
              fontSize: 16.5,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFF6F1E7) : const Color(0xFF1E281F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Fustat',
              fontSize: 13,
              height: 1.6,
              color: isDark ? const Color(0xFFD8CEBE) : const Color(0xFF707973),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompassDialPainter extends CustomPainter {
  final Color ringColor;
  final Color textColor;
  final Color subtleColor;

  const _CompassDialPainter({
    required this.ringColor,
    required this.textColor,
    required this.subtleColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    final outerPaint = Paint()
      ..color = ringColor.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius, outerPaint);

    final tickPaint = Paint()..strokeWidth = 1.4;
    for (int deg = 0; deg < 360; deg += 15) {
      final rad = (deg - 90) * (math.pi / 180.0);
      final isCardinal = deg % 90 == 0;
      final innerR = isCardinal ? radius - 14 : radius - 8;
      tickPaint.color = isCardinal ? ringColor : subtleColor;
      tickPaint.strokeWidth = isCardinal ? 2.4 : 1.2;
      canvas.drawLine(
        Offset(
          center.dx + innerR * math.cos(rad),
          center.dy + innerR * math.sin(rad),
        ),
        Offset(
          center.dx + radius * math.cos(rad),
          center.dy + radius * math.sin(rad),
        ),
        tickPaint,
      );
    }

    const cardinals = {
      0: 'ش',
      90: 'ق',
      180: 'ج',
      270: 'غ',
    };

    for (final entry in cardinals.entries) {
      final rad = (entry.key - 90) * (math.pi / 180.0);
      final labelR = radius - 26;
      final tp = TextPainter(
        text: TextSpan(
          text: entry.value,
          style: TextStyle(
            fontFamily: 'Fustat',
            fontSize: entry.key == 0 ? 15 : 13,
            fontWeight: FontWeight.bold,
            color: entry.key == 0 ? ringColor : textColor,
          ),
        ),
        textDirection: TextDirection.rtl,
      )..layout();
      tp.paint(
        canvas,
        Offset(
          center.dx + labelR * math.cos(rad) - tp.width / 2,
          center.dy + labelR * math.sin(rad) - tp.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CompassDialPainter oldDelegate) {
    return oldDelegate.ringColor != ringColor ||
        oldDelegate.textColor != textColor ||
        oldDelegate.subtleColor != subtleColor;
  }
}

class _QiblaNeedlePainter extends CustomPainter {
  final Color needleColor;
  final Color tailColor;

  const _QiblaNeedlePainter({
    required this.needleColor,
    required this.tailColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final tipY = 14.0;
    final tailY = size.height - 26.0;

    final forwardPath = Path()
      ..moveTo(center.dx, tipY)
      ..lineTo(center.dx - 11, center.dy)
      ..lineTo(center.dx + 11, center.dy)
      ..close();

    final backPath = Path()
      ..moveTo(center.dx, tailY)
      ..lineTo(center.dx - 8, center.dy)
      ..lineTo(center.dx + 8, center.dy)
      ..close();

    canvas.drawPath(
      forwardPath,
      Paint()
        ..color = needleColor
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      backPath,
      Paint()
        ..color = tailColor.withValues(alpha: 0.65)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _QiblaNeedlePainter oldDelegate) {
    return oldDelegate.needleColor != needleColor ||
        oldDelegate.tailColor != tailColor;
  }
}

