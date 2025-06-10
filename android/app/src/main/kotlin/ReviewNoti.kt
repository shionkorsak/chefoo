package com.example.chefoo

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.app.NotificationChannel
import android.app.NotificationManager
import androidx.core.app.NotificationCompat
import android.util.Log
import androidx.core.content.ContextCompat

class ReviewNoti : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        Log.d("ReviewNoti", "Broadcast received for post-navigation reminder.")
        val channelId = "post_nav_channel"
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        val channel = NotificationChannel(channelId, "Chefoo Reminder", NotificationManager.IMPORTANCE_HIGH )
        manager.createNotificationChannel(channel)

        val notification = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentText("Remember to tell Chefoo about your meal")
            .setStyle(NotificationCompat.BigTextStyle().bigText("Remember to tell Chefoo about your delicious lunch 😋"))
            .setAutoCancel(true)
            .build()

        manager.notify(2002, notification)

    }
}