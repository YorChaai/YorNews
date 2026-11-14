package com.example.yor_news_app

import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.Drawable
import android.net.Uri
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "yornews/browser"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInstalledBrowsers" -> {
                        result.success(queryInstalledBrowsers())
                    }
                    "openUrlInBrowser" -> {
                        val url = call.argument<String>("url")
                        val packageName = call.argument<String>("packageName")
                        if (url.isNullOrBlank()) {
                            result.error("INVALID_URL", "URL is empty", null)
                            return@setMethodCallHandler
                        }
                        result.success(openUrl(url, packageName))
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun queryInstalledBrowsers(): List<Map<String, Any>> {
        val pm = packageManager
        val probeIntent = Intent(Intent.ACTION_VIEW, Uri.parse("https://www.example.com")).apply {
            addCategory(Intent.CATEGORY_BROWSABLE)
        }
        val resolveInfos = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.queryIntentActivities(
                probeIntent,
                PackageManager.ResolveInfoFlags.of(PackageManager.MATCH_ALL.toLong()),
            )
        } else {
            @Suppress("DEPRECATION")
            pm.queryIntentActivities(probeIntent, PackageManager.MATCH_ALL)
        }

        val seen = HashSet<String>()
        val browsers = mutableListOf<Map<String, Any>>()

        for (info in resolveInfos) {
            val activityInfo = info.activityInfo ?: continue
            val pkg = activityInfo.packageName ?: continue
            if (pkg == packageName || !seen.add(pkg)) continue

            val label = info.loadLabel(pm).toString().ifBlank { pkg }
            val iconBytes = try {
                drawableToPngBytes(info.loadIcon(pm))
            } catch (_: Exception) {
                ByteArray(0)
            }
            browsers.add(
                mapOf(
                    "packageName" to pkg,
                    "label" to label,
                    "icon" to iconBytes,
                ),
            )
        }

        browsers.sortWith(
            compareBy<Map<String, Any>> {
                val pkg = it["packageName"] as String
                when (pkg) {
                    "com.android.chrome" -> 0
                    "com.chrome.beta", "com.chrome.dev" -> 1
                    "com.brave.browser" -> 2
                    "com.microsoft.emmx" -> 3
                    "org.mozilla.firefox" -> 4
                    else -> 10
                }
            }.thenBy { (it["label"] as String).lowercase() },
        )

        return browsers
    }

    private fun openUrl(url: String, targetPackage: String?): Boolean {
        val uri = Uri.parse(url)
        val intent = Intent(Intent.ACTION_VIEW, uri).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            if (!targetPackage.isNullOrBlank()) {
                setPackage(targetPackage)
            }
        }
        return try {
            startActivity(intent)
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun drawableToPngBytes(drawable: Drawable): ByteArray {
        val size = 96
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, size, size)
        drawable.draw(canvas)
        val stream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
        bitmap.recycle()
        return stream.toByteArray()
    }
}
