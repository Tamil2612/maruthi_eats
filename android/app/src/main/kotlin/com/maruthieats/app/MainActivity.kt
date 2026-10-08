package com.maruthieats.app

import android.content.pm.PackageManager
import android.content.pm.Signature
import java.security.MessageDigest
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.maruthieats.app/config"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getMapsApiKey" -> {
                    try {
                        val appInfo = packageManager.getApplicationInfo(packageName, PackageManager.GET_META_DATA)
                        val apiKey = appInfo.metaData?.getString("com.google.android.geo.API_KEY") ?: ""
                        result.success(apiKey)
                    } catch (e: Exception) {
                        result.error("UNAVAILABLE", "API key not available", e.localizedMessage)
                    }
                }
                "getAndroidHeaderInfo" -> {
                    try {
                        val pkgName = packageName
                        val sha1 = getSignatureSha1()
                        result.success(mapOf(
                            "packageName" to pkgName,
                            "sha1" to sha1
                        ))
                    } catch (e: Exception) {
                        result.error("UNAVAILABLE", "Header info not available", e.localizedMessage)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun getSignatureSha1(): String {
        try {
            val flags = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
                PackageManager.GET_SIGNING_CERTIFICATES
            } else {
                @Suppress("DEPRECATION")
                PackageManager.GET_SIGNATURES
            }
            val packageInfo = packageManager.getPackageInfo(packageName, flags)
            val signatures: Array<out Signature>? = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
                packageInfo.signingInfo?.apkContentsSigners
            } else {
                @Suppress("DEPRECATION")
                packageInfo.signatures
            }
            if (!signatures.isNullOrEmpty()) {
                val md = MessageDigest.getInstance("SHA-1")
                val digest = md.digest(signatures[0].toByteArray())
                return digest.joinToString("") { "%02X".format(it) }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return ""
    }
}
