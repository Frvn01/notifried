package com.example.nowtifried

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

open class NowtifriedWidgetProvider : AppWidgetProvider() {

    open val explicitImageKey: String? = null
    open val widgetTypePrefix: String? = null // "schedule", "deadlines", "tasks"

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        super.onUpdate(context, appWidgetManager, appWidgetIds)
        for (appWidgetId in appWidgetIds) {
            updateSingleWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: android.os.Bundle
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        updateSingleWidget(context, appWidgetManager, appWidgetId)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        try {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val thisWidget = ComponentName(context, this::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
            if (appWidgetIds != null && appWidgetIds.isNotEmpty()) {
                for (appWidgetId in appWidgetIds) {
                    updateSingleWidget(context, appWidgetManager, appWidgetId)
                }
            }
        } catch (_: Exception) {}
    }

    private fun updateSingleWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        try {
            val views = RemoteViews(context.packageName, R.layout.widget_nowtifried)
            
            // Determine size
            val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
            val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH)
            val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT)

            val widgetData = HomeWidgetPlugin.getData(context)

            // Determine image key based on widgetTypePrefix and resized dimensions.
            // Android widget grid cell formula: dp = (cells * 70) - 30.
            //   1 row:  ~40-90 dp
            //   2 rows: ~100-160 dp
            //   3 rows: ~170-230 dp
            //   4 rows: ~240-350 dp
            //   2 cols: ~100-190 dp (square / compact)
            //   4 cols: ~250-380 dp (full width)
            val isNarrow = minWidth in 1..199

            val imageKey = when {
                explicitImageKey != null -> explicitImageKey!!
                widgetTypePrefix == "schedule" -> when {
                    isNarrow         -> "widget_schedule_small_image"
                    minHeight >= 230 -> "widget_schedule_xlarge_image"
                    minHeight >= 160 -> "widget_schedule_large_image"
                    minHeight >= 95  -> "widget_schedule_medium_image"
                    else             -> "widget_schedule_bar_image"
                }
                widgetTypePrefix == "deadlines" -> when {
                    isNarrow         -> "widget_deadlines_small_image"
                    minHeight >= 230 -> "widget_deadlines_xlarge_image"
                    minHeight >= 160 -> "widget_deadlines_large_image"
                    minHeight >= 95  -> "widget_deadlines_medium_image"
                    else             -> "widget_deadlines_bar_image"
                }
                widgetTypePrefix == "tasks" -> when {
                    isNarrow         -> "widget_tasks_small_image"
                    minHeight >= 230 -> "widget_tasks_xlarge_image"
                    minHeight >= 160 -> "widget_tasks_large_image"
                    minHeight >= 95  -> "widget_tasks_medium_image"
                    else             -> "widget_tasks_bar_image"
                }
                else -> when {
                    isNarrow         -> "widget_small_image"
                    minHeight >= 230 -> "widget_extra_large_image"
                    minHeight >= 160 -> "widget_large_image"
                    minHeight >= 95  -> "widget_medium_image"
                    else             -> "widget_bar_image"
                }
            }

            var imagePath = widgetData.getString(imageKey, null)
            if (imagePath == null) {
                // Family-specific fallback chain, then generic adaptive fallbacks
                val prefix = if (widgetTypePrefix != null) "widget_${widgetTypePrefix}_" else "widget_"
                imagePath = widgetData.getString("${prefix}xlarge_image", null)
                    ?: widgetData.getString("${prefix}large_image", null)
                    ?: widgetData.getString("${prefix}medium_image", null)
                    ?: widgetData.getString("${prefix}bar_image", null)
                    ?: widgetData.getString("${prefix}small_image", null)
                    ?: widgetData.getString("widget_extra_large_image", null)
                    ?: widgetData.getString("widget_large_image", null)
                    ?: widgetData.getString("widget_medium_image", null)
            }

            if (imagePath != null) {
                val bitmap = android.graphics.BitmapFactory.decodeFile(imagePath)
                if (bitmap != null) {
                    views.setImageViewBitmap(R.id.widget_image, bitmap)
                }
            }

            // Click to open app and optionally navigate to the right section
            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            if (launchIntent != null) {
                if (widgetTypePrefix != null) {
                    launchIntent.putExtra("target_tab", widgetTypePrefix)
                }
                val pending = PendingIntent.getActivity(
                    context, appWidgetId, launchIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_root, pending)
                views.setOnClickPendingIntent(R.id.widget_image, pending)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}

class ScheduleWidgetProvider : NowtifriedWidgetProvider() {
    override val widgetTypePrefix = "schedule"
}

class DeadlinesWidgetProvider : NowtifriedWidgetProvider() {
    override val widgetTypePrefix = "deadlines"
}

class TasksWidgetProvider : NowtifriedWidgetProvider() {
    override val widgetTypePrefix = "tasks"
}

class NowtifriedLargeWidgetProvider : NowtifriedWidgetProvider() {
    override val explicitImageKey = "widget_large_image"
}
class NowtifriedMediumWidgetProvider : NowtifriedWidgetProvider() {
    override val explicitImageKey = "widget_medium_image"
}
class NowtifriedSmallWidgetProvider : NowtifriedWidgetProvider() {
    override val explicitImageKey = "widget_small_image"
}
class NowtifriedExtraLargeWidgetProvider : NowtifriedWidgetProvider() {
    override val explicitImageKey = "widget_extra_large_image"
}
class NowtifriedGlanceWidgetProvider : NowtifriedWidgetProvider() {
    override val explicitImageKey = "widget_glance_image"
}
