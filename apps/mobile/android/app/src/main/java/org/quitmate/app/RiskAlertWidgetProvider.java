package org.quitmate.app;

import android.appwidget.AppWidgetManager;
import android.context.Context;
import android.content.SharedPreferences;
import android.widget.RemoteViews;

public class RiskAlertWidgetProvider extends QuitMateWidgetProvider {
    @Override
    public void onUpdate(Context context, AppWidgetManager appWidgetManager, int[] appWidgetIds) {
        for (int appWidgetId : appWidgetIds) {
            RemoteViews views = new RemoteViews(context.getPackageName(), R.layout.risk_alert_widget_layout);
            
            SharedPreferences prefs = context.getSharedPreferences("QuitMateWidgetData", Context.MODE_PRIVATE);
            
            int riskScore = prefs.getInt("riskScore", 0);
            String riskLabel = prefs.getString("riskLabel", "完全");
            int cravingIntensity = prefs.getInt("cravingIntensity", 0);
            
            views.setTextViewText(R.id.risk_score_text, String.valueOf(riskScore));
            views.setTextViewText(R.id.risk_label_text, riskLabel);
            views.setProgressBar(R.id.craving_bar, 100, cravingIntensity, false);
            
            // Color based on risk level
            int riskColor;
            if (riskScore >= 70) riskColor = 0xFFF4444;
            else if (riskScore >= 40) riskColor = 0xFFF8800;
            else riskColor = 0xFF44AA44;
            views.setTextColor(R.id.risk_score_text, riskColor);
            views.setTextColor(R.id.risk_label_text, riskColor);
            
            appWidgetManager.updateAppWidget(appWidgetId, views);
        }
    }
}
