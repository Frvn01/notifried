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
        val entries = buildEntriesFromJson(schedulesJson)

        // Populate up to 3 lines and colored dots
        val idsLine = listOf(R.id.widget_line1, R.id.widget_line2, R.id.widget_line3)
        val idsDot = listOf(R.id.widget_dot1, R.id.widget_dot2, R.id.widget_dot3)
        for (i in 0..2) {
            if (i < entries.size) {
                val (timeStr, title, colorInt) = entries[i]
                views.setViewVisibility(idsLine[i], android.view.View.VISIBLE)
                views.setViewVisibility(idsDot[i], android.view.View.VISIBLE)
                views.setTextViewText(idsLine[i], "$timeStr • $title")
                try {
                    views.setInt(idsDot[i], "setBackgroundColor", colorInt)
                } catch (e: Exception) {
                    // ignore color set failure
                }
            } else {
                views.setViewVisibility(idsLine[i], android.view.View.GONE)
                views.setViewVisibility(idsDot[i], android.view.View.GONE)
            }
        }

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

    private fun buildEntriesFromJson(json: String?): List<Triple<String, String, Int>> {
        val results = mutableListOf<Triple<String, String, Int>>()
        if (json == null) return results
        try {
            val arr = JSONArray(json)
            val now = Instant.now()
            val items = mutableListOf<Triple<Instant, String, Int>>()
            for (i in 0 until arr.length()) {
                val obj = arr.getJSONObject(i)
                val title = obj.optString("title", "")
                val startStr = obj.optString("start", null)
                val color = obj.optInt("color", 0xFF888888.toInt())
                if (startStr == null) continue
                try {
                    val inst = Instant.parse(startStr)
                    if (inst.isAfter(now)) {
                        items.add(Triple(inst, title, color))
                    }
                } catch (e: Exception) {
                    // ignore parse error
                }
            }
            items.sortBy { it.first }
            val fmt = DateTimeFormatter.ofPattern("HH:mm").withZone(ZoneId.systemDefault())
            val top = items.take(3)
            for ((time, title, color) in top) {
                results.add(Triple(fmt.format(time), title, color))
            }
        } catch (e: Exception) {
            // ignore
        }
        return results
    }
}
