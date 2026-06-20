package org.quitmate.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat

/**
 * Foreground service that reschedules notifications after device boot.
 *
 * Required by Android 8+ and Chinese ROMs that restrict background execution.
 * The service creates a notification channel, shows a foreground notification,
 * then sends a broadcast to Flutter to trigger notification rescheduling.
 *
 * This service is declared with foregroundServiceType="specialUse" in the manifest
 * for Android 14+ compatibility.
 */
class NotificationRescheduleService : Service() {
    companion object {
        private const val TAG = "QuitMate.RescheduleService"
        private const val CHANNEL_ID = "quitmate_reschedule"
        private const val NOTIFICATION_ID = 99999
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, buildNotification())
        Log.i(TAG, "Foreground service started for notification reschedule")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Notify Flutter side via broadcast
        try {
            val appContext = applicationContext
            // Send a broadcast that the Flutter side can pick up
            val notifyIntent = Intent("org.quitmate.app.RESCHEDULE_NOTIFICATIONS")
            notifyIntent.setPackage(appContext.packageName)
            appContext.sendBroadcast(notifyIntent)
            Log.i(TAG, "Reschedule broadcast sent to Flutter")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to send reschedule broadcast", e)
        }

        // Stop the foreground service after a brief delay
        Thread {
            try {
                Thread.sleep(3000) // Brief delay for Flutter to process
            } catch (_: InterruptedException) {
                // Ignore
            }
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
            Log.i(TAG, "Foreground service completed")
        }.start()

        return START_NOT_STICKY
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "通知恢复",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "设备重启后恢复通知提醒"
                setShowBadge(false)
            }
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.createNotificationChannel(channel)
        }
    }

    private fun buildNotification() = NotificationCompat.Builder(this, CHANNEL_ID)
        .setContentTitle("QuitMate")
        .setContentText("正在恢复提醒设置...")
        .setSmallIcon(android.R.drawable.ic_popup_reminder)
        .setPriority(NotificationCompat.PRIORITY_LOW)
        .setOngoing(true)
        .build()
}