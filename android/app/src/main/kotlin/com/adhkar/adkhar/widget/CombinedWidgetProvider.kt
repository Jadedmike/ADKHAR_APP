package com.adhkar.adkhar.widget

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.os.Bundle
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import java.util.TimeZone

class CombinedWidgetProvider : HomeWidgetProvider() {
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
      val views = WidgetUiBinder.bindCombinedWidget(context, state, options, tz)
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
    val tz = TimeZone.getDefault()
    val state = WidgetSnapshotReader.resolveFromPreferences(
      prefs = widgetData,
      nowEpochMs = System.currentTimeMillis(),
      timeZone = tz,
      isSystemDark = WidgetUiBinder.isSystemDark(context),
    )
    val views = WidgetUiBinder.bindCombinedWidget(context, state, newOptions, tz)
    appWidgetManager.updateAppWidget(appWidgetId, views)
  }

  override fun onDisabled(context: Context) {
    super.onDisabled(context)
    WidgetScheduleCoordinator.cancelSchedule(context, javaClass.name)
  }
}

