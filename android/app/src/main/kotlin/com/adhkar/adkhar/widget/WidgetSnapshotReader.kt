package com.adhkar.adkhar.widget

import android.content.SharedPreferences
import java.util.Calendar
import java.util.TimeZone

internal object WidgetJsonParser {
  fun parseObject(raw: String): Map<String, Any?>? {
    val trimmed = raw.trim()
    if (trimmed.isEmpty() || trimmed[0] != '{') return null
    return try {
      val cursor = Cursor(trimmed)
      val value = parseValue(cursor)
      skipWhitespace(cursor)
      if (cursor.index != trimmed.length) null else value as? Map<String, Any?>
    } catch (_: Exception) {
      null
    }
  }

  private class Cursor(val text: String) {
    var index: Int = 0
    fun hasMore(): Boolean = index < text.length
    fun peek(): Char = text[index]
    fun next(): Char = text[index++]
  }

  private fun skipWhitespace(c: Cursor) {
    while (c.hasMore()) {
      when (c.peek()) {
        ' ', '\t', '\n', '\r' -> c.index++
        else -> return
      }
    }
  }

  private fun parseValue(c: Cursor): Any? {
    skipWhitespace(c)
    if (!c.hasMore()) throw IllegalStateException("Unexpected end of JSON")
    return when (c.peek()) {
      '{' -> parseObjectInternal(c)
      '[' -> parseArrayInternal(c)
      '"' -> parseString(c)
      't' -> expectLiteral(c, "true", true)
      'f' -> expectLiteral(c, "false", false)
      'n' -> expectLiteral(c, "null", null)
      '-', in '0'..'9' -> parseNumber(c)
      else -> throw IllegalStateException("Unexpected JSON token at ${c.index}")
    }
  }

  private fun expectLiteral(c: Cursor, literal: String, value: Any?): Any? {
    if (!c.text.regionMatches(c.index, literal, 0, literal.length)) {
      throw IllegalStateException("Invalid literal at ${c.index}")
    }
    c.index += literal.length
    return value
  }

  private fun parseObjectInternal(c: Cursor): Map<String, Any?> {
    c.next() // '{'
    val map = LinkedHashMap<String, Any?>()
    skipWhitespace(c)
    if (c.hasMore() && c.peek() == '}') {
      c.next()
      return map
    }
    while (true) {
      skipWhitespace(c)
      if (!c.hasMore() || c.peek() != '"') {
        throw IllegalStateException("Expected object key at ${c.index}")
      }
      val key = parseString(c)
      skipWhitespace(c)
      if (!c.hasMore() || c.next() != ':') {
        throw IllegalStateException("Expected ':' after key at ${c.index}")
      }
      val value = parseValue(c)
      map[key] = value
      skipWhitespace(c)
      if (!c.hasMore()) throw IllegalStateException("Unterminated object")
      when (c.next()) {
        '}' -> return map
        ',' -> continue
        else -> throw IllegalStateException("Expected ',' or '}' at ${c.index}")
      }
    }
  }

  private fun parseArrayInternal(c: Cursor): List<Any?> {
    c.next() // '['
    val list = ArrayList<Any?>()
    skipWhitespace(c)
    if (c.hasMore() && c.peek() == ']') {
      c.next()
      return list
    }
    while (true) {
      list.add(parseValue(c))
      skipWhitespace(c)
      if (!c.hasMore()) throw IllegalStateException("Unterminated array")
      when (c.next()) {
        ']' -> return list
        ',' -> continue
        else -> throw IllegalStateException("Expected ',' or ']' at ${c.index}")
      }
    }
  }

  private fun parseString(c: Cursor): String {
    c.next() // opening '"'
    val sb = StringBuilder()
    while (c.hasMore()) {
      val ch = c.next()
      if (ch == '"') return sb.toString()
      if (ch == '\\') {
        if (!c.hasMore()) throw IllegalStateException("Unterminated escape")
        when (val esc = c.next()) {
          '"' -> sb.append('"')
          '\\' -> sb.append('\\')
          '/' -> sb.append('/')
          'b' -> sb.append('\b')
          'f' -> sb.append('\u000C')
          'n' -> sb.append('\n')
          'r' -> sb.append('\r')
          't' -> sb.append('\t')
          'u' -> {
            if (c.index + 4 > c.text.length) {
              throw IllegalStateException("Invalid unicode escape")
            }
            val hex = c.text.substring(c.index, c.index + 4)
            c.index += 4
            sb.append(hex.toInt(16).toChar())
          }
          else -> throw IllegalStateException("Invalid escape '\\$esc'")
        }
      } else {
        sb.append(ch)
      }
    }
    throw IllegalStateException("Unterminated string")
  }

