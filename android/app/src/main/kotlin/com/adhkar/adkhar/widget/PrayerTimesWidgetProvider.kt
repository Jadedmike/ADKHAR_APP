package com.adhkar.adkhar.widget

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Bundle
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import java.util.TimeZone

class PrayerTimesWidgetProvider : HomeWidgetProvider() {
  override fun onReceive(context: Context, intent: Intent) {
    super.onReceive(context, intent)
    when (intent.action) {
      Intent.ACTION_TIME_CHANGED,
      Intent.ACTION_TIMEZONE_CHANGED,
      Intent.ACTION_DATE_CHANGED -> {
        val appWidgetManager = AppWidgetManager.getInstance(context)
        val ids = appWidgetManager.getAppWidgetIds(ComponentName(context, javaClass))
        if (ids.isNotEmpty()) {
          onUpdate(context, appWidgetManager, ids, HomeWidgetPlugin.getData(context))
        }
      }
    }
  }

  override fun onUpdate(
    context: Context,
    appWidgetManager: AppWidgetManager,
    appWidgetIds: IntArray,
    widgetData: SharedPreferences,
  ) {
    val nowMs = System.currentTimeMillis()
    val tz = TimeZone.getDefault()
    val snapshot = WidgetSnapshotReader.readSnapshot(widgetData)
    val state = WidgetSnapshotReader.resolveFromPreferences(
      prefs = widgetData,
      nowEpochMs = nowMs,
      timeZone = tz,
      isSystemDark = WidgetUiBinder.isSystemDark(context),
    )

    for (appWidgetId in appWidgetIds) {
      val options = appWidgetManager.getAppWidgetOptions(appWidgetId) ?: Bundle.EMPTY
      val views = WidgetUiBinder.bindPrayerWidget(context, state, options, tz, nowMs)
      appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    WidgetScheduleCoordinator.syncSchedule(
      context = context,
      providerClassName = javaClass.name,
      snapshot = snapshot,
      nowEpochMs = nowMs,
      timeZone = tz,
    )
  }

  override fun onAppWidgetOptionsChanged(
    context: Context,
    appWidgetManager: AppWidgetManager,
    appWidgetId: Int,
    newOptions: Bundle,
  ) {
    super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
    val widgetData = HomeWidgetPlugin.getData(context)
    val nowMs = System.currentTimeMillis()
    val tz = TimeZone.getDefault()
    val state = WidgetSnapshotReader.resolveFromPreferences(
      prefs = widgetData,
      nowEpochMs = nowMs,
      timeZone = tz,
      isSystemDark = WidgetUiBinder.isSystemDark(context),
    )
    val views = WidgetUiBinder.bindPrayerWidget(context, state, newOptions, tz, nowMs)
    appWidgetManager.updateAppWidget(appWidgetId, views)
  }

  override fun onDisabled(context: Context) {
    super.onDisabled(context)
    WidgetScheduleCoordinator.cancelSchedule(context, javaClass.name)
  }
}

