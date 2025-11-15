package io.cylonix.sase

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.UserManager
import android.util.Log
import java.io.File

class BootReceiver : BroadcastReceiver() {
    companion object {
        private const val LOG_TAG = "cylonix: BootReceiver"
        private const val PREFS_NAME = "CylonixPrefs"
        private const val KEY_AUTO_START = "auto_start_enabled"
    }

    override fun onReceive(context: Context, intent: Intent) {
        Log.i(LOG_TAG, "onReceive called with action: ${intent.action}")

        when (intent.action) {
            Intent.ACTION_LOCKED_BOOT_COMPLETED -> {
                // Device booted but still locked - ignore if user is locked
                Log.i(LOG_TAG, "Device is locked, skipping")
                return
            }
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_USER_UNLOCKED,
            "android.intent.action.QUICKBOOT_POWERON" -> {
                Log.i(LOG_TAG, "Boot/unlock completed detected")

                // Double-check that user is actually unlocked
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    val userManager = context.getSystemService(Context.USER_SERVICE) as? UserManager
                    if (userManager?.isUserUnlocked == false) {
                        Log.i(LOG_TAG, "User still locked, skipping")
                        return
                    }
                }

                // Check auto-start preference from multiple locations
                val autoStartEnabled = getAutoStartPreference(context)

                Log.i(LOG_TAG, "Auto-start: $autoStartEnabled")

                if (!autoStartEnabled) {
                    Log.i(LOG_TAG, "Auto-start is disabled, skipping")
                    return
                }

                // Start the service which can then launch the activity
                startBootService(context)
            }
            else -> {
                Log.w(LOG_TAG, "Received unexpected action: ${intent.action}")
            }
        }
    }

    private fun getAutoStartPreference(context: Context): Boolean {
        // 1. Try regular credential-encrypted storage
        val regularEnabled = try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val enabled = prefs.getBoolean(KEY_AUTO_START, true)
            Log.i(LOG_TAG, "Regular storage auto-start: $enabled")
            enabled
        } catch (e: Exception) {
            Log.w(LOG_TAG, "Cannot access regular storage: ${e.message}")
            null
        }

        // 2. Try device-protected storage
        val deviceEnabled = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            try {
                val deviceContext = context.createDeviceProtectedStorageContext()
                val prefs = deviceContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                val enabled = prefs.getBoolean(KEY_AUTO_START, true)
                Log.i(LOG_TAG, "Device-protected storage auto-start: $enabled")
                enabled
            } catch (e: Exception) {
                Log.w(LOG_TAG, "Cannot access device-protected storage: ${e.message}")
                null
            }
        } else {
            null
        }

        // Use the first non-null value, preferring regular storage
        return regularEnabled ?: deviceEnabled ?: true
    }

    private fun startBootService(context: Context) {
        try {
            val serviceIntent = Intent(context, BootStartService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
            Log.i(LOG_TAG, "Successfully started BootStartService")
        } catch (e: Exception) {
            Log.e(LOG_TAG, "Failed to start BootStartService", e)
        }
    }
}