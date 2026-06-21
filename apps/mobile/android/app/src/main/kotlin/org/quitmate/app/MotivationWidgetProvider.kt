package org.quitmate.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent

class MotivationWidgetProvider : AppWidgetProvider() {
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
        const val PREFS_NAME = "MotivationWidgetPreferences"
        const val KEY_TIP = "motivation_tip"
        const val KEY_STREAK = "motivation_streak"
        const val KEY_INSIGHT = "motivation_insight"

        private val DEFAULT_TIPS = arrayOf(
            "每坚持一天，你的肺功能都在恢复。继续保持！",
            "你已经比昨天更强了。",
            "深呼吸， cravings 会在几分钟内消退。",
            "想想你省下的钱和恢复的健康。",
            "每一次拒绝，都是对自我的掌控。"
        )

        fun updateWidget(context: Context, manager: AppWidgetManager, id: Int) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val views = android.widget.RemoteViews(context.packageName, R.layout.motivation_widget_layout)

            val tip = prefs.getString(KEY_TIP, null)
                ?: DEFAULT_TIPS[(System.currentTimeMillis() / 86400000L).toInt() % DEFAULT_TIPS.size]
            val streak = prefs.getInt(KEY_STREAK, 0)
            val insight = prefs.getString(KEY_INSIGHT, null)

            views.setTextViewText(R.id.tip_text, tip)
            views.setTextViewText(R.id.streak_text, "$streak 天连续")

            if (!insight.isNullOrEmpty()) {
                views.setTextViewText(R.id.insight_text, insight)
                views.setViewVisibility(R.id.insight_text, android.view.View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.insight_text, android.view.View.GONE)
            }

            // Tap to open app
            val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            intent?.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            val pendingIntent = PendingIntent.getActivity(
                context, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(android.R.id.background, pendingIntent)

            manager.updateAppWidget(id, views)
        }
    }
}