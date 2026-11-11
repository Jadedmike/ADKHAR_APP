package com.adhkar.adkhar.widget

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.util.Calendar
import java.util.TimeZone

class WidgetSnapshotReaderTest {
  private val utcZone: TimeZone = TimeZone.getTimeZone("UTC")

  private fun utcEpoch(year: Int, month: Int, day: Int, hour: Int, minute: Int): Long {
    val cal = Calendar.getInstance(utcZone).apply {
      clear()
      set(year, month - 1, day, hour, minute, 0)
    }
    return cal.timeInMillis
  }

  private fun sampleSnapshotJson(
    themePreference: String = "light",
    hasSavedLocation: Boolean = true,
    prayerDataAvailable: Boolean = true,
    schemaVersion: Int = 1,
    morningStartMinutes: Int = 360,
    eveningStartMinutes: Int = 1020,
  ): String {
    val day1 = "2026-11-11"
    val day2 = "2026-11-12"

    val f1 = utcEpoch(2026, 11, 11, 5, 0)
    val s1 = utcEpoch(2026, 11, 11, 6, 30)
    val d1 = utcEpoch(2026, 11, 11, 12, 0)
    val a1 = utcEpoch(2026, 11, 11, 15, 15)
    val m1 = utcEpoch(2026, 11, 11, 17, 45)
    val i1 = utcEpoch(2026, 11, 11, 19, 10)
    val f2 = utcEpoch(2026, 11, 12, 5, 2)
    val s2 = utcEpoch(2026, 11, 12, 6, 31)
    val d2 = utcEpoch(2026, 11, 12, 12, 0)
    val a2 = utcEpoch(2026, 11, 12, 15, 14)
    val m2 = utcEpoch(2026, 11, 12, 17, 44)
    val i2 = utcEpoch(2026, 11, 12, 19, 9)
    val f3 = utcEpoch(2026, 11, 13, 5, 3)

    val prayerDaysJson = if (hasSavedLocation && prayerDataAvailable) {
      """
      [
        {
          "localDate": "$day1",
          "fajrUtcEpochMs": $f1,
          "sunriseUtcEpochMs": $s1,
          "dhuhrUtcEpochMs": $d1,
          "asrUtcEpochMs": $a1,
          "maghribUtcEpochMs": $m1,
          "ishaUtcEpochMs": $i1,
          "tomorrowFajrUtcEpochMs": $f2
        },
        {
          "localDate": "$day2",
          "fajrUtcEpochMs": $f2,
          "sunriseUtcEpochMs": $s2,
          "dhuhrUtcEpochMs": $d2,
          "asrUtcEpochMs": $a2,
          "maghribUtcEpochMs": $m2,
          "ishaUtcEpochMs": $i2,
          "tomorrowFajrUtcEpochMs": $f3
        }
      ]
      """
    } else {
      "[]"
    }

    val displayNameJson = if (hasSavedLocation) "\"تركيا، إسطنبول، الفاتح\"" else "null"

    return """
    {
      "schemaVersion": $schemaVersion,
      "generatedAtUtcEpochMs": ${utcEpoch(2026, 11, 11, 4, 0)},
      "hasSavedLocation": $hasSavedLocation,
      "prayerDataAvailable": $prayerDataAvailable,
      "prayerUnavailablePrompt": "تعذر حساب مواقيت الصلاة حالياً",
      "themePreference": "$themePreference",
      "themeModeLabel": "فاتح",
      "location": {
        "hasSavedLocation": $hasSavedLocation,
        "locationFingerprint": ${if (hasSavedLocation) "\"0123456789abcdef0123456789abcdef\"" else "null"},
        "displayName": $displayNameJson,
        "isoCountryCode": "TR",
        "calculationMethodKey": "turkey",
        "calculationMethodLabel": "تركيا (رئاسة الشؤون الدينية)",
        "madhabKey": "shafi",
        "madhabLabel": "الشافعي (الجمهور)",
        "missingLocationPrompt": "افتح التطبيق لتحديد الموقع"
      },
      "cutoffs": {
        "morningStartMinutes": $morningStartMinutes,
        "eveningStartMinutes": $eveningStartMinutes,
        "morningStartFormatted": "06:00",
        "eveningStartFormatted": "17:00",
        "morningReminderEnabled": true,
        "eveningReminderEnabled": true
      },
      "dailyAdhkarDays": [
        {
          "localDate": "$day1",
          "dhikr": { "text": "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، سُبْحَانَ اللَّهِ الْعَظِيمِ.", "source": "رواه البخاري ومسلم", "categoryTitle": "أذكار اليوم" },
          "dua": { "text": "دعاء", "source": "مصدر", "categoryTitle": "أدعية اليوم" },
          "ayah": { "text": "آية", "source": "سورة", "categoryTitle": "آية عشوائية" },
          "quote": { "text": "اقتباس", "source": "سورة", "categoryTitle": "اقتباس إسلامي" }
        },
        {
          "localDate": "$day2",
          "dhikr": { "text": "أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ.", "source": "رواه البخاري", "categoryTitle": "أذكار اليوم" },
          "dua": { "text": "دعاء ٢", "source": "مصدر", "categoryTitle": "أدعية اليوم" },
          "ayah": { "text": "آية ٢", "source": "سورة", "categoryTitle": "آية عشوائية" },
          "quote": { "text": "اقتباس ٢", "source": "سورة", "categoryTitle": "اقتباس إسلامي" }
        }
      ],
      "morningAdhkar": [
        { "id": "m1", "order": 1, "text": "أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ", "source": "صحيح مسلم", "count": 1, "countDescription": "مرة" }
      ],
      "eveningAdhkar": [
        { "id": "e1", "order": 1, "text": "أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ", "source": "صحيح مسلم", "count": 1, "countDescription": "مرة" }
      ],
      "prayerDays": $prayerDaysJson
    }
    """.trimIndent()
  }

