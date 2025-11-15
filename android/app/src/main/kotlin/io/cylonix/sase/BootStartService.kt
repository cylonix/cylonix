package io.cylonix.sase

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import android.util.Log

class BootStartService : Service() {
    companion object {
        private const val LOG_TAG = "cylonix: BootStartService"
        private const val CHANNEL_ID = "boot_service_channel"
        private const val NOTIFICATION_ID = 9999
    }

    override fun onCreate() {
        super.onCreate()
        Log.i(LOG_TAG, "BootStartService created")
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, createNotification())
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.i(LOG_TAG, "BootStartService started")

        try {
            // Wait a bit for system to settle
            Thread.sleep(2000)

            // As a foreground service, we CAN launch activities
            Log.i(LOG_TAG, "Attempting to start MainActivity")
            try {
                val packageManager = packageManager
                val launchIntent = packageManager.getLaunchIntentForPackage(packageName)

                if (launchIntent != null) {
                    launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    launchIntent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
                    launchIntent.putExtra("started_from_boot", true)

                    startActivity(launchIntent)
                    Log.i(LOG_TAG, "Successfully started MainActivity")
                } else {
                    Log.w(LOG_TAG, "Could not get launcher intent, starting VPN without UI")
                }
            } catch (e: Exception) {
                Log.e(LOG_TAG, "Failed to start MainActivity: ${e.message}", e)
            }

            // Start VPN after a short delay
            Thread.sleep(3000)
            try {
                Log.i(LOG_TAG, "Attempting to start VPN")
                App.get().startVPN()
                Log.i(LOG_TAG, "VPN start command sent")
            } catch (e: Exception) {
                Log.e(LOG_TAG, "Failed to start VPN", e)
            }

        } catch (e: Exception) {
            Log.e(LOG_TAG, "Error in boot service", e)
        } finally {
            // Stop the service after a delay
            Thread {
                try {
                    Thread.sleep(5000)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                        stopForeground(STOP_FOREGROUND_REMOVE)
                    } else {
                        @Suppress("DEPRECATION")
                        stopForeground(true)
                    }
                    stopSelf()
                    Log.i(LOG_TAG, "BootStartService stopped")
                } catch (e: Exception) {
                    Log.e(LOG_TAG, "Error stopping service", e)
                }
            }.start()
        }

        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Boot Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Service for starting Cylonix on boot"
                setShowBadge(false)
            }
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun createNotification() = NotificationCompat.Builder(this, CHANNEL_ID)
        .setContentTitle("Cylonix")
        .setContentText("Starting Cylonix...")
        .setSmallIcon(R.mipmap.ic_launcher)
        .setPriority(NotificationCompat.PRIORITY_LOW)
        .setOngoing(true)
        .build()
}