import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_page_transitions.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/glass_button.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/glass_modal.dart';
import '../../../../shared/widgets/glass_option_tile.dart';
import '../../../../shared/widgets/screen_header.dart';
import '../../../qibla/presentation/pages/qibla_page.dart';
import '../../data/services/prayer_location_cache_service.dart';
import '../../data/services/prayer_location_service.dart';
import '../../data/services/prayer_times_calculator.dart';
import '../../domain/entities/daily_prayer_times.dart';
import '../../domain/entities/prayer_calculation_method.dart';
import '../../domain/entities/prayer_madhab.dart';
import '../../domain/entities/prayer_settings.dart';
import '../../domain/entities/saved_prayer_location.dart';
import '../managers/prayer_notification_manager.dart';
import '../managers/prayer_settings_manager.dart';
import 'prayer_notification_settings_page.dart';

/// Dedicated Prayer Times screen integrated with saved persistent location,
/// calculation settings, countdown, tomorrow's Fajr, and notification settings.
class PrayerTimesPage extends StatefulWidget {
  final PrayerSettingsManager? settingsManager;
  final PrayerLocationService? locationService;
  final PrayerLocationCacheService? locationCache;
  final PrayerNotificationManager? notificationManager;
  final PrayerTimesCalculator? calculator;
  final DateTime Function()? nowProvider;

  const PrayerTimesPage({
    super.key,
    this.settingsManager,
    this.locationService,
    this.locationCache,
    this.notificationManager,
    this.calculator,
    this.nowProvider,
  });

  @override
  State<PrayerTimesPage> createState() => _PrayerTimesPageState();
}

