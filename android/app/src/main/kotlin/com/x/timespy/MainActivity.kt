package com.x.timespy

import android.os.Build

import com.x.timespy.permissions.UsagePermissionHelper
import com.x.timespy.usage.UsageStatsHelper
import com.x.timespy.utils.AppInfoUtils
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel


class MainActivity : FlutterActivity() {
    private val usageStatsHelper by lazy { UsageStatsHelper(this) }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "time_spy/usage_events")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getRecentForegroundApps" -> {
                        val sinceMillis = call.argument<Long>("since") ?: 0L
                        result.success(usageStatsHelper.getRecentForegroundApps(sinceMillis))
                    }

                    "getAppCategory" -> {
                        val packageName = call.argument<String>("packageName")
                        result.success(
                            AppInfoUtils.getAppCategory(this, packageName ?: "")
                        )
                    }

                    "getLaunchCount" -> {
                        val packageName = call.argument<String>("packageName")
                        result.success(
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && packageName != null)
                                usageStatsHelper.getLaunchCount(packageName)
                            else null
                        )
                    }

                    "getAppIcon" -> {
                        val packageName = call.argument<String>("packageName")
                        result.success(
                            AppInfoUtils.getAppIconBytes(this, packageName ?: "")
                        )
                    }

                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "usage_permission_channel")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isUsagePermissionGranted" -> {
                        result.success(UsagePermissionHelper.isPermissionGranted(this))
                    }

                    "openUsageSettings" -> {
                        UsagePermissionHelper.openSettings(this)
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
    }
}