  private fun parseNumber(c: Cursor): Number {
    val start = c.index
    if (c.peek() == '-') c.index++
    var isDouble = false
    while (c.hasMore()) {
      val ch = c.peek()
      if (ch in '0'..'9') {
        c.index++
      } else if (ch == '.' || ch == 'e' || ch == 'E' || ch == '+' || ch == '-') {
        if (ch == '-' && c.index == start) {
          c.index++
        } else if (ch == '+' || ch == '-' || ch == '.' || ch == 'e' || ch == 'E') {
          isDouble = true
          c.index++
        } else {
          break
        }
      } else {
        break
      }
    }
    val token = c.text.substring(start, c.index)
    return if (isDouble) token.toDouble() else token.toLong()
  }
}

enum class SnapshotHealth {
  VALID,
  MISSING,
  CORRUPT,
  EXPIRED,
}

enum class AdhkarPeriod(val queryValue: String, val arabicLabel: String) {
  MORNING("morning", "أذكار الصباح"),
  EVENING("evening", "أذكار المساء"),
}

enum class PrayerWidgetStatus {
  AVAILABLE,
  MISSING_LOCATION,
  UNAVAILABLE,
  EXPIRED,
  MISSING_SNAPSHOT,
  CORRUPT,
}

data class ParsedTextItem(
  val text: String,
  val source: String,
  val categoryTitle: String,
)

data class ParsedPeriodDhikr(
  val id: String,
  val order: Int,
  val text: String,
  val source: String,
  val count: Int,
  val countDescription: String,
)

data class ParsedDailyAdhkarDay(
  val localDate: String,
  val dhikr: ParsedTextItem,
  val dua: ParsedTextItem,
  val ayah: ParsedTextItem,
  val quote: ParsedTextItem,
)

data class ParsedPrayerDay(
  val localDate: String,
  val fajrUtcEpochMs: Long,
  val sunriseUtcEpochMs: Long,
  val dhuhrUtcEpochMs: Long,
  val asrUtcEpochMs: Long,
  val maghribUtcEpochMs: Long,
  val ishaUtcEpochMs: Long,
  val tomorrowFajrUtcEpochMs: Long,
) {
  fun obligatoryEvents(): List<Pair<String, Long>> = listOf(
    "الفجر" to fajrUtcEpochMs,
    "الظهر" to dhuhrUtcEpochMs,
    "العصر" to asrUtcEpochMs,
    "المغرب" to maghribUtcEpochMs,
    "العشاء" to ishaUtcEpochMs,
  )

  fun hasValidOrder(): Boolean =
    fajrUtcEpochMs > 0L &&
      fajrUtcEpochMs < sunriseUtcEpochMs &&
      sunriseUtcEpochMs < dhuhrUtcEpochMs &&
      dhuhrUtcEpochMs < asrUtcEpochMs &&
      asrUtcEpochMs < maghribUtcEpochMs &&
      maghribUtcEpochMs < ishaUtcEpochMs &&
      ishaUtcEpochMs < tomorrowFajrUtcEpochMs
}

data class ParsedWidgetSnapshot(
  val schemaVersion: Int,
  val generatedAtUtcEpochMs: Long,
  val hasSavedLocation: Boolean,
  val prayerDataAvailable: Boolean,
  val prayerUnavailablePrompt: String,
  val themePreference: String,
  val locationDisplayName: String?,
  val calculationMethodLabel: String?,
  val madhabLabel: String?,
  val missingLocationPrompt: String,
  val morningStartMinutes: Int,
  val eveningStartMinutes: Int,
  val dailyAdhkarDays: List<ParsedDailyAdhkarDay>,
  val morningAdhkar: List<ParsedPeriodDhikr>,
  val eveningAdhkar: List<ParsedPeriodDhikr>,
  val prayerDays: List<ParsedPrayerDay>,
) {
  fun resolvePeriod(hour: Int, minute: Int): AdhkarPeriod {
    val minuteOfDay = (hour * 60) + minute
    return when {
      morningStartMinutes < eveningStartMinutes ->
        if (minuteOfDay in morningStartMinutes until eveningStartMinutes) {
          AdhkarPeriod.MORNING
        } else {
          AdhkarPeriod.EVENING
        }
      morningStartMinutes > eveningStartMinutes ->
        if (minuteOfDay >= morningStartMinutes || minuteOfDay < eveningStartMinutes) {
          AdhkarPeriod.MORNING
        } else {
          AdhkarPeriod.EVENING
        }
      else -> AdhkarPeriod.MORNING
    }
  }
}

