package com.x.timespy.permissions

import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.provider.Settings

object UsagePermissionHelper {
    fun isPermissionGranted(context: Context): Boolean {
        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val stats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            System.currentTimeMillis() - 1000 * 60 * 60,
            System.currentTimeMillis()
        )
        return stats.isNotEmpty()
    }

    fun openSettings(context: Context) {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
    }
}