class _PrayerTimesPageState extends State<PrayerTimesPage>
    with WidgetsBindingObserver {
  late final PrayerSettingsManager _settingsManager;
  late final PrayerLocationService _locationService;
  late final PrayerLocationCacheService _locationCache;
  late final PrayerNotificationManager _notificationManager;
  late final PrayerTimesCalculator _calculator;
  late final DateTime Function() _nowProvider;

  bool _isLoading = true;
  bool _isRefreshingLocation = false;
  String? _errorMessage;
  SavedPrayerLocation? _savedLocation;
  DailyPrayerTimes? _dailyTimes;
  NextObligatoryPrayerInfo? _nextPrayer;
  DateTime? _calculatedLocalDate;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _settingsManager = widget.settingsManager ?? PrayerSettingsManager.instance;
    _locationService = widget.locationService ?? PrayerLocationService.instance;
    _locationCache =
        widget.locationCache ?? PrayerLocationCacheService.instance;
    _notificationManager =
        widget.notificationManager ?? PrayerNotificationManager.instance;
    _calculator = widget.calculator ?? PrayerTimesCalculator.instance;
    _nowProvider = widget.nowProvider ?? DateTime.now;

    WidgetsBinding.instance.addObserver(this);
    _settingsManager.current.addListener(_onPrayerSettingsChanged);
    _initializeFromSavedLocation();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _settingsManager.current.removeListener(_onPrayerSettingsChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Recalculate if local calendar day changed while backgrounded; never acquires GPS.
      _recalculateIfDateChangedOrTick();
    }
  }

  void _onPrayerSettingsChanged() {
    if (!mounted) return;
    _recalculateForCurrentLocation();
    _notificationManager.resyncWithSavedLocation(
      explicitLocation: _savedLocation,
    );
  }

  Future<void> _initializeFromSavedLocation() async {
    try {
      await _settingsManager.loadSafely();
      final cachedLocation = await _locationCache.load();
      if (!mounted) return;

      if (cachedLocation == null || !cachedLocation.hasValidCoordinates) {
        setState(() {
          _savedLocation = null;
          _dailyTimes = null;
          _nextPrayer = null;
          _isLoading = false;
          _errorMessage = null;
        });
        return;
      }

      setState(() {
        _savedLocation = cachedLocation;
        _isLoading = false;
        _errorMessage = null;
      });
      _recalculateForCurrentLocation();
      _startCountdownTimer();

      // Enrich missing readable address metadata from saved coordinates only (no GPS).
      if (!cachedLocation.hasReadableAddress ||
          (cachedLocation.isoCountryCode?.isEmpty ?? true)) {
        final enriched = await _locationService.resolveAddressForSavedLocation(
          cachedLocation,
        );
        if (mounted && enriched != cachedLocation) {
          setState(() => _savedLocation = enriched);
          _recalculateForCurrentLocation();
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'حدث خطأ أثناء تحميل بيانات مواقيت الصلاة.';
        });
      }
    }
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _recalculateIfDateChangedOrTick(),
    );
  }

  void _recalculateIfDateChangedOrTick() {
    if (!mounted || _savedLocation == null) return;
    final nowLocal = _nowProvider().toLocal();
    final todayLocal = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);

    if (_calculatedLocalDate == null ||
        _calculatedLocalDate != todayLocal ||
        _dailyTimes == null) {
      _recalculateForCurrentLocation();
      return;
    }

    setState(() {
      _nextPrayer = _calculator.resolveNextObligatoryPrayer(
        _dailyTimes!,
        nowLocal,
      );
    });
  }

  void _recalculateForCurrentLocation() {
    final location = _savedLocation;
    if (location == null || !location.hasValidCoordinates) return;

    final nowLocal = _nowProvider().toLocal();
    final todayLocal = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
    final calculated = _calculator.calculate(
      latitude: location.latitude,
      longitude: location.longitude,
      settings: _settingsManager.value,
      isoCountryCode: location.isoCountryCode,
      localDate: todayLocal,
    );
    final nextInfo = _calculator.resolveNextObligatoryPrayer(
      calculated,
      nowLocal,
    );

    setState(() {
      _calculatedLocalDate = todayLocal;
      _dailyTimes = calculated;
      _nextPrayer = nextInfo;
      _errorMessage = null;
    });
  }

  Future<bool> _confirmLocationPermissionExplanation() async {
    final currentPermission = await _locationService.checkPermission();
    if (currentPermission == geolocator.LocationPermission.whileInUse ||
        currentPermission == geolocator.LocationPermission.always) {
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
                Icons.location_on_outlined,
                size: 36,
                color: isDark
                    ? const Color(0xFFC9A15B)
                    : const Color(0xFF4E5B4E),
              ),
              const SizedBox(height: 12),
              Text(
                'تحديد الموقع لمواقيت الصلاة',
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
                'يحتاج التطبيق إلى تحديد موقعك الحالي لمرة واحدة لحساب أوقات الصلاة بدقة وحفظ اسم المدينة محلياً على جهازك فقط دون أي تتبع مستمر.',
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

    final confirmed = await _confirmLocationPermissionExplanation();
    if (!confirmed || !mounted) return;

    setState(() {
      _isRefreshingLocation = true;
      if (_savedLocation == null) {
        _errorMessage = null;
      }
    });

    try {
      final acquired = await _locationService.acquireAndSaveLocation();
      if (!mounted) return;

      setState(() {
        _savedLocation = acquired;
        _isRefreshingLocation = false;
        _errorMessage = null;
      });
      _recalculateForCurrentLocation();
      _startCountdownTimer();
      await _notificationManager.resyncWithSavedLocation(
        explicitLocation: acquired,
      );
      if (mounted) {
        _showSnackBar('تم تحديث الموقع: ${acquired.displayName}');
      }
    } on LocationAcquisitionException catch (error) {
      if (!mounted) return;
      setState(() {
        _isRefreshingLocation = false;
        // Preserve previous valid location if refresh fails.
        if (_savedLocation == null) {
          _errorMessage = error.arabicMessage;
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
          _errorMessage = msg;
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

  void _openCalculationSettingsSheet() {
    showGlassBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return ValueListenableBuilder<PrayerSettings>(
          valueListenable: _settingsManager.current,
          builder: (context, settings, _) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'إعدادات حساب المواقيت',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Fustat',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? const Color(0xFFF6F1E7)
                          : AppColors.primaryLight,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'المذهب الفقهي (العصر)',
                    style: TextStyle(
                      fontFamily: 'Fustat',
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? const Color(0xFFC9A15B)
                          : const Color(0xFF4E5B4E),
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (final madhab in PrayerMadhab.values)
                    GlassOptionTile(
                      titleText: madhab.arabicName,
                      isSelected: settings.madhab == madhab,
                      onTap: () => _settingsManager.setMadhab(madhab),
                    ),
                  const SizedBox(height: 14),
                  Text(
                    'وضع اختيار طريقة الحساب',
                    style: TextStyle(
                      fontFamily: 'Fustat',
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? const Color(0xFFC9A15B)
                          : const Color(0xFF4E5B4E),
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (final mode in PrayerCalculationMode.values)
                    GlassOptionTile(
                      titleText: mode.arabicName,
                      subtitleText: mode == PrayerCalculationMode.auto
                          ? 'يُحدّد تلقائياً بناءً على بلد الموقع المحفوظ مع رابطة العالم الإسلامي كبديل افتراضي'
                          : 'اختيار طريقة الحساب يدوياً وتجاوز الاختيار التلقائي',
                      isSelected: settings.calculationMode == mode,
                      onTap: () => _settingsManager.setCalculationMode(mode),
                    ),
                  if (settings.calculationMode ==
                      PrayerCalculationMode.manual) ...[
                    const SizedBox(height: 14),
                    Text(
                      'طريقة الحساب اليدوية',
                      style: TextStyle(
                        fontFamily: 'Fustat',
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? const Color(0xFFC9A15B)
                            : const Color(0xFF4E5B4E),
                      ),
                    ),
                    const SizedBox(height: 6),
                    for (final method in PrayerCalculationMethod.values)
                      GlassOptionTile(
                        titleText: method.arabicName,
                        isSelected: settings.manualMethod == method,
                        onTap: () => _settingsManager.setManualMethod(method),
                      ),
                  ],
                ],
              ),
            );
          },
        );
      },
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
                      title: 'مواقيت الصلاة',
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GlassIconButton(
                            icon: Icons.tune_rounded,
                            tooltip: 'إعدادات الحساب',
                            onPressed: _openCalculationSettingsSheet,
                            size: 42,
                            iconSize: 20,
                          ),
                          const SizedBox(width: 8),
                          GlassIconButton(
                            icon: Icons.notifications_outlined,
                            tooltip: 'تنبيهات الصلاة',
                            onPressed: () {
                              Navigator.of(context).push(
                                AppPageRoute.create(
                                  PrayerNotificationSettingsPage(
                                    notificationManager: _notificationManager,
                                    locationCache: _locationCache,
                                    locationService: _locationService,
                                  ),
                                ),
                              );
                            },
                            size: 42,
                            iconSize: 20,
                          ),
                        ],
                      ),
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
      if (_errorMessage != null) {
        return _buildErrorState(context, _errorMessage!);
      }
      return _buildMissingLocationState(context);
    }

    if (_dailyTimes == null) {
      return _buildErrorState(
        context,
        _errorMessage ?? 'تعذر حساب مواقيت الصلاة للموقع الحالي.',
      );
    }

    return _buildPrayerTimesContent(context, _savedLocation!, _dailyTimes!);
  }

  Widget _buildMissingLocationState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: GlassCard(
        radius: 24,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_off_outlined,
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
              'لحساب مواقيت الصلاة بدقة في منطقتك، يرجى السماح بتحديد الموقع لمرة واحدة ليتم حفظه محلياً.',
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
              borderColor: isDark
                  ? const Color(0xFFC9A15B)
                  : const Color(0xFF4E5B4E),
              onPressed: _isRefreshingLocation
                  ? null
                  : _acquireLocationExplicitly,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
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
              'تعذر تحديد الموقع',
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
            const SizedBox(height: 8),
            Text(
              message,
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

  Widget _buildPrayerTimesContent(
    BuildContext context,
    SavedPrayerLocation location,
    DailyPrayerTimes times,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final next = _nextPrayer;
    final settings = _settingsManager.value;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Saved Location & Date Meta Card
          GlassCard(
            radius: 22,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            location.displayName,
                            style: TextStyle(
                              fontFamily: 'Fustat',
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? const Color(0xFFF6F1E7)
                                  : const Color(0xFF1E281F),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_formatLocalDate(times.localDate)} • ${location.source.arabicLabel}',
                            style: TextStyle(
                              fontFamily: 'Fustat',
                              fontSize: 11.5,
                              color: isDark
                                  ? const Color(0xFFD8CEBE)
                                  : const Color(0xFF707973),
                            ),
                          ),
                        ],
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
                const SizedBox(height: 10),
                Divider(
                  height: 1,
                  color: isDark
                      ? const Color(0xFF353E32)
                      : const Color(0xFFEADFCF),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: _openCalculationSettingsSheet,
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${times.method.arabicName} (${settings.calculationMode == PrayerCalculationMode.auto ? "تلقائي" : "يدوي"}) • المذهب ${times.madhab.arabicName}',
                          style: TextStyle(
                            fontFamily: 'Fustat',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFFC9A15B)
                                : const Color(0xFF4E5B4E),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_left_rounded,
                        size: 18,
                        color: isDark
                            ? const Color(0xFFD8CEBE)
                            : const Color(0xFF707973),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Next Obligatory Prayer & Countdown Card
          if (next != null)
            GlassCard(
              radius: 24,
              borderColor: isDark
                  ? const Color(0xFFC9A15B).withValues(alpha: 0.6)
                  : const Color(0xFFC5A059).withValues(alpha: 0.7),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    next.isTomorrow
                        ? 'الصلاة القادمة (غداً)'
                        : 'الصلاة القادمة',
                    style: TextStyle(
                      fontFamily: 'Fustat',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFFC9A15B)
                          : const Color(0xFF707973),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    next.arabicName,
                    style: TextStyle(
                      fontFamily: 'Fustat',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? const Color(0xFFF6F1E7)
                          : AppColors.primaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(next.time),
                    style: TextStyle(
                      fontFamily: 'Fustat',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? const Color(0xFFD8CEBE)
                          : const Color(0xFF4E5B4E),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1F241D)
                          : const Color(0xFFF7F2E8),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF353E32)
                            : const Color(0xFFEADFCF),
                      ),
                    ),
                    child: Text(
                      'المتبقي ${_formatCountdown(next.remaining)}',
                      style: TextStyle(
                        fontFamily: 'Fustat',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? const Color(0xFFC9A15B)
                            : const Color(0xFF4E5B4E),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 14),

          // All 6 Prayer Events List
          GlassCard(
            key: const ValueKey('prayer_events_list'),
            radius: 22,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              children: [
                for (int i = 0; i < times.events.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 12,
                      color: isDark
                          ? const Color(0xFF353E32)
                          : const Color(0xFFF3ECE0),
                    ),
                  _buildPrayerEventRow(
                    context,
                    event: times.events[i],
                    isNext:
                        next != null &&
                        !next.isTomorrow &&
                        times.events[i].obligatoryPrayer == next.prayer,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Tomorrow's Fajr Card
          GlassCard(
            radius: 18,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.wb_twilight_rounded,
                      size: 18,
                      color: isDark
                          ? const Color(0xFFC9A15B)
                          : const Color(0xFF4E5B4E),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'فجر الغد',
                      style: TextStyle(
                        fontFamily: 'Fustat',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? const Color(0xFFF6F1E7)
                            : const Color(0xFF1E281F),
                      ),
                    ),
                  ],
                ),
                Text(
                  _formatTime(times.tomorrowFajr),
                  style: TextStyle(
                    fontFamily: 'Fustat',
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? const Color(0xFFC9A15B)
                        : const Color(0xFF4E5B4E),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Quick navigation to Qibla & Notification Settings
          Row(
            children: [
              Expanded(
                child: GlassButton(
                  label: 'اتجاه القبلة',
                  icon: const Icon(Icons.explore_outlined, size: 18),
                  onPressed: () {
                    Navigator.of(context).push(
                      AppPageRoute.create(
                        QiblaPage(
                          locationCache: _locationCache,
                          locationService: _locationService,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GlassButton(
                  label: 'التنبيهات',
                  icon: const Icon(Icons.notifications_none_rounded, size: 18),
                  onPressed: () {
                    Navigator.of(context).push(
                      AppPageRoute.create(
                        PrayerNotificationSettingsPage(
                          notificationManager: _notificationManager,
                          locationCache: _locationCache,
                          locationService: _locationService,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerEventRow(
    BuildContext context, {
    required PrayerEvent event,
    required bool isNext,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isSunrise = !event.isObligatory;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: isNext
          ? BoxDecoration(
              color: isDark
                  ? const Color(0xFFC9A15B).withValues(alpha: 0.14)
                  : const Color(0xFFC5A059).withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            )
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                _iconForEvent(event.type),
                size: 20,
                color: isNext
                    ? (isDark
                          ? const Color(0xFFC9A15B)
                          : const Color(0xFF4E5B4E))
                    : (isDark
                          ? const Color(0xFFD8CEBE)
                          : const Color(0xFF707973)),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.arabicName,
                    style: TextStyle(
                      fontFamily: 'Fustat',
                      fontSize: 15.5,
                      fontWeight: isNext ? FontWeight.w800 : FontWeight.bold,
                      color: isSunrise
                          ? (isDark
                                ? const Color(0xFFD8CEBE)
                                : const Color(0xFF707973))
                          : (isDark
                                ? const Color(0xFFF6F1E7)
                                : const Color(0xFF1E281F)),
                    ),
                  ),
                  if (isSunrise)
                    Text(
                      'وقت الشروق (ليس صلاة مفروضة)',
                      style: TextStyle(
                        fontFamily: 'Fustat',
                        fontSize: 11,
                        color: isDark
                            ? const Color(0xFFA69F91)
                            : const Color(0xFF8C918A),
                      ),
                    ),
                ],
              ),
            ],
          ),
          Text(
            _formatTime(event.time),
            style: TextStyle(
              fontFamily: 'Fustat',
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isNext
                  ? (isDark ? const Color(0xFFC9A15B) : const Color(0xFF4E5B4E))
                  : (isDark
                        ? const Color(0xFFF6F1E7)
                        : const Color(0xFF1E281F)),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForEvent(PrayerEventType type) {
    switch (type) {
      case PrayerEventType.fajr:
        return Icons.wb_twilight_rounded;
      case PrayerEventType.sunrise:
        return Icons.wb_sunny_outlined;
      case PrayerEventType.dhuhr:
        return Icons.light_mode_outlined;
      case PrayerEventType.asr:
        return Icons.sunny_snowing;
      case PrayerEventType.maghrib:
        return Icons.nights_stay_outlined;
      case PrayerEventType.isha:
        return Icons.dark_mode_outlined;
    }
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour < 12 ? 'ص' : 'م';
    return '$hour12:$minute $period';
  }

  String _formatCountdown(Duration duration) {
    final safe = duration.isNegative ? Duration.zero : duration;
    final hours = safe.inHours.toString().padLeft(2, '0');
    final minutes = (safe.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (safe.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  String _formatLocalDate(DateTime date) {
    try {
      HijriCalendar.setLocal('ar');
      final hDate = HijriCalendar.fromDate(date);
      final gregorian = DateFormat('d MMMM yyyy', 'ar').format(date);
      return '${hDate.hDay} ${hDate.longMonthName} ${hDate.hYear} هـ • $gregorian م';
    } catch (_) {
      return '${date.year}/${date.month}/${date.day}';
    }
  }
}