data class WidgetDhikrDisplay(
  val text: String,
  val source: String,
  val badgeTitle: String,
  val period: AdhkarPeriod?,
)

data class WidgetPrayerRow(
  val arabicName: String,
  val utcEpochMs: Long,
  val isObligatory: Boolean,
  val isNext: Boolean,
)

data class ResolvedWidgetState(
  val health: SnapshotHealth,
  val isDarkTheme: Boolean,
  val periodDhikr: WidgetDhikrDisplay?,
  val dailyShortDhikr: WidgetDhikrDisplay?,
  val prayerStatus: PrayerWidgetStatus,
  val locationDisplayName: String?,
  val calculationMethodLabel: String?,
  val madhabLabel: String?,
  val nextPrayerName: String?,
  val nextPrayerTimeEpochMs: Long?,
  val nextPrayerRemainingMs: Long?,
  val isNextPrayerTomorrow: Boolean,
  val dailyPrayerRows: List<WidgetPrayerRow>,
  val promptMessage: String,
)

object WidgetSnapshotReader {
  const val SNAPSHOT_STORAGE_KEY = "adhkar_widget_snapshot_v1_json"
  const val SUPPORTED_SCHEMA_VERSION = 1

  const val PROMPT_FIRST_LAUNCH = "افتح التطبيق لتحديث الأذكار والمواقيت"
  const val PROMPT_CORRUPT_DATA = "تعذر قراءة البيانات، افتح التطبيق للتحديث"
  const val PROMPT_EXPIRED_DATA = "انتهت صلاحية البيانات، افتح التطبيق للتحديث"
  const val PROMPT_MISSING_LOCATION = "افتح التطبيق لتحديد الموقع"
  const val PROMPT_PRAYER_UNAVAILABLE = "تعذر حساب مواقيت الصلاة حالياً"

  fun readSnapshot(prefs: SharedPreferences): ParsedWidgetSnapshot? =
    parseSnapshot(prefs.getString(SNAPSHOT_STORAGE_KEY, null))

  fun resolveFromPreferences(
    prefs: SharedPreferences,
    nowEpochMs: Long = System.currentTimeMillis(),
    timeZone: TimeZone = TimeZone.getDefault(),
    isSystemDark: Boolean = false,
  ): ResolvedWidgetState {
    val raw = prefs.getString(SNAPSHOT_STORAGE_KEY, null)
    return resolveFromRawJson(raw, nowEpochMs, timeZone, isSystemDark)
  }

  fun resolveFromRawJson(
    rawJson: String?,
    nowEpochMs: Long = System.currentTimeMillis(),
    timeZone: TimeZone = TimeZone.getDefault(),
    isSystemDark: Boolean = false,
  ): ResolvedWidgetState {
    if (rawJson == null || rawJson.isBlank()) {
      return ResolvedWidgetState(
        health = SnapshotHealth.MISSING,
        isDarkTheme = isSystemDark,
        periodDhikr = null,
        dailyShortDhikr = null,
        prayerStatus = PrayerWidgetStatus.MISSING_SNAPSHOT,
        locationDisplayName = null,
        calculationMethodLabel = null,
        madhabLabel = null,
        nextPrayerName = null,
        nextPrayerTimeEpochMs = null,
        nextPrayerRemainingMs = null,
        isNextPrayerTomorrow = false,
        dailyPrayerRows = emptyList(),
        promptMessage = PROMPT_FIRST_LAUNCH,
      )
    }

    val snapshot = parseSnapshot(rawJson)
    if (snapshot == null) {
      return ResolvedWidgetState(
        health = SnapshotHealth.CORRUPT,
        isDarkTheme = isSystemDark,
        periodDhikr = null,
        dailyShortDhikr = null,
        prayerStatus = PrayerWidgetStatus.CORRUPT,
        locationDisplayName = null,
        calculationMethodLabel = null,
        madhabLabel = null,
        nextPrayerName = null,
        nextPrayerTimeEpochMs = null,
        nextPrayerRemainingMs = null,
        isNextPrayerTomorrow = false,
        dailyPrayerRows = emptyList(),
        promptMessage = PROMPT_CORRUPT_DATA,
      )
    }

    return resolveState(snapshot, nowEpochMs, timeZone, isSystemDark)
  }

