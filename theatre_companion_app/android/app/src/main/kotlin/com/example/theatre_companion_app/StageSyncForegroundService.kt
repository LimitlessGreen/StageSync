package com.example.theatre_companion_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat

/**
 * Foreground Service für StageSync.
 *
 * Hält die App aktiv wenn der Bildschirm aus ist oder die App im Hintergrund läuft.
 * Zeigt eine persistente Notification damit Android den Prozess nicht terminiert.
 *
 * Typen:
 *  - MEDIA_PLAYBACK  → Audio-Node darf im Hintergrund abspielen (Android 14+)
 *  - DATA_SYNC       → gRPC-Streams und Heartbeat bleiben aktiv (Android 14+)
 *  - CONNECTED_DEVICE → BLE-Verbindung bleibt offen (Android 14+)
 */
class StageSyncForegroundService : Service() {

    companion object {
        const val CHANNEL_ID      = "stagesync_foreground"
        const val NOTIFICATION_ID = 1001
        const val ACTION_START    = "ACTION_START"
        const val ACTION_STOP     = "ACTION_STOP"
        const val EXTRA_SESSION   = "session_name"
        const val EXTRA_ROLE      = "node_role"
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
                return START_NOT_STICKY
            }
            else -> {
                val sessionName = intent?.getStringExtra(EXTRA_SESSION) ?: "Session"
                val role        = intent?.getStringExtra(EXTRA_ROLE)    ?: ""
                startForegroundCompat(buildNotification(sessionName, role))
            }
        }
        return START_STICKY
    }

    private fun startForegroundCompat(notification: Notification) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            // Android 14+ benötigt explizite foregroundServiceType-Flags
            ServiceCompat.startForeground(
                this,
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK or
                ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC or
                ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE,
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun buildNotification(sessionName: String, role: String): Notification {
        val launchIntent = packageManager
            .getLaunchIntentForPackage(packageName)
            ?.apply { flags = Intent.FLAG_ACTIVITY_SINGLE_TOP }
        val pendingIntent = PendingIntent.getActivity(
            this, 0, launchIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )

        val contentText = buildString {
            append(sessionName)
            if (role.isNotEmpty()) append(" · $role")
        }

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("StageSync aktiv")
            .setContentText(contentText)
            .setSmallIcon(android.R.drawable.ic_media_play)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            CHANNEL_ID,
            "StageSync Hintergrund-Betrieb",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Hält StageSync aktiv während einer Show"
            setShowBadge(false)
        }
        val mgr = getSystemService(NotificationManager::class.java)
        mgr.createNotificationChannel(channel)
    }
}
