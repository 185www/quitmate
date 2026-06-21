package org.quitmate.app;

import android.appwidget.AppWidgetManager;
import android.context.Context;
import android.content.SharedPreferences;
import android.widget.RemoteViews;

public class MotivationWidgetProvider extends QuitMateWidgetProvider {
    @Override
    public void onUpdate(Context context, AppWidgetManager appWidgetManager, int[] appWidgetIds) {
        for (int appWidgetId : appWidgetIds) {
            RemoteViews views = new RemoteViews(context.getPackageName(), R.layout.motivation_widget_layout);
            
            SharedPreferences prefs = context.getSharedPreferences("QuitMateWidgetData", Context.MODE_PRIVATE);
            
            String tipOfDay = prefs.getString("tipOfDay", "您的重自已支付可以包否.");
            String personalizedInsight = prefs.getString("personalizedInsight", "");
            int streakDays = prefs.getInt("streakDays", 0);
            
            views.setTextViewText(R.id.tip_text, tipOfDay);
            views.setTextViewText(R.id.streak_text, streakDays + " 字");
            
            if (!personalizedInsight.isEmpty() && personalizedInsight.length() > 5) {
                views.setTextViewText(R.id.insight_text, personalizedInsight);
                views.setViewVisibility(R.id.insight_text, android.view.View.VISIBLE);
            } else {
                views.setViewVisibility(R.id.insight_text, android.view.View.GONE);
            }
            
            appWidgetManager.updateAppWidget(appWidgetId, views);
        }
    }
}