  fun parseSnapshot(rawJson: String?): ParsedWidgetSnapshot? {
    if (rawJson == null || rawJson.isBlank()) return null
    val root = WidgetJsonParser.parseObject(rawJson) ?: return null

    val schemaVersion = (root["schemaVersion"] as? Number)?.toInt() ?: return null
    if (schemaVersion != SUPPORTED_SCHEMA_VERSION) return null

    val generatedAt = (root["generatedAtUtcEpochMs"] as? Number)?.toLong() ?: return null
    if (generatedAt <= 0L) return null

    val hasSavedLocation = root["hasSavedLocation"] as? Boolean ?: return null
    val prayerDataAvailable = root["prayerDataAvailable"] as? Boolean ?: return null
    if (prayerDataAvailable && !hasSavedLocation) return null

    val prayerUnavailablePrompt =
      (root["prayerUnavailablePrompt"] as? String)?.trim().takeUnless { it.isNullOrEmpty() }
        ?: PROMPT_PRAYER_UNAVAILABLE

    val themePreference = root["themePreference"] as? String ?: "light"

    val locMap = root["location"] as? Map<*, *> ?: return null
    val locHasSaved = locMap["hasSavedLocation"] as? Boolean ?: return null
    if (locHasSaved != hasSavedLocation) return null

    val displayName = (locMap["displayName"] as? String)?.trim()?.takeIf { it.isNotEmpty() }
    val methodLabel = (locMap["calculationMethodLabel"] as? String)?.trim()?.takeIf { it.isNotEmpty() }
    val madhabLabel = (locMap["madhabLabel"] as? String)?.trim()?.takeIf { it.isNotEmpty() }
    val missingPrompt =
      (locMap["missingLocationPrompt"] as? String)?.trim().takeUnless { it.isNullOrEmpty() }
        ?: PROMPT_MISSING_LOCATION

    val cutoffsMap = root["cutoffs"] as? Map<*, *> ?: return null
    val morningMin = (cutoffsMap["morningStartMinutes"] as? Number)?.toInt() ?: 360
    val eveningMin = (cutoffsMap["eveningStartMinutes"] as? Number)?.toInt() ?: 1020
    if (morningMin !in 0 until 1440 || eveningMin !in 0 until 1440) return null

    val dailyRaw = root["dailyAdhkarDays"] as? List<*> ?: return null
    val dailyDays = dailyRaw.mapNotNull { parseDailyDay(it as? Map<*, *>) }
    if (dailyDays.size != dailyRaw.size || dailyDays.isEmpty()) return null

    val morningRaw = root["morningAdhkar"] as? List<*> ?: emptyList<Any?>()
    val morningList = morningRaw.mapNotNull { parsePeriodDhikr(it as? Map<*, *>) }

    val eveningRaw = root["eveningAdhkar"] as? List<*> ?: emptyList<Any?>()
    val eveningList = eveningRaw.mapNotNull { parsePeriodDhikr(it as? Map<*, *>) }

    val prayerRaw = root["prayerDays"] as? List<*> ?: emptyList<Any?>()
    val prayerDays = prayerRaw.mapNotNull { parsePrayerDay(it as? Map<*, *>) }
    if (prayerDataAvailable && (prayerDays.size != prayerRaw.size || prayerDays.isEmpty())) {
      return null
    }
    if (prayerDataAvailable && prayerDays.any { !it.hasValidOrder() }) {
      return null
    }

    return ParsedWidgetSnapshot(
      schemaVersion = schemaVersion,
      generatedAtUtcEpochMs = generatedAt,
      hasSavedLocation = hasSavedLocation,
      prayerDataAvailable = prayerDataAvailable,
      prayerUnavailablePrompt = prayerUnavailablePrompt,
      themePreference = themePreference,
      locationDisplayName = if (hasSavedLocation) displayName else null,
      calculationMethodLabel = methodLabel,
      madhabLabel = madhabLabel,
      missingLocationPrompt = missingPrompt,
      morningStartMinutes = morningMin,
      eveningStartMinutes = eveningMin,
      dailyAdhkarDays = dailyDays,
      morningAdhkar = morningList,
      eveningAdhkar = eveningList,
      prayerDays = if (prayerDataAvailable) prayerDays else emptyList(),
    )
  }