  @Test
  fun parsesSnapshotAndPreservesArabicText() {
    val parsed = WidgetSnapshotReader.parseSnapshot(sampleSnapshotJson())
    assertNotNull(parsed)
    assertEquals(1, parsed!!.schemaVersion)
    assertEquals("تركيا، إسطنبول، الفاتح", parsed.locationDisplayName)
    assertEquals("سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، سُبْحَانَ اللَّهِ الْعَظِيمِ.", parsed.dailyAdhkarDays.first().dhikr.text)
    assertEquals("أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ", parsed.morningAdhkar.first().text)
    assertEquals("أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ", parsed.eveningAdhkar.first().text)
    assertEquals(2, parsed.prayerDays.size)
  }

  @Test
  fun resolvesMorningAndEveningCutoffsAccurately() {
    val json = sampleSnapshotJson(morningStartMinutes = 360, eveningStartMinutes = 1020)

    val morningState = WidgetSnapshotReader.resolveFromRawJson(
      rawJson = json,
      nowEpochMs = utcEpoch(2026, 11, 11, 9, 0),
      timeZone = utcZone,
    )
    assertEquals(AdhkarPeriod.MORNING, morningState.periodDhikr?.period)
    assertEquals("أذكار الصباح", morningState.periodDhikr?.badgeTitle)
    assertEquals("أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ", morningState.periodDhikr?.text)

    val eveningState = WidgetSnapshotReader.resolveFromRawJson(
      rawJson = json,
      nowEpochMs = utcEpoch(2026, 11, 11, 18, 0),
      timeZone = utcZone,
    )
    assertEquals(AdhkarPeriod.EVENING, eveningState.periodDhikr?.period)
    assertEquals("أذكار المساء", eveningState.periodDhikr?.badgeTitle)
    assertEquals("أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ", eveningState.periodDhikr?.text)
  }

  @Test
  fun skipsSunriseAndHandlesAfterIshaAndMidnightRollover() {
    val json = sampleSnapshotJson()

    // Between Fajr (05:00) and Sunrise (06:30) -> next obligatory prayer must be Dhuhr (not Sunrise).
    val afterFajr = WidgetSnapshotReader.resolveFromRawJson(
      rawJson = json,
      nowEpochMs = utcEpoch(2026, 11, 11, 5, 30),
      timeZone = utcZone,
    )
    assertEquals(PrayerWidgetStatus.AVAILABLE, afterFajr.prayerStatus)
    assertEquals("الظهر", afterFajr.nextPrayerName)
    assertFalse(afterFajr.isNextPrayerTomorrow)
    assertEquals(6, afterFajr.dailyPrayerRows.size)
    assertFalse(afterFajr.dailyPrayerRows[1].isObligatory) // Sunrise row

    // After Isha (19:30) on Nov 11 -> rolls over to Nov 12 Fajr (isNextPrayerTomorrow = true).
    val afterIsha = WidgetSnapshotReader.resolveFromRawJson(
      rawJson = json,
      nowEpochMs = utcEpoch(2026, 11, 11, 19, 30),
      timeZone = utcZone,
    )
    assertEquals("الفجر", afterIsha.nextPrayerName)
    assertTrue(afterIsha.isNextPrayerTomorrow)
    assertEquals(utcEpoch(2026, 11, 12, 5, 2), afterIsha.nextPrayerTimeEpochMs)

    // After midnight (00:05) on Nov 12 -> picks Nov 12 daily Dhikr & Nov 12 Fajr (isTomorrow = false).
    val afterMidnight = WidgetSnapshotReader.resolveFromRawJson(
      rawJson = json,
      nowEpochMs = utcEpoch(2026, 11, 12, 0, 5),
      timeZone = utcZone,
    )
    assertEquals("أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ.", afterMidnight.dailyShortDhikr?.text)
    assertEquals("الفجر", afterMidnight.nextPrayerName)
    assertFalse(afterMidnight.isNextPrayerTomorrow)
    assertEquals(utcEpoch(2026, 11, 12, 5, 2), afterMidnight.nextPrayerTimeEpochMs)
  }

