package com.adhkar.adkhar.widget

import android.content.Context
import es.antonborri.home_widget.HomeWidgetScheduler
import java.util.Calendar
import java.util.TimeZone

object WidgetScheduleCoordinator {
  const val PROVIDER_ADHKAR = "com.adhkar.adkhar.widget.AdhkarHomeWidgetProvider"
  const val PROVIDER_PRAYER = "com.adhkar.adkhar.widget.PrayerTimesWidgetProvider"
  const val PROVIDER_COMBINED = "com.adhkar.adkhar.widget.CombinedWidgetProvider"

  fun syncSchedule(
    context: Context,
    providerClassName: String,
    snapshot: ParsedWidgetSnapshot?,
    nowEpochMs: Long = System.currentTimeMillis(),
    timeZone: TimeZone = TimeZone.getDefault(),
  ) {
    if (snapshot == null) {
      HomeWidgetScheduler.cancel(context, providerClassName)
      return
    }

    val times = when (providerClassName) {
      PROVIDER_ADHKAR -> computeAdhkarTransitionTimes(snapshot, nowEpochMs, timeZone)
      PROVIDER_PRAYER -> computePrayerTransitionTimes(snapshot, nowEpochMs, timeZone)
      PROVIDER_COMBINED -> computeCombinedTransitionTimes(snapshot, nowEpochMs, timeZone)
      else -> emptyList()
    }

    if (times.isEmpty()) {
      HomeWidgetScheduler.cancel(context, providerClassName)
    } else {
      HomeWidgetScheduler.schedule(context, providerClassName, times)
    }
  }

  fun cancelSchedule(context: Context, providerClassName: String) {
    HomeWidgetScheduler.cancel(context, providerClassName)
  }

  fun computeAdhkarTransitionTimes(
    snapshot: ParsedWidgetSnapshot,
    nowEpochMs: Long,
    timeZone: TimeZone = TimeZone.getDefault(),
  ): List<Long> {
    val times = LinkedHashSet<Long>()
    for (day in snapshot.dailyAdhkarDays) {
      midnightForDateKey(day.localDate, timeZone)?.let { midnightMs ->
        times.add(midnightMs + 5_000L) // +5s buffer past 00:00
        times.add(midnightMs + (snapshot.morningStartMinutes * 60_000L) + 1_000L)
        times.add(midnightMs + (snapshot.eveningStartMinutes * 60_000L) + 1_000L)
      }
    }
    return times.filter { it > nowEpochMs }.sorted()
  }

  fun computePrayerTransitionTimes(
    snapshot: ParsedWidgetSnapshot,
    nowEpochMs: Long,
    timeZone: TimeZone = TimeZone.getDefault(),
  ): List<Long> {
    val times = LinkedHashSet<Long>()
    for (day in snapshot.prayerDays) {
      for ((_, eventMs) in day.obligatoryEvents()) {
        times.add(eventMs + 1_000L) // +1s past prayer instant so Chronometer transitions cleanly
        val subHourBoundaryMs = eventMs - 3_599_500L
        if (subHourBoundaryMs > nowEpochMs) {
          times.add(subHourBoundaryMs) // Refresh below 1h so Chronometer switches from H:MM:SS to 00:MM:SS
        }
      }
      times.add(day.tomorrowFajrUtcEpochMs + 1_000L)
      val tomorrowSubHourMs = day.tomorrowFajrUtcEpochMs - 3_599_500L
      if (tomorrowSubHourMs > nowEpochMs) {
        times.add(tomorrowSubHourMs)
      }
      midnightForDateKey(day.localDate, timeZone)?.let { midnightMs ->
        times.add(midnightMs + 5_000L)
      }
    }
    if (times.isEmpty()) {
      for (day in snapshot.dailyAdhkarDays) {
        midnightForDateKey(day.localDate, timeZone)?.let { times.add(it + 5_000L) }
      }
    }
    return times.filter { it > nowEpochMs }.sorted()
  }

  fun computeCombinedTransitionTimes(
    snapshot: ParsedWidgetSnapshot,
    nowEpochMs: Long,
    timeZone: TimeZone = TimeZone.getDefault(),
  ): List<Long> {
    val combined = LinkedHashSet<Long>()
    combined.addAll(computeAdhkarTransitionTimes(snapshot, nowEpochMs, timeZone))
    combined.addAll(computePrayerTransitionTimes(snapshot, nowEpochMs, timeZone))
    return combined.filter { it > nowEpochMs }.sorted()
  }

  private fun midnightForDateKey(dateKey: String, timeZone: TimeZone): Long? {
    val parts = dateKey.split("-")
    if (parts.size != 3) return null
    return try {
      val cal = Calendar.getInstance(timeZone).apply {
        clear()
        set(parts[0].toInt(), parts[1].toInt() - 1, parts[2].toInt(), 0, 0, 0)
      }
      cal.timeInMillis
    } catch (_: Exception) {
      null
    }
  }
}