  fun resolveState(
    snapshot: ParsedWidgetSnapshot,
    nowEpochMs: Long = System.currentTimeMillis(),
    timeZone: TimeZone = TimeZone.getDefault(),
    isSystemDark: Boolean = false,
  ): ResolvedWidgetState {
    val isDark = when (snapshot.themePreference) {
      "dark" -> true
      "light" -> false
      else -> isSystemDark
    }

    val cal = Calendar.getInstance(timeZone).apply { timeInMillis = nowEpochMs }
    val todayKey = formatCalendarDate(cal)
    val hour = cal.get(Calendar.HOUR_OF_DAY)
    val minute = cal.get(Calendar.MINUTE)
    val dayOfYear = cal.get(Calendar.DAY_OF_YEAR)

    val matchingDaily = snapshot.dailyAdhkarDays.firstOrNull { it.localDate == todayKey }
    val dailyShort = matchingDaily?.let {
      WidgetDhikrDisplay(
        text = it.dhikr.text,
        source = it.dhikr.source,
        badgeTitle = it.dhikr.categoryTitle.ifBlank { "ذكر اليوم" },
        period = null,
      )
    }

    val activePeriod = snapshot.resolvePeriod(hour, minute)
    val periodPool = when (activePeriod) {
      AdhkarPeriod.MORNING -> snapshot.morningAdhkar
      AdhkarPeriod.EVENING -> snapshot.eveningAdhkar
    }

    val periodDhikr = when {
      matchingDaily == null -> null
      periodPool.isNotEmpty() -> {
        val selected = periodPool[(dayOfYear - 1).coerceAtLeast(0) % periodPool.size]
        WidgetDhikrDisplay(
          text = selected.text,
          source = selected.source,
          badgeTitle = activePeriod.arabicLabel,
          period = activePeriod,
        )
      }
      else -> dailyShort
    }

    if (!snapshot.hasSavedLocation) {
      return ResolvedWidgetState(
        health = if (matchingDaily != null) SnapshotHealth.VALID else SnapshotHealth.EXPIRED,
        isDarkTheme = isDark,
        periodDhikr = periodDhikr,
        dailyShortDhikr = dailyShort,
        prayerStatus = PrayerWidgetStatus.MISSING_LOCATION,
        locationDisplayName = null,
        calculationMethodLabel = null,
        madhabLabel = null,
        nextPrayerName = null,
        nextPrayerTimeEpochMs = null,
        nextPrayerRemainingMs = null,
        isNextPrayerTomorrow = false,
        dailyPrayerRows = emptyList(),
        promptMessage = if (matchingDaily != null) {
          snapshot.missingLocationPrompt
        } else {
          PROMPT_EXPIRED_DATA
        },
      )
    }

    if (!snapshot.prayerDataAvailable || snapshot.prayerDays.isEmpty()) {
      return ResolvedWidgetState(
        health = if (matchingDaily != null) SnapshotHealth.VALID else SnapshotHealth.EXPIRED,
        isDarkTheme = isDark,
        periodDhikr = periodDhikr,
        dailyShortDhikr = dailyShort,
        prayerStatus = PrayerWidgetStatus.UNAVAILABLE,
        locationDisplayName = snapshot.locationDisplayName,
        calculationMethodLabel = snapshot.calculationMethodLabel,
        madhabLabel = snapshot.madhabLabel,
        nextPrayerName = null,
        nextPrayerTimeEpochMs = null,
        nextPrayerRemainingMs = null,
        isNextPrayerTomorrow = false,
        dailyPrayerRows = emptyList(),
        promptMessage = if (matchingDaily != null) {
          snapshot.prayerUnavailablePrompt
        } else {
          PROMPT_EXPIRED_DATA
        },
      )
    }

    var resolvedNextName: String? = null
    var resolvedNextTimeMs: Long? = null
    var resolvedNextDayKey: String? = null
    var activeDayForNext: ParsedPrayerDay? = null

    outer@ for (day in snapshot.prayerDays) {
      for ((name, timeMs) in day.obligatoryEvents()) {
        if (timeMs > nowEpochMs) {
          resolvedNextName = name
          resolvedNextTimeMs = timeMs
          resolvedNextDayKey = day.localDate
          activeDayForNext = day
          break@outer
        }
      }
    }

    if (resolvedNextTimeMs == null) {
      val lastDay = snapshot.prayerDays.last()
      if (lastDay.tomorrowFajrUtcEpochMs > nowEpochMs) {
        resolvedNextName = "الفجر"
        resolvedNextTimeMs = lastDay.tomorrowFajrUtcEpochMs
        resolvedNextDayKey = nextCalendarDate(lastDay.localDate, timeZone)
        activeDayForNext = lastDay
      }
    }

    if (resolvedNextTimeMs == null || resolvedNextName == null) {
      return ResolvedWidgetState(
        health = SnapshotHealth.EXPIRED,
        isDarkTheme = isDark,
        periodDhikr = periodDhikr,
        dailyShortDhikr = dailyShort,
        prayerStatus = PrayerWidgetStatus.EXPIRED,
        locationDisplayName = snapshot.locationDisplayName,
        calculationMethodLabel = snapshot.calculationMethodLabel,
        madhabLabel = snapshot.madhabLabel,
        nextPrayerName = null,
        nextPrayerTimeEpochMs = null,
        nextPrayerRemainingMs = null,
        isNextPrayerTomorrow = false,
        dailyPrayerRows = emptyList(),
        promptMessage = PROMPT_EXPIRED_DATA,
      )
    }

    val scheduleForDisplay =
      snapshot.prayerDays.firstOrNull { it.localDate == todayKey }
        ?: activeDayForNext
        ?: snapshot.prayerDays.first()

    val rows = buildPrayerRows(
      schedule = scheduleForDisplay,
      nextName = resolvedNextName,
      nextTimeMs = resolvedNextTimeMs,
    )

    val remainingMs = (resolvedNextTimeMs - nowEpochMs).coerceAtLeast(0L)
    val isTomorrow = resolvedNextDayKey != null && resolvedNextDayKey != todayKey

    return ResolvedWidgetState(
      health = if (matchingDaily != null) SnapshotHealth.VALID else SnapshotHealth.EXPIRED,
      isDarkTheme = isDark,
      periodDhikr = periodDhikr,
      dailyShortDhikr = dailyShort,
      prayerStatus = PrayerWidgetStatus.AVAILABLE,
      locationDisplayName = snapshot.locationDisplayName,
      calculationMethodLabel = snapshot.calculationMethodLabel,
      madhabLabel = snapshot.madhabLabel,
      nextPrayerName = resolvedNextName,
      nextPrayerTimeEpochMs = resolvedNextTimeMs,
      nextPrayerRemainingMs = remainingMs,
      isNextPrayerTomorrow = isTomorrow,
      dailyPrayerRows = rows,
      promptMessage = if (matchingDaily != null) "" else PROMPT_EXPIRED_DATA,
    )
  }

