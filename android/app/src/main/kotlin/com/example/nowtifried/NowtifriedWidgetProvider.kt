package com.example.nowtifried

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import java.util.Calendar

open class NowtifriedWidgetProvider : AppWidgetProvider() {

    companion object {
        const val ACTION_SELECT_DAY = "com.example.nowtifried.ACTION_SELECT_DAY"
        const val EXTRA_DAY = "extra_selected_day"
        const val PREFS_NAME = "nowtifried_widget_prefs"
        const val PREF_SELECTED_DAY_PREFIX = "selected_day_"
    }

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
        if (intent.action == ACTION_SELECT_DAY) {
            val selectedDay = intent.getIntExtra(EXTRA_DAY, 1)
            val appWidgetId = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)
            if (appWidgetId != AppWidgetManager.INVALID_APPWIDGET_ID) {
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                prefs.edit().putInt("$PREF_SELECTED_DAY_PREFIX$appWidgetId", selectedDay).apply()

                val appWidgetManager = AppWidgetManager.getInstance(context)
                updateSingleWidget(context, appWidgetManager, appWidgetId)
            }
            return
        }

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
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

            // Current day of week (Monday=1 .. Saturday=6, Sunday->1)
            val cal = Calendar.getInstance()
            val rawDow = cal.get(Calendar.DAY_OF_WEEK)
            val todayWeekday = when (rawDow) {
                Calendar.MONDAY -> 1
                Calendar.TUESDAY -> 2
                Calendar.WEDNESDAY -> 3
                Calendar.THURSDAY -> 4
                Calendar.FRIDAY -> 5
                Calendar.SATURDAY -> 6
                else -> 1
            }
            val selectedDay = prefs.getInt("$PREF_SELECTED_DAY_PREFIX$appWidgetId", todayWeekday).coerceIn(1, 6)

            val isNarrow = minWidth in 1..199
            val isScheduleType = widgetTypePrefix == "schedule" ||
                (widgetTypePrefix == null && widgetData.getString("widget_schedule_large_day_1", null) != null)

            // Determine image key based on widgetTypePrefix and resized dimensions.
            // Android widget grid cell formula: dp = (cells * 70) - 30.
            //   1 row:  ~40-90 dp
            //   2 rows: ~100-160 dp
            //   3 rows: ~170-230 dp
            //   4 rows: ~240-350 dp
            //   2 cols: ~100-190 dp (square / compact)
            //   4 cols: ~250-380 dp (full width)
            val imageKey = when {
                widgetTypePrefix == "schedule" -> when {
                    isNarrow         -> "widget_schedule_small_image"
                    minHeight >= 230 -> "widget_schedule_xlarge_day_$selectedDay"
                    minHeight >= 140 -> "widget_schedule_large_day_$selectedDay"
                    minHeight >= 95  -> "widget_schedule_medium_image"
                    else             -> "widget_schedule_bar_image"
                }
                widgetTypePrefix == "deadlines" -> when {
                    isNarrow         -> "widget_deadlines_small_image"
                    minHeight >= 230 -> "widget_deadlines_xlarge_image"
                    minHeight >= 140 -> "widget_deadlines_large_image"
                    minHeight >= 95  -> "widget_deadlines_medium_image"
                    else             -> "widget_deadlines_bar_image"
                }
                widgetTypePrefix == "tasks" -> when {
                    isNarrow         -> "widget_tasks_small_image"
                    minHeight >= 230 -> "widget_tasks_xlarge_image"
                    minHeight >= 140 -> "widget_tasks_large_image"
                    minHeight >= 95  -> "widget_tasks_medium_image"
                    else             -> "widget_tasks_bar_image"
                }
                else -> when {
                    // Resizable general agenda hub (adapts automatically when resized)
                    isNarrow         -> "widget_small_image"
                    minHeight >= 230 -> if (isScheduleType) "widget_schedule_xlarge_day_$selectedDay" else "widget_extra_large_image"
                    minHeight >= 140 -> if (isScheduleType) "widget_schedule_large_day_$selectedDay" else "widget_large_image"
                    minHeight >= 95  -> "widget_medium_image"
                    minHeight in 1..94 -> "widget_bar_image"
                    else             -> explicitImageKey ?: "widget_large_image"
                }
            }

            var imagePath = widgetData.getString(imageKey, null)
            if (imagePath == null) {
                // Secondary fallback chain
                val prefix = if (widgetTypePrefix != null) "widget_${widgetTypePrefix}_" else "widget_"
                imagePath = widgetData.getString("${prefix}large_day_$selectedDay", null)
                    ?: widgetData.getString("${prefix}large_image", null)
                    ?: widgetData.getString("${prefix}xlarge_image", null)
                    ?: widgetData.getString("${prefix}medium_image", null)
                    ?: widgetData.getString("${prefix}bar_image", null)
                    ?: widgetData.getString("${prefix}small_image", null)
                    ?: widgetData.getString("widget_large_image", null)
                    ?: widgetData.getString("widget_extra_large_image", null)
                    ?: widgetData.getString("widget_medium_image", null)
            }

            if (imagePath != null) {
                val bitmap = android.graphics.BitmapFactory.decodeFile(imagePath)
                if (bitmap != null) {
                    views.setImageViewBitmap(R.id.widget_image, bitmap)
                }
            }

            // Interactive Day Strip setup for Schedule widgets (large & extra-large layouts)
            val hasDayStrip = isScheduleType && !isNarrow && (minHeight == 0 || minHeight >= 140)

            if (hasDayStrip) {
                views.setViewVisibility(R.id.day_strip_touch_overlay, View.VISIBLE)

                // Wire up transparent day buttons for in-place broadcast switching on home screen
                val dayButtons = intArrayOf(
                    R.id.btn_day_1,
                    R.id.btn_day_2,
                    R.id.btn_day_3,
                    R.id.btn_day_4,
                    R.id.btn_day_5,
                    R.id.btn_day_6
                )
                for (i in dayButtons.indices) {
                    val targetDay = i + 1
                    val selectDayIntent = Intent(context, this::class.java).apply {
                        action = ACTION_SELECT_DAY
                        putExtra(EXTRA_DAY, targetDay)
                        putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                    }
                    val pIntent = PendingIntent.getBroadcast(
                        context,
                        appWidgetId * 100 + targetDay,
                        selectDayIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                    views.setOnClickPendingIntent(dayButtons[i], pIntent)
                }

                // Top & Bottom touch areas launch the app directly into the Schedule tab
                val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)?.apply {
                    putExtra("target_tab", "schedule")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                if (launchIntent != null) {
                    val topPending = PendingIntent.getActivity(
                        context,
                        appWidgetId * 10 + 1,
                        launchIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                    val bottomPending = PendingIntent.getActivity(
                        context,
                        appWidgetId * 10 + 2,
                        launchIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                    views.setOnClickPendingIntent(R.id.touch_top_area, topPending)
                    views.setOnClickPendingIntent(R.id.touch_bottom_area, bottomPending)
                }
            } else {
                views.setViewVisibility(R.id.day_strip_touch_overlay, View.GONE)

                // Full card click opens the app with target_tab
                val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)?.apply {
                    if (widgetTypePrefix != null) {
                        putExtra("target_tab", widgetTypePrefix)
                    }
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                if (launchIntent != null) {
                    val pending = PendingIntent.getActivity(
                        context,
                        appWidgetId,
                        launchIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                    views.setOnClickPendingIntent(R.id.widget_root, pending)
                    views.setOnClickPendingIntent(R.id.widget_image, pending)
                }
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
