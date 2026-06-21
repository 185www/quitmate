package org.quitmate.app;

import android.appwidget.AppWidgetProvider;
import android.appwidget.AppWidgetManager;
import android.content.Context;
import android.content.SharedPreferences;
import android.widget.RemoteViews;

public class RiskAlertWidgetProvider extends AppWidgetProvider {
    @Override
    public void onUpdate(Context context, AppWidgetManager appWidgetManager, int[] appWidgetIds) {
        for (int appWidgetId : appWidgetIds) {
            RemoteViews views = new RemoteViews(context.getPackageName(), R.layout.risk_alert_widget_layout);

            SharedPreferences prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE);

            int riskScore = prefs.getInt("risk_score", 0);
            String riskLabel = prefs.getString("risk_label", "\u4F4E");
            int cravingIntensity = prefs.getInt("craving_intensity", 0);

            views.setTextViewText(R.id.risk_score_text, String.valueOf(riskScore));
            views.setTextViewText(R.id.risk_label_text, "\u26A0\uFE0F \u98CE\u9669\u7B49\u7EA7 " + riskLabel);
            views.setProgressBar(R.id.craving_bar, 100, cravingIntensity, false);

            // Color based on risk level: green <40, amber 40-70, red >=70
            int riskColor;
            if (riskScore >= 70) riskColor = 0xFFF44444;
            else if (riskScore >= 40) riskColor = 0xFFFFB74D;
            else riskColor = 0xFF4CAF50;
            views.setTextColor(R.id.risk_score_text, riskColor);

            appWidgetManager.updateAppWidget(appWidgetId, views);
        }
    }
}
