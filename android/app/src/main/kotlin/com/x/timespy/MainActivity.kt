package com.x.timespy

import android.app.usage.UsageStatsManager
import android.app.usage.UsageEvents
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.graphics.Bitmap
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.os.Build
import android.provider.Settings
import androidx.annotation.RequiresApi
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "time_spy/usage_events"
    private val PERMISSION_CHANNEL = "usage_permission_channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getRecentForegroundApps" -> {
                    val sinceMillis = call.argument<Long>("since") ?: 0L
                    val map = getRecentForegroundApps(sinceMillis)
                    result.success(map)
                }

                "getAppCategory" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        val category = getAppCategory(packageName)
                        result.success(category)
                    } else {
                        result.error("NO_PACKAGE", "Package name missing", null)
                    }
                }

                "getLaunchCount" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        val packageName = call.argument<String>("packageName")
                        if (packageName != null) {
                            val count = getLaunchCount(packageName, usageStatsManager)
                            result.success(count)
                        } else {
                            result.error("NO_PACKAGE", "Package name missing", null)
                        }
                    } else {
                        result.error("API_NOT_SUPPORTED", "API 29+ required", null)
                    }
                }

                "getAppIcon" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        val iconBytes = getAppIcon(packageName)
                        if (iconBytes != null) {
                            result.success(iconBytes)
                        } else {
                            result.error("NO_ICON", "Icon not found", null)
                        }
                    } else {
                        result.error("NO_PACKAGE", "Package name missing", null)
                    }
                }

                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            PERMISSION_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isUsagePermissionGranted" -> {
                    val apps = usageStatsManager.queryUsageStats(
                        UsageStatsManager.INTERVAL_DAILY,
                        System.currentTimeMillis() - 1000 * 60 * 60,
                        System.currentTimeMillis()
                    )
                    result.success(apps.isNotEmpty())
                }

                "openUsageSettings" -> {
                    openUsageSettings()
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun openUsageSettings() {
        val intent = Intent(android.provider.Settings.ACTION_USAGE_ACCESS_SETTINGS)
        startActivity(intent)
    }

    private fun getRecentForegroundApps(sinceMillis: Long): Map<String, Long> {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val now = System.currentTimeMillis()
        val events = usageStatsManager.queryEvents(sinceMillis, now)
        val packageToLastForeground = mutableMapOf<String, Long>()
        val ev = UsageEvents.Event()

        while (events.hasNextEvent()) {
            events.getNextEvent(ev)
            val pkg = ev.packageName
            val type = ev.eventType
            if (type == UsageEvents.Event.MOVE_TO_FOREGROUND || type == UsageEvents.Event.ACTIVITY_RESUMED) {
                packageToLastForeground[pkg] = ev.timeStamp
            }
        }

        return packageToLastForeground
    }

    private fun getAppCategory(packageName: String): String {
        return try {
            val ai = packageManager.getApplicationInfo(packageName, 0)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val cat = ApplicationInfo.getCategoryTitle(this, ai.category)?.toString() ?: "Other"
                cat
            } else {
                "Other"
            }
        } catch (e: Exception) {
            "Other"
        }
    }

    @RequiresApi(Build.VERSION_CODES.Q)
    private fun getLaunchCount(packageName: String, usageStatsManager: UsageStatsManager): Int {
        val now = System.currentTimeMillis()
        val start = now - 1000L * 60 * 60 * 24 * 14

        val statsMap = usageStatsManager.queryAndAggregateUsageStats(start, now)
        val usageStats = statsMap[packageName] ?: return 0

        try {
            val field = usageStats.javaClass.getDeclaredField("mAppLaunchCount")
            field.isAccessible = true
            val count = field.getInt(usageStats)
            if (count >= 0) {
                return count          }
        } catch (e: NoSuchFieldException) {
            android.util.Log.w("TimeSpy", "Field mAppLaunchCount not found for $packageName")
        } catch (e: Exception) {
            android.util.Log.e("TimeSpy", "Error reading mAppLaunchCount for $packageName", e)
        }

        try {
            val field2 = usageStats.javaClass.getDeclaredField("mLaunchCount")
            field2.isAccessible = true
            val count2 = field2.getInt(usageStats)
            if (count2 >= 0) {
                return count2
            }
        } catch (e: Exception) {
            android.util.Log.w("TimeSpy", "Fallback mLaunchCount failed for $packageName")
        }
        return 0
    }

    private fun getAppIcon(packageName: String): ByteArray? {
        return try {
            val drawable = packageManager.getApplicationIcon(packageName)
            drawableToBytes(drawable)
        } catch (e: Exception) {
            null
        }
    }

    private fun drawableToBytes(drawable: Drawable): ByteArray {
        val bitmap = (drawable as BitmapDrawable).bitmap
        val stream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
        return stream.toByteArray()
    }
}