  private fun buildPrayerRows(
    schedule: ParsedPrayerDay,
    nextName: String,
    nextTimeMs: Long,
  ): List<WidgetPrayerRow> {
    return listOf(
      WidgetPrayerRow(
        arabicName = "الفجر",
        utcEpochMs = schedule.fajrUtcEpochMs,
        isObligatory = true,
        isNext = nextName == "الفجر" && schedule.fajrUtcEpochMs == nextTimeMs,
      ),
      WidgetPrayerRow(
        arabicName = "الشروق",
        utcEpochMs = schedule.sunriseUtcEpochMs,
        isObligatory = false,
        isNext = false,
      ),
      WidgetPrayerRow(
        arabicName = "الظهر",
        utcEpochMs = schedule.dhuhrUtcEpochMs,
        isObligatory = true,
        isNext = nextName == "الظهر" && schedule.dhuhrUtcEpochMs == nextTimeMs,
      ),
      WidgetPrayerRow(
        arabicName = "العصر",
        utcEpochMs = schedule.asrUtcEpochMs,
        isObligatory = true,
        isNext = nextName == "العصر" && schedule.asrUtcEpochMs == nextTimeMs,
      ),
      WidgetPrayerRow(
        arabicName = "المغرب",
        utcEpochMs = schedule.maghribUtcEpochMs,
        isObligatory = true,
        isNext = nextName == "المغرب" && schedule.maghribUtcEpochMs == nextTimeMs,
      ),
      WidgetPrayerRow(
        arabicName = "العشاء",
        utcEpochMs = schedule.ishaUtcEpochMs,
        isObligatory = true,
        isNext = nextName == "العشاء" && schedule.ishaUtcEpochMs == nextTimeMs,
      ),
    )
  }

