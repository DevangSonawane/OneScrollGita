package com.example.versescroll

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import org.json.JSONObject
import java.time.LocalDate

/** Opens the app, at [verseId] when given (handled by the app's /verse route). */
private fun openApp(context: Context, verseId: String?, requestCode: Int): PendingIntent {
    val intent = if (verseId == null) {
        Intent(context, MainActivity::class.java)
    } else {
        Intent(
            Intent.ACTION_VIEW,
            Uri.parse("gitaapp://open/verse?id=" + Uri.encode(verseId)),
            context,
            MainActivity::class.java,
        )
    }.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
    return PendingIntent.getActivity(
        context,
        requestCode,
        intent,
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )
}

private fun readArray(data: SharedPreferences, key: String): JSONArray =
    try {
        JSONArray(data.getString(key, "[]") ?: "[]")
    } catch (e: Exception) {
        JSONArray()
    }

/** Verse of the day. The app stores the next 30 days; this picks today's. */
class DailyVerseWidget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val days = readArray(widgetData, "daily_verses")
        val today = LocalDate.now().toString()
        var verse: JSONObject? = null
        for (i in 0 until days.length()) {
            val d = days.getJSONObject(i)
            if (d.optString("date") <= today) verse = d // latest day not in the future
        }
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_daily)
            if (verse == null) {
                views.setTextViewText(R.id.daily_text, context.getString(R.string.widget_open_app))
                views.setTextViewText(R.id.daily_ref, context.getString(R.string.app_name_widget))
                views.setOnClickPendingIntent(R.id.daily_root, openApp(context, null, 100))
            } else {
                views.setTextViewText(R.id.daily_text, verse.optString("text"))
                views.setTextViewText(R.id.daily_ref, "Bhagavad-gītā " + verse.optString("label"))
                views.setOnClickPendingIntent(
                    R.id.daily_root,
                    openApp(context, verse.optString("id"), 100),
                )
            }
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}

/** Continue reading: the last verse read, plus a few before it. */
class RecentWidget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val items = readArray(widgetData, "history_items")
        val chips = intArrayOf(R.id.recent_1, R.id.recent_2, R.id.recent_3)
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_recent)
            if (items.length() == 0) {
                views.setViewVisibility(R.id.recent_main, View.GONE)
                views.setViewVisibility(R.id.recent_more, View.GONE)
                views.setViewVisibility(R.id.recent_empty, View.VISIBLE)
                views.setOnClickPendingIntent(R.id.recent_root, openApp(context, null, 200))
            } else {
                val first = items.getJSONObject(0)
                views.setViewVisibility(R.id.recent_main, View.VISIBLE)
                views.setViewVisibility(R.id.recent_empty, View.GONE)
                views.setTextViewText(R.id.recent_ref, "Bhagavad-gītā " + first.optString("label"))
                views.setTextViewText(R.id.recent_text, first.optString("text"))
                views.setOnClickPendingIntent(
                    R.id.recent_main,
                    openApp(context, first.optString("id"), 200),
                )
                views.setOnClickPendingIntent(R.id.recent_root, openApp(context, first.optString("id"), 201))
                views.setViewVisibility(R.id.recent_more, if (items.length() > 1) View.VISIBLE else View.GONE)
                for (i in chips.indices) {
                    val item = items.optJSONObject(i + 1)
                    if (item == null) {
                        views.setViewVisibility(chips[i], View.GONE)
                    } else {
                        views.setViewVisibility(chips[i], View.VISIBLE)
                        views.setTextViewText(chips[i], item.optString("label"))
                        views.setOnClickPendingIntent(
                            chips[i],
                            openApp(context, item.optString("id"), 210 + i),
                        )
                    }
                }
            }
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
