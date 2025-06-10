package com.example.chefoo

import android.util.Log

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import java.util.Calendar
import android.app.AlarmManager
import android.app.PendingIntent

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.d("BootReceiver", "BOOT_COMPLETED received, scheduling alarm.")
            scheduleNotification(context, 12, 0, 100)
            scheduleNotification(context, 12, 15, 101)
            scheduleNotification(context, 12, 30, 102)
            scheduleNotification(context, 18, 0, 103)
            scheduleNotification(context, 18, 15, 104)
            scheduleNotification(context, 18, 30, 105)
        }
    }

    private fun scheduleNotification(context: Context, hour: Int, minute: Int, requestCode: Int) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, AlarmReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            context, requestCode, intent, PendingIntent.FLAG_IMMUTABLE
        )

        val calendar = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
            if (before(Calendar.getInstance())) {
                add(Calendar.DATE, 1)
            }
        }

        alarmManager.setRepeating(
            AlarmManager.RTC_WAKEUP,
            calendar.timeInMillis,
            AlarmManager.INTERVAL_DAY,
            pendingIntent
        )
    }
}