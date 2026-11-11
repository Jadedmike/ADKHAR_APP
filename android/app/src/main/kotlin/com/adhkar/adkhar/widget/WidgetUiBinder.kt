package com.adhkar.adkhar.widget

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.res.Configuration
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.SystemClock
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import androidx.core.content.ContextCompat
import com.adhkar.adkhar.MainActivity
import com.adhkar.adkhar.R
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import java.time.LocalDate
import java.time.chrono.HijrahDate
import java.time.temporal.ChronoField
import java.util.Calendar
import java.util.Locale
import java.util.TimeZone

object WidgetUiBinder {
  private const val MAX_CHRONOMETER_MS = 48L * 60L * 60L * 1000L

  private data class RowIds(
    val rowId: Int,
    val nameId: Int,
    val clockId: Int,
  )

  private val prayerRowIds = listOf(
    RowIds(R.id.prayer_row_0, R.id.prayer_name_0, R.id.prayer_clock_0),
    RowIds(R.id.prayer_row_1, R.id.prayer_name_1, R.id.prayer_clock_1),
    RowIds(R.id.prayer_row_2, R.id.prayer_name_2, R.id.prayer_clock_2),
    RowIds(R.id.prayer_row_3, R.id.prayer_name_3, R.id.prayer_clock_3),
    RowIds(R.id.prayer_row_4, R.id.prayer_name_4, R.id.prayer_clock_4),
    RowIds(R.id.prayer_row_5, R.id.prayer_name_5, R.id.prayer_clock_5),
  )

  fun isSystemDark(context: Context): Boolean {
    val mask = context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK
    return mask == Configuration.UI_MODE_NIGHT_YES
  }

  fun bindAdhkarWidget(
    context: Context,
    state: ResolvedWidgetState,
    options: Bundle,
  ): RemoteViews {
    val views = RemoteViews(context.packageName, R.layout.widget_adhkar)
    val palette = resolvePalette(context, state.isDarkTheme)
    val minHeightDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 110)

    views.setInt(R.id.widget_adhkar_root, "setBackgroundResource", palette.cardBgRes)
    views.setInt(R.id.adhkar_badge, "setBackgroundResource", palette.pillBgRes)
    views.setTextColor(R.id.adhkar_badge, palette.secondaryText)
    views.setTextColor(R.id.adhkar_brand, palette.goldAccent)
    views.setTextColor(R.id.adhkar_text, palette.primaryText)
    views.setTextColor(R.id.adhkar_source, palette.mutedText)

    val dhikr = state.periodDhikr ?: state.dailyShortDhikr
    val uriString = when (dhikr?.period) {
      AdhkarPeriod.MORNING -> "adhkar://widget/adhkar?period=morning"
      AdhkarPeriod.EVENING -> "adhkar://widget/adhkar?period=evening"
      null -> "adhkar://widget/adhkar"
    }

    if (dhikr != null) {
      views.setTextViewText(R.id.adhkar_badge, dhikr.badgeTitle)
      views.setTextViewText(R.id.adhkar_text, dhikr.text)
      views.setInt(R.id.adhkar_text, "setMaxLines", if (minHeightDp >= 150) 7 else 4)

      if (dhikr.source.isNotBlank() && minHeightDp >= 125) {
        views.setTextViewText(R.id.adhkar_source, dhikr.source)
        views.setViewVisibility(R.id.adhkar_source, View.VISIBLE)
      } else {
        views.setViewVisibility(R.id.adhkar_source, View.GONE)
      }
    } else {
      views.setTextViewText(R.id.adhkar_badge, "الأذكار")
      views.setTextViewText(R.id.adhkar_text, state.promptMessage)
      views.setInt(R.id.adhkar_text, "setMaxLines", 4)
      views.setViewVisibility(R.id.adhkar_source, View.GONE)
    }

