package com.example.nowtifried

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class NowtifriedWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        super.onUpdate(context, appWidgetManager, appWidgetIds)

        val views = RemoteViews(context.packageName, R.layout.widget_nowtifried)
        // Default text; for full integration, read schedules saved via HomeWidget plugin and update this view.
        views.setTextViewText(R.id.widget_title, "Nowtifried")
        views.setTextViewText(R.id.widget_sub, "Tap to open app")

        // Launch the app when clicking the widget
        val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val pending = PendingIntent.getActivity(context, 0, intent, PendingIntent.FLAG_IMMUTABLE)
        views.setOnClickPendingIntent(R.id.widget_title, pending)
        views.setOnClickPendingIntent(R.id.widget_sub, pending)

        val thisWidget = ComponentName(context, NowtifriedWidgetProvider::class.java)
        appWidgetManager.updateAppWidget(thisWidget, views)
    }
}
