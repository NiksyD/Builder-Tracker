package com.example.clash_builder

import android.content.Context
import android.content.Intent
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import org.json.JSONArray

/** One list item per account: its Home Village and Builder Base builders. */
class BuilderWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory = Factory(applicationContext)

    private class Row(val name: String, val endsAt: Long?)
    private class Section(val title: String, val rows: List<Row>)
    private class Account(val name: String, val sections: List<Section>)

    private class Factory(private val context: Context) : RemoteViewsFactory {
        private var accounts: List<Account> = emptyList()

        override fun onCreate() {}
        override fun onDataSetChanged() {
            val p = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
            val out = ArrayList<Account>()
            try {
                val arr = JSONArray(p.getString("accounts_json", "[]"))
                for (i in 0 until arr.length()) {
                    val a = arr.getJSONObject(i)
                    val secs = ArrayList<Section>()
                    val vs = a.getJSONArray("villages")
                    for (k in 0 until vs.length()) {
                        val v = vs.getJSONObject(k)
                        val items = v.getJSONArray("items")
                        val rows = ArrayList<Row>()
                        for (j in 0 until items.length()) {
                            val it = items.getJSONObject(j)
                            rows.add(Row(it.getString("name").replace("  ›  Level ", " · Lv "), it.getLong("endsAt")))
                        }
                        rows.sortBy { it.endsAt }
                        while (rows.size < v.getInt("total")) rows.add(Row("Builder ${rows.size + 1}", null))
                        secs.add(Section(v.getString("title"), rows))
                    }
                    out.add(Account(a.optString("name", ""), secs))
                }
            } catch (_: Exception) {}
            accounts = out
        }

        override fun onDestroy() {}
        override fun getCount() = accounts.size

        override fun getViewAt(position: Int): RemoteViews {
            val v = RemoteViews(context.packageName, R.layout.widget_account)
            val acc = accounts.getOrNull(position) ?: return v
            val now = System.currentTimeMillis()
            v.setTextViewText(R.id.account, acc.name)
            v.setViewVisibility(R.id.account, if (acc.name.isEmpty()) View.GONE else View.VISIBLE)
            v.removeAllViews(R.id.content)
            for (s in acc.sections) {
                val busy = s.rows.count { it.endsAt != null && it.endsAt > now }
                val h = RemoteViews(context.packageName, R.layout.widget_section)
                h.setTextViewText(R.id.section_title, s.title)
                h.setTextViewText(R.id.section_free, "${s.rows.size - busy} of ${s.rows.size} free")
                v.addView(R.id.content, h)
                s.rows.forEachIndexed { i, r -> v.addView(R.id.content, row(r, i, now)) }
            }
            v.setOnClickFillInIntent(R.id.item_root, Intent())
            return v
        }

        private fun row(r: Row, index: Int, now: Long): RemoteViews {
            val v = RemoteViews(context.packageName, R.layout.widget_row)
            v.setTextViewText(R.id.name, r.name)
            v.setViewVisibility(R.id.divider, if (index == 0) View.GONE else View.VISIBLE)
            val end = r.endsAt
            if (end == null || end <= now) {
                v.setViewVisibility(R.id.chrono, View.GONE)
                v.setViewVisibility(R.id.ready, View.VISIBLE)
                v.setTextViewText(R.id.ready, if (end == null) "Free" else "Ready!")
            } else {
                v.setViewVisibility(R.id.chrono, View.VISIBLE)
                v.setViewVisibility(R.id.ready, View.GONE)
                v.setChronometerCountDown(R.id.chrono, true)
                v.setChronometer(R.id.chrono, SystemClock.elapsedRealtime() + (end - now), null, true)
            }
            return v
        }

        override fun getLoadingView(): RemoteViews? = null
        override fun getViewTypeCount() = 1
        override fun getItemId(position: Int) = position.toLong()
        override fun hasStableIds() = false
    }
}