    views.setOnClickPendingIntent(
      R.id.widget_adhkar_root,
      HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse(uriString)),
    )
    return views
  }

  fun bindPrayerWidget(
    context: Context,
    state: ResolvedWidgetState,
    options: Bundle,
    timeZone: TimeZone = TimeZone.getDefault(),
    nowEpochMs: Long = System.currentTimeMillis(),
  ): RemoteViews {
    val views = RemoteViews(context.packageName, R.layout.widget_prayer_times)
    val palette = resolvePalette(context, state.isDarkTheme)
    val minHeightDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 110)
    val minWidthDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 250)
    val isCompact = minHeightDp < 105 || minWidthDp < 235
    val isExpanded = minHeightDp >= 160 && minWidthDp >= 300

    views.setInt(R.id.widget_prayer_root, "setBackgroundResource", palette.cardBgRes)
    views.setInt(R.id.prayer_left_panel, "setBackgroundResource", palette.pillBgRes)

    views.setTextViewText(R.id.prayer_weekday, formatArabicWeekday(nowEpochMs, timeZone))
    views.setTextViewText(R.id.prayer_hijri_date, formatArabicHijriDate(nowEpochMs, timeZone))
    views.setTextViewText(R.id.prayer_gregorian_date, formatArabicGregorianDate(nowEpochMs, timeZone))

    val weekdaySp = when {
      isExpanded -> 14.5f
      isCompact -> 11.5f
      else -> 13f
    }
    val dateSp = when {
      isExpanded -> 12f
      isCompact -> 9.5f
      else -> 10.5f
    }
    val nextNameSp = when {
      isExpanded -> 15f
      isCompact -> 12f
      else -> 13.5f
    }
    val countdownSp = when {
      isExpanded -> 20f
      isCompact -> 14.5f
      else -> 17f
    }
    val rowSp = when {
      isExpanded -> 13f
      isCompact -> 10.5f
      else -> 11.5f
    }

    views.setTextViewTextSize(R.id.prayer_weekday, TypedValue.COMPLEX_UNIT_SP, weekdaySp)
    views.setTextViewTextSize(R.id.prayer_hijri_date, TypedValue.COMPLEX_UNIT_SP, dateSp)
    views.setTextViewTextSize(R.id.prayer_gregorian_date, TypedValue.COMPLEX_UNIT_SP, dateSp)
    views.setTextViewTextSize(R.id.prayer_next_name, TypedValue.COMPLEX_UNIT_SP, nextNameSp)
    views.setTextViewTextSize(R.id.prayer_chronometer, TypedValue.COMPLEX_UNIT_SP, countdownSp)
    views.setTextViewTextSize(R.id.prayer_countdown_fallback, TypedValue.COMPLEX_UNIT_SP, countdownSp)

    views.setTextColor(R.id.prayer_weekday, palette.primaryText)
    views.setTextColor(R.id.prayer_hijri_date, if (state.isDarkTheme) palette.mutedText else palette.secondaryText)
    views.setTextColor(R.id.prayer_gregorian_date, palette.mutedText)
    views.setTextColor(R.id.prayer_location, palette.mutedText)
    views.setTextColor(R.id.prayer_next_label, palette.mutedText)
    views.setTextColor(R.id.prayer_next_name, palette.goldAccent)
    views.setTextColor(R.id.prayer_chronometer, palette.primaryText)
    views.setTextColor(R.id.prayer_countdown_fallback, palette.primaryText)
    views.setTextColor(R.id.prayer_prompt_text, palette.primaryText)

    val locationText = state.locationDisplayName
    if (!locationText.isNullOrBlank() && minHeightDp >= 100) {
      views.setTextViewText(R.id.prayer_location, locationText)
      views.setViewVisibility(R.id.prayer_location, View.VISIBLE)
    } else {
      views.setViewVisibility(R.id.prayer_location, View.GONE)
    }

    if (state.prayerStatus == PrayerWidgetStatus.AVAILABLE &&
      state.nextPrayerName != null &&
      state.nextPrayerTimeEpochMs != null
    ) {
      views.setViewVisibility(R.id.prayer_hero_container, View.VISIBLE)
      views.setViewVisibility(R.id.prayer_prompt_container, View.GONE)

      val labelPrefix = if (state.isNextPrayerTomorrow) "الصلاة القادمة (غداً)" else "الصلاة القادمة"
      views.setTextViewText(R.id.prayer_next_label, labelPrefix)
      views.setTextViewText(R.id.prayer_next_name, state.nextPrayerName)

      bindPrayerCountdown(
        views = views,
        chronometerId = R.id.prayer_chronometer,
        fallbackId = R.id.prayer_countdown_fallback,
        remainingMs = state.nextPrayerRemainingMs,
      )

      if (state.dailyPrayerRows.size == prayerRowIds.size) {
        views.setViewVisibility(R.id.prayer_list_container, View.VISIBLE)
        for (i in prayerRowIds.indices) {
          val rowMeta = state.dailyPrayerRows[i]
          val ids = prayerRowIds[i]
          views.setTextViewText(ids.nameId, rowMeta.arabicName)
          views.setTextViewText(ids.clockId, formatArabicClock(rowMeta.utcEpochMs, timeZone))
          views.setTextViewTextSize(ids.nameId, TypedValue.COMPLEX_UNIT_SP, rowSp)
          views.setTextViewTextSize(ids.clockId, TypedValue.COMPLEX_UNIT_SP, rowSp)

          if (rowMeta.isNext) {
            views.setInt(ids.rowId, "setBackgroundResource", palette.highlightBgRes)
            views.setTextColor(ids.nameId, palette.goldAccent)
            views.setTextColor(ids.clockId, palette.goldAccent)
          } else {
            views.setInt(ids.rowId, "setBackgroundResource", 0)
            val nameColor = if (rowMeta.isObligatory) palette.primaryText else palette.mutedText
            val clockColor = if (rowMeta.isObligatory) {
              if (state.isDarkTheme) palette.mutedText else palette.secondaryText
            } else {
              palette.mutedText
            }
            views.setTextColor(ids.nameId, nameColor)
            views.setTextColor(ids.clockId, clockColor)
          }
        }
      } else {
        views.setViewVisibility(R.id.prayer_list_container, View.GONE)
      }
    } else {
      views.setViewVisibility(R.id.prayer_list_container, View.GONE)
      views.setViewVisibility(R.id.prayer_prompt_container, View.VISIBLE)
      views.setTextViewText(R.id.prayer_prompt_text, state.promptMessage)
      views.setViewVisibility(R.id.prayer_hero_container, View.VISIBLE)
      views.setTextViewText(R.id.prayer_next_label, "مواقيت الصلاة")
      views.setTextViewText(R.id.prayer_next_name, "--")
      views.setViewVisibility(R.id.prayer_chronometer, View.GONE)
      views.setViewVisibility(R.id.prayer_countdown_fallback, View.VISIBLE)
      views.setTextViewText(R.id.prayer_countdown_fallback, "--:--:--")
    }

    views.setOnClickPendingIntent(
      R.id.widget_prayer_root,
      HomeWidgetLaunchIntent.getActivity(
        context,
        MainActivity::class.java,
        Uri.parse("adhkar://widget/prayer"),
      ),
    )
    return views
  }

  fun bindCombinedWidget(
    context: Context,
    state: ResolvedWidgetState,
    options: Bundle,
    timeZone: TimeZone = TimeZone.getDefault(),
  ): RemoteViews {
    val views = RemoteViews(context.packageName, R.layout.widget_combined)
    val palette = resolvePalette(context, state.isDarkTheme)
    val minHeightDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 110)

    views.setInt(R.id.widget_combined_root, "setBackgroundResource", palette.cardBgRes)
    views.setInt(R.id.combined_prayer_card, "setBackgroundResource", palette.pillBgRes)
    views.setTextColor(R.id.combined_next_prayer, palette.primaryText)
    views.setTextColor(R.id.combined_location, palette.mutedText)
    views.setTextColor(R.id.combined_next_time, palette.goldAccent)
    views.setTextColor(R.id.combined_countdown_prefix, palette.mutedText)
    views.setTextColor(R.id.combined_chronometer, palette.secondaryText)
    views.setTextColor(R.id.combined_countdown_fallback, palette.secondaryText)
    views.setTextColor(R.id.combined_prayer_prompt, palette.mutedText)
    views.setTextColor(R.id.combined_adhkar_badge, palette.goldAccent)
    views.setTextColor(R.id.combined_adhkar_text, palette.primaryText)

    if (!state.locationDisplayName.isNullOrBlank()) {
      views.setTextViewText(R.id.combined_location, state.locationDisplayName)
      views.setViewVisibility(R.id.combined_location, View.VISIBLE)
    } else {
      views.setViewVisibility(R.id.combined_location, View.GONE)
    }

    if (state.prayerStatus == PrayerWidgetStatus.AVAILABLE &&
      state.nextPrayerName != null &&
      state.nextPrayerTimeEpochMs != null
    ) {
      views.setViewVisibility(R.id.combined_prayer_row, View.VISIBLE)
      views.setViewVisibility(R.id.combined_countdown_row, View.VISIBLE)
      views.setViewVisibility(R.id.combined_prayer_prompt, View.GONE)

      val title = if (state.isNextPrayerTomorrow) {
        "القادمة غداً: ${state.nextPrayerName}"
      } else {
        "القادمة: ${state.nextPrayerName}"
      }
      views.setTextViewText(R.id.combined_next_prayer, title)
      views.setTextViewText(
        R.id.combined_next_time,
        formatArabicClock(state.nextPrayerTimeEpochMs, timeZone),
      )

      bindCountdown(
        views = views,
        rowId = R.id.combined_countdown_row,
        prefixId = R.id.combined_countdown_prefix,
        chronometerId = R.id.combined_chronometer,
        fallbackId = R.id.combined_countdown_fallback,
        remainingMs = state.nextPrayerRemainingMs,
      )
    } else {
      views.setViewVisibility(R.id.combined_prayer_row, View.GONE)
      views.setViewVisibility(R.id.combined_countdown_row, View.GONE)
      views.setViewVisibility(R.id.combined_prayer_prompt, View.VISIBLE)
      views.setTextViewText(R.id.combined_prayer_prompt, state.promptMessage)
    }

    val dhikr = state.dailyShortDhikr ?: state.periodDhikr
    if (dhikr != null) {
      views.setTextViewText(R.id.combined_adhkar_badge, dhikr.badgeTitle)
      views.setTextViewText(R.id.combined_adhkar_text, dhikr.text)
    } else {
      views.setTextViewText(R.id.combined_adhkar_badge, "ذكر اليوم")
      views.setTextViewText(R.id.combined_adhkar_text, state.promptMessage)
    }
    views.setInt(R.id.combined_adhkar_text, "setMaxLines", if (minHeightDp >= 165) 4 else 2)

    views.setOnClickPendingIntent(
      R.id.widget_combined_root,
      HomeWidgetLaunchIntent.getActivity(
        context,
        MainActivity::class.java,
        Uri.parse("adhkar://widget/home"),
      ),
    )
    return views
  }

  private fun bindCountdown(
    views: RemoteViews,
    rowId: Int,
    prefixId: Int,
    chronometerId: Int,
    fallbackId: Int,
    remainingMs: Long?,
  ) {
    if (remainingMs == null || remainingMs <= 0L) {
      views.setViewVisibility(chronometerId, View.GONE)
      views.setViewVisibility(fallbackId, View.GONE)
      views.setViewVisibility(prefixId, View.GONE)
      return
    }

    views.setViewVisibility(rowId, View.VISIBLE)
    views.setViewVisibility(prefixId, View.VISIBLE)

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N && remainingMs < MAX_CHRONOMETER_MS) {
      views.setViewVisibility(chronometerId, View.VISIBLE)
      views.setViewVisibility(fallbackId, View.GONE)
      views.setChronometer(
        chronometerId,
        SystemClock.elapsedRealtime() + remainingMs,
        "%s",
        true,
      )
      views.setChronometerCountDown(chronometerId, true)
    } else {
      views.setViewVisibility(chronometerId, View.GONE)
      views.setViewVisibility(fallbackId, View.VISIBLE)
      views.setTextViewText(fallbackId, formatRemainingDuration(remainingMs))
    }
  }

  private fun bindPrayerCountdown(
    views: RemoteViews,
    chronometerId: Int,
    fallbackId: Int,
    remainingMs: Long?,
  ) {
    if (remainingMs == null || remainingMs <= 0L) {
      views.setViewVisibility(chronometerId, View.GONE)
      views.setViewVisibility(fallbackId, View.VISIBLE)
      views.setTextViewText(fallbackId, if (remainingMs == null) "--:--:--" else "00:00:00")
      return
    }

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N && remainingMs < MAX_CHRONOMETER_MS) {
      views.setViewVisibility(chronometerId, View.VISIBLE)
      views.setViewVisibility(fallbackId, View.GONE)
      val format = if (remainingMs < 3_600_000L) "00:%s" else "%s"
      views.setChronometer(
        chronometerId,
        SystemClock.elapsedRealtime() + remainingMs,
        format,
        true,
      )
      views.setChronometerCountDown(chronometerId, true)
    } else {
      views.setViewVisibility(chronometerId, View.GONE)
      views.setViewVisibility(fallbackId, View.VISIBLE)
      views.setTextViewText(fallbackId, formatCountdownHhMmSs(remainingMs))
    }
  }

  internal fun formatArabicWeekday(epochMs: Long, timeZone: TimeZone): String {
    val cal = Calendar.getInstance(timeZone).apply { timeInMillis = epochMs }
    return when (cal.get(Calendar.DAY_OF_WEEK)) {
      Calendar.SUNDAY -> "الأحد"
      Calendar.MONDAY -> "الإثنين"
      Calendar.TUESDAY -> "الثلاثاء"
      Calendar.WEDNESDAY -> "الأربعاء"
      Calendar.THURSDAY -> "الخميس"
      Calendar.FRIDAY -> "الجمعة"
      Calendar.SATURDAY -> "السبت"
      else -> ""
    }
  }

  internal fun formatArabicHijriDate(epochMs: Long, timeZone: TimeZone): String {
    val cal = Calendar.getInstance(timeZone).apply { timeInMillis = epochMs }
    val localDate = LocalDate.of(
      cal.get(Calendar.YEAR),
      cal.get(Calendar.MONTH) + 1,
      cal.get(Calendar.DAY_OF_MONTH),
    )
    val hijri = HijrahDate.from(localDate)
    val day = hijri.get(ChronoField.DAY_OF_MONTH)
    val month = hijri.get(ChronoField.MONTH_OF_YEAR)
    val year = hijri.get(ChronoField.YEAR_OF_ERA)
    val monthName = ARABIC_HIJRI_MONTHS[month - 1]
    return "$day $monthName $year هـ"
  }

  internal fun formatArabicGregorianDate(epochMs: Long, timeZone: TimeZone): String {
    val cal = Calendar.getInstance(timeZone).apply { timeInMillis = epochMs }
    val day = cal.get(Calendar.DAY_OF_MONTH)
    val month = cal.get(Calendar.MONTH)
    val year = cal.get(Calendar.YEAR)
    val monthName = ARABIC_GREGORIAN_MONTHS[month]
    return "$day $monthName $year م"
  }

  internal fun formatCountdownHhMmSs(remainingMs: Long): String {
    val totalSeconds = (remainingMs.coerceAtLeast(0L) / 1000L)
    val hours = totalSeconds / 3600L
    val minutes = (totalSeconds % 3600L) / 60L
    val seconds = totalSeconds % 60L
    return String.format(Locale.US, "%02d:%02d:%02d", hours, minutes, seconds)
  }

  private val ARABIC_HIJRI_MONTHS = listOf(
    "محرم",
    "صفر",
    "ربيع الأول",
    "ربيع الثاني",
    "جمادى الأول",
    "جمادى الثاني",
    "رجب",
    "شعبان",
    "رمضان",
    "شوال",
    "ذو القعدة",
    "ذو الحجة",
  )

  private val ARABIC_GREGORIAN_MONTHS = listOf(
    "يناير",
    "فبراير",
    "مارس",
    "أبريل",
    "مايو",
    "يونيو",
    "يوليو",
    "أغسطس",
    "سبتمبر",
    "أكتوبر",
    "نوفمبر",
    "ديسمبر",
  )

  internal fun formatArabicClock(epochMs: Long, timeZone: TimeZone): String {
    val cal = Calendar.getInstance(timeZone).apply { timeInMillis = epochMs }
    val hour24 = cal.get(Calendar.HOUR_OF_DAY)
    val hour12 = if (hour24 % 12 == 0) 12 else hour24 % 12
    val minute = cal.get(Calendar.MINUTE).toString().padStart(2, '0')
    val suffix = if (hour24 < 12) "ص" else "م"
    return "$hour12:$minute $suffix"
  }

  internal fun formatRemainingDuration(remainingMs: Long): String {
    val safeMs = remainingMs.coerceAtLeast(0L)
    val totalMinutes = safeMs / 60_000L
    val hours = totalMinutes / 60L
    val minutes = totalMinutes % 60L
    return when {
      hours > 0L -> "$hours س $minutes د"
      minutes > 0L -> "$minutes د"
      else -> "أقل من دقيقة"
    }
  }

  private data class WidgetPalette(
    val cardBgRes: Int,
    val pillBgRes: Int,
    val highlightBgRes: Int,
    val primaryText: Int,
    val secondaryText: Int,
    val mutedText: Int,
    val goldAccent: Int,
  )

  private fun resolvePalette(context: Context, isDark: Boolean): WidgetPalette {
    return if (isDark) {
      WidgetPalette(
        cardBgRes = R.drawable.widget_bg_dark,
        pillBgRes = R.drawable.widget_pill_bg_dark,
        highlightBgRes = R.drawable.widget_prayer_highlight_dark,
        primaryText = ContextCompat.getColor(context, R.color.widget_text_primary_dark),
        secondaryText = ContextCompat.getColor(context, R.color.widget_text_secondary_dark),
        mutedText = ContextCompat.getColor(context, R.color.widget_text_muted_dark),
        goldAccent = ContextCompat.getColor(context, R.color.widget_accent_gold_dark),
      )
    } else {
      WidgetPalette(
        cardBgRes = R.drawable.widget_bg_light,
        pillBgRes = R.drawable.widget_pill_bg_light,
        highlightBgRes = R.drawable.widget_prayer_highlight_light,
        primaryText = ContextCompat.getColor(context, R.color.widget_text_primary_light),
        secondaryText = ContextCompat.getColor(context, R.color.widget_text_secondary_light),
        mutedText = ContextCompat.getColor(context, R.color.widget_text_muted_light),
        goldAccent = ContextCompat.getColor(context, R.color.widget_accent_gold_light),
      )
    }
  }
}

