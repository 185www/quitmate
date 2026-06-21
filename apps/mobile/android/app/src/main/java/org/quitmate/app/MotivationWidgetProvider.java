package org.quitmate.app;

import android.appwidget.AppWidgetProvider;
import android.appwidget.AppWidgetManager;
import android.content.Context;
import android.content.SharedPreferences;
import android.widget.RemoteViews;

public class MotivationWidgetProvider extends AppWidgetProvider {
    @Override
    public void onUpdate(Context context, AppWidgetManager appWidgetManager, int[] appWidgetIds) {
        for (int appWidgetId : appWidgetIds) {
            RemoteViews views = new RemoteViews(context.getPackageName(), R.layout.motivation_widget_layout);

            SharedPreferences prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE);

            String tipOfDay = prefs.getString("tip_of_the_day", "\u6BCF\u575A\u6301\u4E00\u5929\uFF0C\u4F60\u7684\u80BA\u529F\u80FD\u90FD\u5728\u6062\u590D\u3002\u7EE7\u7EED\u4FDD\u6301\uFF01");
            String personalizedInsight = prefs.getString("personalized_insight", "");
            int streakDays = prefs.getInt("streak_days", 0);

            views.setTextViewText(R.id.tip_text, tipOfDay);
            views.setTextViewText(R.id.streak_text, streakDays + " \u5929\u8FDE\u7EED");

            if (personalizedInsight != null && personalizedInsight.length() > 5) {
                views.setTextViewText(R.id.insight_text, personalizedInsight);
                views.setViewVisibility(R.id.insight_text, android.view.View.VISIBLE);
            } else {
                views.setViewVisibility(R.id.insight_text, android.view.View.GONE);
            }

            appWidgetManager.updateAppWidget(appWidgetId, views);
        }
    }
}
