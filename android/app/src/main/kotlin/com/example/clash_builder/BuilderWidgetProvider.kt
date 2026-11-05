package com.example.clash_builder

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import org.json.JSONArray

/** A vertically scrolling list: swipe up/down to move between accounts. */
class BuilderWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, mgr: AppWidgetManager, ids: IntArray) {
        for (id in ids) mgr.updateAppWidget(id, build(context))
        mgr.notifyAppWidgetViewDataChanged(ids, R.id.list)
        scheduleNextRefresh(context)
    }

    private fun build(context: Context): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.builder_widget)
        views.setRemoteAdapter(R.id.list, Intent(context, BuilderWidgetService::class.java))
        views.setEmptyView(R.id.list, R.id.empty_text)
        val launch = context.packageManager.getLaunchIntentForPackage(context.packageName)
        if (launch != null) {
            views.setPendingIntentTemplate(
                R.id.list,
                PendingIntent.getActivity(context, 2, launch, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE)
            )
            views.setOnClickPendingIntent(
                R.id.empty_text,
                PendingIntent.getActivity(context, 0, launch, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            )
        }
        return views
    }

    /** Countdown chronometers go negative after zero, so redraw right after the next finish. */
    private fun scheduleNextRefresh(context: Context) {
        val p = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val now = System.currentTimeMillis()
        var next = Long.MAX_VALUE
        try {
            val accs = JSONArray(p.getString("accounts_json", "[]"))
            for (i in 0 until accs.length()) {
                val vs = accs.getJSONObject(i).getJSONArray("villages")
                for (k in 0 until vs.length()) {
                    val items = vs.getJSONObject(k).getJSONArray("items")
                    for (j in 0 until items.length()) {
                        val e = items.getJSONObject(j).getLong("endsAt")
                        if (e > now && e < next) next = e
                    }
                }
            }
        } catch (_: Exception) {}
        if (next == Long.MAX_VALUE) return
        val intent = Intent(context, BuilderWidgetProvider::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            val ids = AppWidgetManager.getInstance(context)
                .getAppWidgetIds(ComponentName(context, BuilderWidgetProvider::class.java))
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
        }
        val pi = PendingIntent.getBroadcast(
            context, 1, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        (context.getSystemService(Context.ALARM_SERVICE) as AlarmManager).set(AlarmManager.RTC, next + 1500, pi)
    }
}
