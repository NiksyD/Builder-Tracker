package com.example.clash_builder

import android.content.Context
import android.content.Intent
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import org.json.JSONArray

class BuilderWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory = Factory(applicationContext)

    private class Row(val name: String, val endsAt: Long?)

    private class Factory(private val context: Context) : RemoteViewsFactory {
        private var rows: List<Row> = emptyList()

        override fun onCreate() {}
        override fun onDataSetChanged() {
            val p = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
            val sel = p.getString("selected_village", "home") ?: "home"
            val total = if (sel == "home") p.getInt("home_builders", 5) else p.getInt("base_builders", 2)
            val list = ArrayList<Row>()
            try {
                val arr = JSONArray(p.getString("upgrades_json", "[]"))
                for (i in 0 until arr.length()) {
                    val o = arr.getJSONObject(i)
                    if (o.getString("village") == sel) {
                        list.add(Row(o.getString("name").replace("  ›  Level ", " · Lv "), o.getLong("endsAt")))
                    }
                }
            } catch (_: Exception) {}
            list.sortBy { it.endsAt }
            var n = 1
            while (list.size < total) { list.add(Row("Builder ${list.size + 1}", null)); n++ }
            rows = list
        }

        override fun onDestroy() {}
        override fun getCount() = rows.size
        override fun getViewAt(position: Int): RemoteViews {
            val v = RemoteViews(context.packageName, R.layout.widget_row)
            val r = rows.getOrNull(position) ?: return v
            val now = System.currentTimeMillis()
            v.setTextViewText(R.id.name, r.name)
            v.setViewVisibility(R.id.divider, if (position == 0) View.GONE else View.VISIBLE)
            val end = r.endsAt
            when {
                end == null -> {
                    v.setViewVisibility(R.id.chrono, View.GONE)
                    v.setViewVisibility(R.id.ready, View.VISIBLE)
                    v.setTextViewText(R.id.ready, "Free")
                }
                end <= now -> {
                    v.setViewVisibility(R.id.chrono, View.GONE)
                    v.setViewVisibility(R.id.ready, View.VISIBLE)
                    v.setTextViewText(R.id.ready, "Ready!")
                }
                else -> {
                    v.setViewVisibility(R.id.chrono, View.VISIBLE)
                    v.setViewVisibility(R.id.ready, View.GONE)
                    v.setChronometerCountDown(R.id.chrono, true)
                    v.setChronometer(R.id.chrono, SystemClock.elapsedRealtime() + (end - now), null, true)
                }
            }
            v.setOnClickFillInIntent(R.id.row_root, Intent())
            return v
        }
        override fun getLoadingView(): RemoteViews? = null
        override fun getViewTypeCount() = 1
        override fun getItemId(position: Int) = position.toLong()
        override fun hasStableIds() = false
    }
}
