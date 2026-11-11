package com.adhkar.adkhar.widget

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.util.Calendar
import java.util.TimeZone

class PrayerWidgetFormatterTest {
  private val utcZone: TimeZone = TimeZone.getTimeZone("UTC")

  private fun utcEpoch(year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int = 0): Long {
    val cal = Calendar.getInstance(utcZone).apply {
      clear()
      set(year, month - 1, day, hour, minute, second)
    }
    return cal.timeInMillis
  }

  @Test
  fun formatsArabicWeekdayHijriAndGregorianDatesAndUpdatesAtMidnight() {
    val beforeMidnight = utcEpoch(2026, 11, 11, 23, 59, 50)
    assertEquals("الأربعاء", WidgetUiBinder.formatArabicWeekday(beforeMidnight, utcZone))
    assertEquals("11 نوفمبر 2026 م", WidgetUiBinder.formatArabicGregorianDate(beforeMidnight, utcZone))
    val hijriBefore = WidgetUiBinder.formatArabicHijriDate(beforeMidnight, utcZone)
    assertTrue(hijriBefore.endsWith("هـ"))

    val afterMidnight = utcEpoch(2026, 11, 12, 0, 0, 5)
    assertEquals("الخميس", WidgetUiBinder.formatArabicWeekday(afterMidnight, utcZone))
    assertEquals("12 نوفمبر 2026 م", WidgetUiBinder.formatArabicGregorianDate(afterMidnight, utcZone))
    val hijriAfter = WidgetUiBinder.formatArabicHijriDate(afterMidnight, utcZone)
    assertTrue(hijriAfter.endsWith("هـ"))
    assertFalse(hijriBefore == hijriAfter)
  }

  @Test
  fun formatsCountdownAsHhMmSsWithZeroPadding() {
    assertEquals("00:00:00", WidgetUiBinder.formatCountdownHhMmSs(0L))
    assertEquals("00:05:09", WidgetUiBinder.formatCountdownHhMmSs((5 * 60 + 9) * 1000L))
    assertEquals("03:45:12", WidgetUiBinder.formatCountdownHhMmSs((3 * 3600 + 45 * 60 + 12) * 1000L))
    assertEquals("12:00:01", WidgetUiBinder.formatCountdownHhMmSs((12 * 3600 + 1) * 1000L))
  }

  @Test
  fun formatsArabicClockWithAmPmSuffix() {
    assertEquals("4:52 ص", WidgetUiBinder.formatArabicClock(utcEpoch(2026, 11, 11, 4, 52), utcZone))
    assertEquals("12:15 م", WidgetUiBinder.formatArabicClock(utcEpoch(2026, 11, 11, 12, 15), utcZone))
    assertEquals("7:05 م", WidgetUiBinder.formatArabicClock(utcEpoch(2026, 11, 11, 19, 5), utcZone))
  }
}

