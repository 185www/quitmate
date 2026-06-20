package org.quitmate.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

/**
 * Boot/Update receiver — re-registers daily notifications after device reboot.
 *
 * On Chinese ROMs (MIUI, ColorOS, HarmonyOS), background AlarmManager schedules
 * are wiped after reboot. This receiver ensures the daily reminder is rescheduled.
 *
 * The actual reschedule logic is handled by [NotificationRescheduleService]
 * to avoid ANR in the restricted broadcast receiver context.
 */
class BootCompletedReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "QuitMate.BootReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == null) return

        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED -> {
                Log.i(TAG, "Device booted or app updated — rescheduling notifications")
                val serviceIntent = Intent(context, NotificationRescheduleService::class.java)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(serviceIntent)
                } else {
                    context.startService(serviceIntent)
                }
            }
        }
    }
}