  private fun parseTextItem(map: Map<*, *>?): ParsedTextItem? {
    if (map == null) return null
    val text = (map["text"] as? String)?.trim() ?: return null
    if (text.isEmpty()) return null
    val source = (map["source"] as? String)?.trim() ?: ""
    val categoryTitle = (map["categoryTitle"] as? String)?.trim() ?: ""
    return ParsedTextItem(text = text, source = source, categoryTitle = categoryTitle)
  }

  private fun parsePeriodDhikr(map: Map<*, *>?): ParsedPeriodDhikr? {
    if (map == null) return null
    val id = (map["id"] as? String)?.trim() ?: return null
    val order = (map["order"] as? Number)?.toInt() ?: return null
    val text = (map["text"] as? String)?.trim() ?: return null
    if (text.isEmpty()) return null
    val source = (map["source"] as? String)?.trim() ?: ""
    val count = (map["count"] as? Number)?.toInt() ?: 1
    val countDescription = (map["countDescription"] as? String)?.trim() ?: ""
    return ParsedPeriodDhikr(
      id = id,
      order = order,
      text = text,
      source = source,
      count = count.coerceAtLeast(1),
      countDescription = countDescription,
    )
  }

  private fun parseDailyDay(map: Map<*, *>?): ParsedDailyAdhkarDay? {
    if (map == null) return null
    val localDate = (map["localDate"] as? String)?.trim() ?: return null
    if (!DATE_PATTERN.matches(localDate)) return null
    val dhikr = parseTextItem(map["dhikr"] as? Map<*, *>) ?: return null
    val dua = parseTextItem(map["dua"] as? Map<*, *>) ?: return null
    val ayah = parseTextItem(map["ayah"] as? Map<*, *>) ?: return null
    val quote = parseTextItem(map["quote"] as? Map<*, *>) ?: return null
    return ParsedDailyAdhkarDay(
      localDate = localDate,
      dhikr = dhikr,
      dua = dua,
      ayah = ayah,
      quote = quote,
    )
  }

  private fun parsePrayerDay(map: Map<*, *>?): ParsedPrayerDay? {
    if (map == null) return null
    val localDate = (map["localDate"] as? String)?.trim() ?: return null
    if (!DATE_PATTERN.matches(localDate)) return null
    val fajr = (map["fajrUtcEpochMs"] as? Number)?.toLong() ?: return null
    val sunrise = (map["sunriseUtcEpochMs"] as? Number)?.toLong() ?: return null
    val dhuhr = (map["dhuhrUtcEpochMs"] as? Number)?.toLong() ?: return null
    val asr = (map["asrUtcEpochMs"] as? Number)?.toLong() ?: return null
    val maghrib = (map["maghribUtcEpochMs"] as? Number)?.toLong() ?: return null
    val isha = (map["ishaUtcEpochMs"] as? Number)?.toLong() ?: return null
    val tomorrowFajr = (map["tomorrowFajrUtcEpochMs"] as? Number)?.toLong() ?: return null
    return ParsedPrayerDay(
      localDate = localDate,
      fajrUtcEpochMs = fajr,
      sunriseUtcEpochMs = sunrise,
      dhuhrUtcEpochMs = dhuhr,
      asrUtcEpochMs = asr,
      maghribUtcEpochMs = maghrib,
      ishaUtcEpochMs = isha,
      tomorrowFajrUtcEpochMs = tomorrowFajr,
    )
  }

  internal fun formatCalendarDate(cal: Calendar): String {
    val y = cal.get(Calendar.YEAR).toString().padStart(4, '0')
    val m = (cal.get(Calendar.MONTH) + 1).toString().padStart(2, '0')
    val d = cal.get(Calendar.DAY_OF_MONTH).toString().padStart(2, '0')
    return "$y-$m-$d"
  }

  private fun nextCalendarDate(dateKey: String, timeZone: TimeZone): String {
    val parts = dateKey.split("-")
    if (parts.size != 3) return dateKey
    val cal = Calendar.getInstance(timeZone).apply {
      clear()
      set(parts[0].toInt(), parts[1].toInt() - 1, parts[2].toInt())
      add(Calendar.DAY_OF_MONTH, 1)
    }
    return formatCalendarDate(cal)
  }

  private val DATE_PATTERN = Regex("^\\d{4}-\\d{2}-\\d{2}$")
}
