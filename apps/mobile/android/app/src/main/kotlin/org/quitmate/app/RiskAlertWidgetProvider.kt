package org.quitmate.app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews

class RiskAlertWidgetProvider : AppWidgetProvider() {
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
        const val PREFS_NAME = "RiskAlertWidgetPreferences"
        const val KEY_RISK_SCORE = "risk_score"
        const val KEY_CRAVING = "craving_intensity"

        fun updateWidget(context: Context, manager: AppWidgetManager, id: Int) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val views = RemoteViews(context.packageName, R.layout.risk_alert_widget_layout)

            val riskScore = prefs.getInt(KEY_RISK_SCORE, 0)
            val craving = prefs.getInt(KEY_CRAVING, 0)

            views.setTextViewText(R.id.risk_score_text, riskScore.toString())
            views.setProgressBar(R.id.craving_bar, 100, craving, false)

            // Color-code risk score: green (low) -> yellow -> red (high)
            val color = when {
                riskScore < 30 -> "#4CAF50"  // Green
                riskScore < 60 -> "#FFC107"  // Yellow
                riskScore < 80 -> "#FF9800"  // Orange
                else -> "#F44336"            // Red
            }
            views.setTextColor(R.id.risk_score_text, android.graphics.Color.parseColor(color))

            manager.updateAppWidget(id, views)
        }
    }
}