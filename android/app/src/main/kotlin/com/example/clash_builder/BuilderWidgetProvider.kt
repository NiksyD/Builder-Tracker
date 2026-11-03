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

class BuilderWidgetProvider : AppWidgetProvider() {

    private class Item(val name: String, val village: String, val endsAt: Long)

    override fun onUpdate(context: Context, mgr: AppWidgetManager, ids: IntArray) {
        for (id in ids) mgr.updateAppWidget(id, build(context))
        mgr.notifyAppWidgetViewDataChanged(ids, R.id.list)
        scheduleNextRefresh(context)
    }

    private fun load(context: Context): Triple<List<Item>, Int, Int> {
        val p = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val items = ArrayList<Item>()
        try {
            val arr = JSONArray(p.getString("upgrades_json", "[]"))
            for (i in 0 until arr.length()) {
                val o = arr.getJSONObject(i)
                items.add(Item(o.getString("name"), o.getString("village"), o.getLong("endsAt")))
            }
        } catch (_: Exception) {}
        items.sortBy { it.endsAt }
        return Triple(items, p.getInt("home_builders", 5), p.getInt("base_builders", 2))
    }

    private fun selected(context: Context): String =
        context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
            .getString("selected_village", "home") ?: "home"

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION_SELECT) {
            val v = intent.getStringExtra("village") ?: "home"
            context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
                .edit().putString("selected_village", v).apply()
            val mgr = AppWidgetManager.getInstance(context)
            val ids = mgr.getAppWidgetIds(ComponentName(context, BuilderWidgetProvider::class.java))
            for (id in ids) mgr.updateAppWidget(id, build(context))
            mgr.notifyAppWidgetViewDataChanged(ids, R.id.list)
            return
        }
        super.onReceive(context, intent)
    }

    private fun selectIntent(context: Context, village: String, code: Int): PendingIntent {
        val i = Intent(context, BuilderWidgetProvider::class.java).apply {
            action = ACTION_SELECT
            putExtra("village", village)
        }
        return PendingIntent.getBroadcast(
            context, code, i, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun build(context: Context): RemoteViews {
        val (all, homeTotal, baseTotal) = load(context)
        val views = RemoteViews(context.packageName, R.layout.builder_widget)
        val now = System.currentTimeMillis()
        val sel = selected(context)

        // Tabs
        val homeSel = sel == "home"
        views.setInt(R.id.tab_home, "setBackgroundResource", if (homeSel) R.drawable.tab_selected else R.drawable.tab_unselected)
        views.setInt(R.id.tab_base, "setBackgroundResource", if (homeSel) R.drawable.tab_unselected else R.drawable.tab_selected)
        views.setTextColor(R.id.tab_home, if (homeSel) 0xFFFFFFFF.toInt() else 0x8CFFFFFF.toInt())
        views.setTextColor(R.id.tab_base, if (homeSel) 0x8CFFFFFF.toInt() else 0xFFFFFFFF.toInt())
        views.setOnClickPendingIntent(R.id.tab_home, selectIntent(context, "home", 10))
        views.setOnClickPendingIntent(R.id.tab_base, selectIntent(context, "builderBase", 11))

        val items = all.filter { it.village == sel }
        val total = if (homeSel) homeTotal else baseTotal
        val active = items.count { it.endsAt > now }
        val free = maxOf(0, total - active)
        views.setTextViewText(R.id.free_text, "$free of ${maxOf(total, items.size)} free")

        views.setRemoteAdapter(R.id.list, Intent(context, BuilderWidgetService::class.java))
        views.setEmptyView(R.id.list, R.id.empty_text)
        val tpl = context.packageManager.getLaunchIntentForPackage(context.packageName)
        if (tpl != null) {
            views.setPendingIntentTemplate(
                R.id.list,
                PendingIntent.getActivity(context, 2, tpl, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE)
            )
        }

        val launch = context.packageManager.getLaunchIntentForPackage(context.packageName)
        if (launch != null) {
            views.setOnClickPendingIntent(
                R.id.widget_root,
                PendingIntent.getActivity(context, 0, launch, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            )
        }
        return views
    }

    /** Countdown chronometers go negative after zero, so redraw right after the next finish. */
    private fun scheduleNextRefresh(context: Context) {
        val (items, _, _) = load(context)
        val now = System.currentTimeMillis()
        val next = items.map { it.endsAt }.filter { it > now }.minOrNull() ?: return
        val intent = Intent(context, BuilderWidgetProvider::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            val ids = AppWidgetManager.getInstance(context)
                .getAppWidgetIds(ComponentName(context, BuilderWidgetProvider::class.java))
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
        }
        val pi = PendingIntent.getBroadcast(
            context, 1, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        am.set(AlarmManager.RTC, next + 1500, pi)
    }

    companion object {
        const val ACTION_SELECT = "com.example.clash_builder.SELECT_VILLAGE"
    }
}
