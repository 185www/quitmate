package org.quitmate.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class QuitMateWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        const val PREFS_NAME = "HomeWidgetPreferences"
        const val KEY_DAYS = "widget_days"
        const val KEY_MONEY = "widget_money"
        const val KEY_LIFE = "widget_life"
        const val KEY_RECOVERY = "widget_recovery"
        const val KEY_PROGRESS = "widget_progress"

        fun updateWidget(context: Context, manager: AppWidgetManager, id: Int) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val views = RemoteViews(context.packageName, R.layout.quitmate_widget_layout)

            val days = prefs.getString(KEY_DAYS, "第 -- 天")
            val money = prefs.getString(KEY_MONEY, "💰 已省 ¥--")
            val life = prefs.getString(KEY_LIFE, "❤️ +-- 天生命")
            val recovery = prefs.getString(KEY_RECOVERY, "身体恢复 --%")
            val progress = prefs.getInt(KEY_PROGRESS, 0)

            views.setTextViewText(R.id.widget_days, days)
            views.setTextViewText(R.id.widget_money, money)
            views.setTextViewText(R.id.widget_life, life)
            views.setTextViewText(R.id.widget_recovery, recovery)
            views.setProgressBar(R.id.widget_progress, 100, progress, false)

            // SOS button: open app and go to urge-toolkit
            val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            intent?.putExtra("route", "/action/urge-toolkit")
            intent?.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            val pendingIntent = PendingIntent.getActivity(
                context, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_sos, pendingIntent)

            manager.updateAppWidget(id, views)
        }
    }
}
