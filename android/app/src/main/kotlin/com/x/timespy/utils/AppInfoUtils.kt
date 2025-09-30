package com.x.timespy.utils

import android.content.pm.ApplicationInfo
import android.graphics.Bitmap
import android.graphics.drawable.BitmapDrawable
import android.os.Build
import android.content.Context
import java.io.ByteArrayOutputStream


object AppInfoUtils {
    fun getAppCategory(context: Context, packageName: String): String {
        return try {
            val appInfo = context.packageManager.getApplicationInfo(packageName, 0)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                ApplicationInfo.getCategoryTitle(context, appInfo.category)?.toString() ?: "Other"
            } else "Other"
        } catch (_: Exception) {
            "Other"
        }
    }

    fun getAppIconBytes(context: Context, packageName: String): ByteArray? {
        return try {
            val icon = context.packageManager.getApplicationIcon(packageName)
            val bitmap = (icon as BitmapDrawable).bitmap
            val stream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
            stream.toByteArray()
        } catch (_: Exception) {
            null
        }
    }
}
