package com.ravana.momento

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import java.net.URL
import kotlin.concurrent.thread

class MomentoWidget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout)
            
            val username = widgetData.getString("latest_log_username", "No logs")
            views.setTextViewText(R.id.widget_title, "@$username")
            
            val imageUrl = widgetData.getString("latest_log_image_url", null)
            if (imageUrl != null) {
                // Download the image in a background thread
                thread {
                    try {
                        val url = URL(imageUrl)
                        val bmp = BitmapFactory.decodeStream(url.openConnection().getInputStream())
                        views.setImageViewBitmap(R.id.widget_image, bmp)
                        // Update the widget UI after image is loaded
                        appWidgetManager.updateAppWidget(widgetId, views)
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }
                }
            } else {
                views.setImageViewResource(R.id.widget_image, 0)
            }
            
            // Initial update (will show empty or cached state while downloading)
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