  @Test
  fun handlesMissingLocationAndUnavailablePrayerDataStates() {
    val missingLocState = WidgetSnapshotReader.resolveFromRawJson(
      rawJson = sampleSnapshotJson(hasSavedLocation = false, prayerDataAvailable = false),
      nowEpochMs = utcEpoch(2026, 11, 11, 9, 0),
      timeZone = utcZone,
    )
    assertEquals(PrayerWidgetStatus.MISSING_LOCATION, missingLocState.prayerStatus)
    assertNull(missingLocState.locationDisplayName)
    assertEquals(WidgetSnapshotReader.PROMPT_MISSING_LOCATION, missingLocState.promptMessage)
    assertNotNull(missingLocState.dailyShortDhikr)

    val unavailableState = WidgetSnapshotReader.resolveFromRawJson(
      rawJson = sampleSnapshotJson(hasSavedLocation = true, prayerDataAvailable = false),
      nowEpochMs = utcEpoch(2026, 11, 11, 9, 0),
      timeZone = utcZone,
    )
    assertEquals(PrayerWidgetStatus.UNAVAILABLE, unavailableState.prayerStatus)
    assertEquals("تركيا، إسطنبول، الفاتح", unavailableState.locationDisplayName)
    assertEquals(WidgetSnapshotReader.PROMPT_PRAYER_UNAVAILABLE, unavailableState.promptMessage)
  }

  @Test
  fun handlesMissingCorruptAndExpiredSnapshotsSafely() {
    val missing = WidgetSnapshotReader.resolveFromRawJson(null, timeZone = utcZone)
    assertEquals(SnapshotHealth.MISSING, missing.health)
    assertEquals(PrayerWidgetStatus.MISSING_SNAPSHOT, missing.prayerStatus)

    val corrupt = WidgetSnapshotReader.resolveFromRawJson("{bad json", timeZone = utcZone)
    assertEquals(SnapshotHealth.CORRUPT, corrupt.health)
    assertEquals(PrayerWidgetStatus.CORRUPT, corrupt.prayerStatus)

    val wrongVersion = WidgetSnapshotReader.parseSnapshot(sampleSnapshotJson(schemaVersion = 99))
    assertNull(wrongVersion)

    val expired = WidgetSnapshotReader.resolveFromRawJson(
      rawJson = sampleSnapshotJson(),
      nowEpochMs = utcEpoch(2026, 11, 20, 10, 0), // far past horizon
      timeZone = utcZone,
    )
    assertEquals(SnapshotHealth.EXPIRED, expired.health)
    assertEquals(PrayerWidgetStatus.EXPIRED, expired.prayerStatus)
  }

  @Test
  fun resolvesLightDarkAndSystemThemeModes() {
    val lightState = WidgetSnapshotReader.resolveFromRawJson(
      rawJson = sampleSnapshotJson(themePreference = "light"),
      nowEpochMs = utcEpoch(2026, 11, 11, 9, 0),
      timeZone = utcZone,
      isSystemDark = true,
    )
    assertFalse(lightState.isDarkTheme)

    val darkState = WidgetSnapshotReader.resolveFromRawJson(
      rawJson = sampleSnapshotJson(themePreference = "dark"),
      nowEpochMs = utcEpoch(2026, 11, 11, 9, 0),
      timeZone = utcZone,
      isSystemDark = false,
    )
    assertTrue(darkState.isDarkTheme)

    val systemDarkState = WidgetSnapshotReader.resolveFromRawJson(
      rawJson = sampleSnapshotJson(themePreference = "system"),
      nowEpochMs = utcEpoch(2026, 11, 11, 9, 0),
      timeZone = utcZone,
      isSystemDark = true,
    )
    assertTrue(systemDarkState.isDarkTheme)
  }

  @Test
  fun schedulesOnlyFutureTransitionTimestamps() {
    val parsed = WidgetSnapshotReader.parseSnapshot(sampleSnapshotJson())!!
    val nowMs = utcEpoch(2026, 11, 11, 14, 0)

    val prayerTimes = WidgetScheduleCoordinator.computePrayerTransitionTimes(parsed, nowMs, utcZone)
    assertTrue(prayerTimes.isNotEmpty())
    assertTrue(prayerTimes.all { it > nowMs })
    assertEquals(prayerTimes.sorted(), prayerTimes)

    val adhkarTimes = WidgetScheduleCoordinator.computeAdhkarTransitionTimes(parsed, nowMs, utcZone)
    assertTrue(adhkarTimes.isNotEmpty())
    assertTrue(adhkarTimes.all { it > nowMs })
  }
}

