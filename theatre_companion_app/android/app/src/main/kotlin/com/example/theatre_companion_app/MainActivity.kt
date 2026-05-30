package com.example.theatre_companion_app

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "com.example.theatre_companion_app/foreground"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    "startService" -> {
                        val sessionName = call.argument<String>("sessionName") ?: ""
                        val role        = call.argument<String>("role")        ?: ""
                        val intent = Intent(this, StageSyncForegroundService::class.java).apply {
                            action = StageSyncForegroundService.ACTION_START
                            putExtra(StageSyncForegroundService.EXTRA_SESSION, sessionName)
                            putExtra(StageSyncForegroundService.EXTRA_ROLE, role)
                        }
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(null)
                    }

                    "stopService" -> {
                        val intent = Intent(this, StageSyncForegroundService::class.java).apply {
                            action = StageSyncForegroundService.ACTION_STOP
                        }
                        startService(intent)
                        result.success(null)
                    }

                    "isIgnoringBatteryOptimizations" -> {
                        val pm = getSystemService(PowerManager::class.java)
                        result.success(pm.isIgnoringBatteryOptimizations(packageName))
                    }

                    "requestIgnoreBatteryOptimizations" -> {
                        val intent = Intent(
                            Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                            Uri.parse("package:$packageName"),
                        )
                        startActivity(intent)
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
    }
}
