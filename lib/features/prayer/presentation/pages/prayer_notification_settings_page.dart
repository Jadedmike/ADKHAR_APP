import 'package:flutter/material.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/glass_button.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/glass_modal.dart';
import '../../../../shared/widgets/glass_option_tile.dart';
import '../../../../shared/widgets/screen_header.dart';
import '../../data/services/prayer_location_cache_service.dart';
import '../../data/services/prayer_location_service.dart';
import '../../domain/entities/daily_prayer_times.dart';
import '../../domain/entities/prayer_notification_settings.dart';
import '../managers/prayer_notification_manager.dart';

/// Dedicated settings screen for local prayer notifications (5 obligatory prayers only).
class PrayerNotificationSettingsPage extends StatefulWidget {
  final PrayerNotificationManager? notificationManager;
  final PrayerLocationCacheService? locationCache;
  final PrayerLocationService? locationService;

  const PrayerNotificationSettingsPage({
    super.key,
    this.notificationManager,
    this.locationCache,
    this.locationService,
  });

  @override
  State<PrayerNotificationSettingsPage> createState() =>
      _PrayerNotificationSettingsPageState();
}

class _PrayerNotificationSettingsPageState
    extends State<PrayerNotificationSettingsPage> {
  late final PrayerNotificationManager _notificationManager;
  late final PrayerLocationCacheService _locationCache;
  late final PrayerLocationService _locationService;

  bool _isBusy = false;
  bool _hasSavedLocation = false;

  @override
  void initState() {
    super.initState();
    _notificationManager =
        widget.notificationManager ?? PrayerNotificationManager.instance;
    _locationCache =
        widget.locationCache ?? PrayerLocationCacheService.instance;
    _locationService = widget.locationService ?? PrayerLocationService.instance;
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    await _notificationManager.loadSafely();
    final saved = await _locationCache.load();
    if (mounted) {
      setState(() {
        _hasSavedLocation = saved != null && saved.hasValidCoordinates;
      });
    }
  }

  Future<bool> _showPermissionExplanationDialog({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final result = await showGlassDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
        return Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.notifications_active_outlined,
                size: 36,
                color: isDark
                    ? const Color(0xFFC9A15B)
                    : const Color(0xFF4E5B4E),
              ),
              const SizedBox(height: 12),
              Text(
                title,
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
                      label: confirmLabel,
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
    return result ?? false;
  }

  Future<void> _toggleMaster(bool enable) async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      if (!enable) {
        await _notificationManager.setMasterEnabled(false);
        return;
      }

      final alreadyPermitted =
          await _notificationManager.hasPermissionWithoutPrompt();
      if (!alreadyPermitted) {
        if (!mounted) return;
        final confirmed = await _showPermissionExplanationDialog(
          title: 'تفعيل تنبيهات الصلاة',
          message:
              'يحتاج التطبيق إلى إذن الإشعارات لإرسال تنبيه محلي قصير عند دخول أوقات الصلوات الخمس المفروضة دون الحاجة للاتصال بالإنترنت.',
          confirmLabel: 'متابعة',
        );
        if (!confirmed || !mounted) return;
      }

      final granted = await _notificationManager.setMasterEnabled(
        true,
        requestPermissionIfNeeded: true,
      );

      if (!mounted) return;
      if (!granted) {
        _showSnackBar(
          'عذراً، يلزم منح إذن الإشعارات من النظام لتفعيل تنبيهات الصلاة',
          isError: true,
        );
        return;
      }

      final saved = await _locationCache.load();
      if (saved == null || !saved.hasValidCoordinates) {
        if (!mounted) return;
        final wantLocation = await _showPermissionExplanationDialog(
          title: 'تحديد الموقع لحساب الأوقات',
          message:
              'تم تفعيل التنبيهات، ولكن لا يوجد موقع محفوظ بعد لحساب مواقيت الصلاة. هل ترغب بتحديد موقعك الآن؟',
          confirmLabel: 'تحديد الموقع',
        );
        if (wantLocation && mounted) {
          try {
            final acquired = await _locationService.acquireAndSaveLocation();
            await _notificationManager.resyncWithSavedLocation(
              explicitLocation: acquired,
            );
            if (mounted) {
              setState(() => _hasSavedLocation = true);
              _showSnackBar('تم تحديد الموقع وجدولة تنبيهات الصلاة بنجاح');
            }
          } on LocationAcquisitionException catch (error) {
            if (mounted) {
              _showSnackBar(error.arabicMessage, isError: true);
            }
          }
        }
      } else {
        _showSnackBar('تم تفعيل وجدولة تنبيهات الصلوات للأيام السبعة القادمة');
      }
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _resetNotifications() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      await _notificationManager.resetSettings();
      if (mounted) {
        _showSnackBar('تمت إعادة ضبط تنبيهات الصلاة وإزالة بياناتها المؤقتة');
      }
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
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
              child: ValueListenableBuilder<PrayerNotificationSettings>(
                valueListenable: _notificationManager.current,
                builder: (context, settings, _) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ScreenHeader(
                          title: 'تنبيهات الصلاة',
                          subtitle: 'إشعارات محلية للصلوات الخمس المفروضة',
                          trailing: GlassIconButton(
                            icon: Icons.arrow_back_ios_new_rounded,
                            onPressed: () => Navigator.of(context).pop(),
                            size: 42,
                            iconSize: 18,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Master toggle
                        GlassCard(
                          radius: 22,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'تفعيل تنبيهات الصلاة',
                                      style: TextStyle(
                                        fontFamily: 'Fustat',
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? const Color(0xFFF6F1E7)
                                            : const Color(0xFF1E281F),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      settings.masterEnabled
                                          ? 'يتم جدولة التنبيهات تلقائياً للأيام السبعة القادمة'
                                          : 'التنبيهات معطّلة افتراضياً حتى تقوم بتفعيلها',
                                      style: TextStyle(
                                        fontFamily: 'Fustat',
                                        fontSize: 12,
                                        color: isDark
                                            ? const Color(0xFFD8CEBE)
                                            : const Color(0xFF707973),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: settings.masterEnabled,
                                activeThumbColor: isDark
                                    ? const Color(0xFFC9A15B)
                                    : const Color(0xFF4E5B4E),
                                onChanged: _isBusy ? null : _toggleMaster,
                              ),
                            ],
                          ),
                        ),

                        if (settings.masterEnabled && !_hasSavedLocation) ...[
                          const SizedBox(height: 12),
                          GlassCard(
                            radius: 18,
                            borderColor: const Color(
                              0xFFC5A059,
                            ).withValues(alpha: 0.6),
                            padding: const EdgeInsets.all(14),
                            child: Text(
                              'ملاحظة: يلزم حفظ موقع في صفحة مواقيت الصلاة ليتمكن التطبيق من جدولة التنبيهات.',
                              style: TextStyle(
                                fontFamily: 'Fustat',
                                fontSize: 12.5,
                                color: isDark
                                    ? const Color(0xFFF6F1E7)
                                    : const Color(0xFF1E281F),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 18),
                        Padding(
                          padding: const EdgeInsets.only(right: 6, bottom: 8),
                          child: Text(
                            'نمط الصوت',
                            style: TextStyle(
                              fontFamily: 'Fustat',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? const Color(0xFFC9A15B)
                                  : const Color(0xFF4E5B4E),
                            ),
                          ),
                        ),
                        for (final mode in PrayerNotificationSoundMode.values)
                          GlassOptionTile(
                            titleText: mode.arabicLabel,
                            subtitleText:
                                mode == PrayerNotificationSoundMode.shortAlert
                                ? 'إشعار بنغمة النظام القصيرة دون تشغيل أذان كامل'
                                : 'إشعار مرئي بدون صوت',
                            isSelected: settings.soundMode == mode,
                            onTap: _isBusy
                                ? null
                                : () => _notificationManager.setSoundMode(mode),
                          ),

                        const SizedBox(height: 18),
                        Padding(
                          padding: const EdgeInsets.only(right: 6, bottom: 8),
                          child: Text(
                            'الصلوات المفروضة (لا يشمل الشروق)',
                            style: TextStyle(
                              fontFamily: 'Fustat',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? const Color(0xFFC9A15B)
                                  : const Color(0xFF4E5B4E),
                            ),
                          ),
                        ),
                        GlassCard(
                          radius: 22,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          child: Column(
                            children: [
                              for (
                                int i = 0;
                                i < ObligatoryPrayer.values.length;
                                i++
                              ) ...[
                                if (i > 0)
                                  Divider(
                                    height: 16,
                                    color: isDark
                                        ? const Color(0xFF353E32)
                                        : const Color(0xFFF3ECE0),
                                  ),
                                _buildPrayerSwitchRow(
                                  context,
                                  prayer: ObligatoryPrayer.values[i],
                                  enabled: settings.isPrayerEnabled(
                                    ObligatoryPrayer.values[i],
                                  ),
                                  masterEnabled: settings.masterEnabled,
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                        GlassButton(
                          label: 'إعادة ضبط تنبيهات الصلاة',
                          icon: const Icon(Icons.restart_alt_rounded, size: 18),
                          isFullWidth: true,
                          onPressed: _isBusy ? null : _resetNotifications,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerSwitchRow(
    BuildContext context, {
    required ObligatoryPrayer prayer,
    required bool enabled,
    required bool masterEnabled,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          prayer.arabicName,
          style: TextStyle(
            fontFamily: 'Fustat',
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: masterEnabled
                ? (isDark ? const Color(0xFFF6F1E7) : const Color(0xFF1E281F))
                : (isDark ? const Color(0xFF8B887E) : const Color(0xFF9A9A92)),
          ),
        ),
        Switch(
          value: enabled,
          activeThumbColor: isDark
              ? const Color(0xFFC9A15B)
              : const Color(0xFF4E5B4E),
          onChanged: (_isBusy || !masterEnabled)
              ? null
              : (val) => _notificationManager.setPrayerEnabled(prayer, val),
        ),
      ],
    );
  }
}

