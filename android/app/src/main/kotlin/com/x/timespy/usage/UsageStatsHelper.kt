package com.x.timespy.usage

import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.os.Build
import androidx.annotation.RequiresApi
import android.content.Context

class UsageStatsHelper(private val context: Context) {

    private val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager

    fun getRecentForegroundApps(sinceMillis: Long): Map<String, Long> {
        val now = System.currentTimeMillis()
        val events = usageStatsManager.queryEvents(sinceMillis, now)
        val usageEvent = UsageEvents.Event()
        val packageToLastForeground = mutableMapOf<String, Long>()

        while (events.hasNextEvent()) {
            events.getNextEvent(usageEvent)
            if (usageEvent.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND ||
                usageEvent.eventType == UsageEvents.Event.ACTIVITY_RESUMED) {
                packageToLastForeground[usageEvent.packageName] = usageEvent.timeStamp
            }
        }

        return packageToLastForeground
    }

    @RequiresApi(Build.VERSION_CODES.Q)
    fun getLaunchCount(packageName: String): Int {
        val now = System.currentTimeMillis()
        val start = now - 1000L * 60 * 60 * 24 * 14
        val statsMap = usageStatsManager.queryAndAggregateUsageStats(start, now)
        val usageStats = statsMap[packageName] ?: return 0

        try {
            val mAppLaunchCount = usageStats.javaClass.getDeclaredField("mAppLaunchCount")
            mAppLaunchCount.isAccessible = true
            return mAppLaunchCount.getInt(usageStats)
        } catch (_: Exception) { /* fallback below */ }

        try {
            val mLaunchCount = usageStats.javaClass.getDeclaredField("mLaunchCount")
            mLaunchCount.isAccessible = true
            return mLaunchCount.getInt(usageStats)
        } catch (_: Exception) {}

        return 0
    }
}
