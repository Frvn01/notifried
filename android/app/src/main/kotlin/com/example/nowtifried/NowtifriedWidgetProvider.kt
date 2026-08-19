package com.example.nowtifried

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import org.json.JSONArray
import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter

class NowtifriedWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        super.onUpdate(context, appWidgetManager, appWidgetIds)

        val views = RemoteViews(context.packageName, R.layout.widget_nowtifried)
        views.setTextViewText(R.id.widget_title, "Nowtifried")

        val schedulesJson = readSchedulesJson(context)
        val summary = buildSummaryFromJson(schedulesJson)
        views.setTextViewText(R.id.widget_sub, summary)

        val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val pending = PendingIntent.getActivity(context, 0, intent, PendingIntent.FLAG_IMMUTABLE)
        views.setOnClickPendingIntent(R.id.widget_title, pending)
        views.setOnClickPendingIntent(R.id.widget_sub, pending)

        val thisWidget = ComponentName(context, NowtifriedWidgetProvider::class.java)
        appWidgetManager.updateAppWidget(thisWidget, views)
    }

    private fun readSchedulesJson(context: Context): String? {
        // The `home_widget` plugin saves values to SharedPreferences under a provider-specific name.
        // Try the common SharedPreferences locations where `home_widget` may write data.
        val names = listOf("com.example.nowtifried.HomeWidget", "home_widget", "FlutterSharedPreferences")
        for (name in names) {
            try {
                val prefs = context.getSharedPreferences(name, Context.MODE_PRIVATE)
                if (prefs.contains("schedules_json")) {
                    return prefs.getString("schedules_json", null)
                }
            } catch (e: Exception) {
                // ignore and try next
            }
        }
        return null
    }

    private fun buildSummaryFromJson(json: String?): String {
        if (json == null) return "No schedules"
        try {
            val arr = JSONArray(json)
            val now = Instant.now()
            val items = mutableListOf<Pair<Instant, String>>()
            for (i in 0 until arr.length()) {
                val obj = arr.getJSONObject(i)
                val title = obj.optString("title", "")
                val startStr = obj.optString("start", null)
                if (startStr == null) continue
                try {
                    val inst = Instant.parse(startStr)
                    if (inst.isAfter(now)) {
                        items.add(Pair(inst, title))
                    }
                } catch (e: Exception) {
                    // ignore parse error
                }
            }
            items.sortBy { it.first }
            val fmt = DateTimeFormatter.ofPattern("HH:mm").withZone(ZoneId.systemDefault())
            val lines = items.take(3).map { (time, title) -> "${fmt.format(time)} • $title" }
            if (lines.isEmpty()) return "No upcoming schedules"
            return lines.joinToString("\n")
        } catch (e: Exception) {
            return "No schedules"
        }
    }
}
