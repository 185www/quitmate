package org.quitmate.app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.util.Log
import android.widget.RemoteViews

class RiskAlertWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            try {
                updateWidget(context, appWidgetManager, appWidgetId)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to update widget $appWidgetId", e)
            }
        }
    }

    companion object {
        private const val TAG = "RiskAlertWidget"
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

            val color = when {
                riskScore < 30 -> "#4CAF50"
                riskScore < 60 -> "#FFC107"
                riskScore < 80 -> "#FF9800"
                else -> "#F44336"
            }
            views.setTextColor(R.id.risk_score_text, android.graphics.Color.parseColor(color))

            manager.updateAppWidget(id, views)
        }
    }
}