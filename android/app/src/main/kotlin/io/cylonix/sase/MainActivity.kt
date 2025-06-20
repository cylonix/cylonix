package io.cylonix.sase

import android.Manifest
import android.app.Activity
import android.app.AlertDialog
import android.bluetooth.BluetoothAdapter
import android.content.Intent
import android.content.Context
import android.content.pm.ActivityInfo
import android.content.pm.PackageManager;
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.Bundle
import android.provider.Settings
import android.util.Log
import android.widget.Toast
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContract
import androidx.annotation.NonNull
import androidx.core.content.ContextCompat
import androidx.lifecycle.ViewModelProvider
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel;
import java.util.*
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

import com.tailscale.ipn.R as IPNR
import com.tailscale.ipn.setIpnStateChangeCallback
import com.tailscale.ipn.setNotificationCallback
import com.tailscale.ipn.getLogContent
import com.tailscale.ipn.sendCommand
import com.tailscale.ipn.ui.model.Ipn
import com.tailscale.ipn.ui.model.Ipn.Notify
import com.tailscale.ipn.ui.model.Netmap
import com.tailscale.ipn.ui.viewModel.VpnViewModel
import com.tailscale.ipn.ui.viewModel.MainViewModel
import com.tailscale.ipn.ui.viewModel.MainViewModelFactory

class MainActivity: FlutterFragmentActivity() {
    companion object {
	    private const val CHANNEL = "io.cylonix.sase/wg"
	    private const val LOG_TAG = "cylonix: MainActivity"
        private const val START_AT_ROOT = "startAtRoot"
    }
	private val callbackByString: MutableMap<String, String> = HashMap()
    private var methodChannel: MethodChannel? = null

	override fun onCreate(savedInstanceState: Bundle?) {
		if (intent.getIntExtra("org.chromium.chrome.extra.TASK_ID", -1) == this.taskId) {
			this.finish()
			intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
			startActivity(intent);
		}
        Log.d(LOG_TAG, "Starting cylonix activity")
		super.onCreate(savedInstanceState)

        App.get().setIpnStateChangeCallback(::onIpnStateChanged)
        App.get().setNotificationCallback(::onNotificationReceived)
        Log.d(LOG_TAG, "onCreate: setting up VPN permission launcher")
        setVpnPermissionLauncher()
	}

    private lateinit var vpnPermissionLauncher: ActivityResultLauncher<Intent>
    private val viewModel: MainViewModel by lazy {
      val app = App.get()
      vpnViewModel = app.getAppScopedViewModel()
      ViewModelProvider(this, MainViewModelFactory(vpnViewModel)).get(MainViewModel::class.java)
    }
    private lateinit var vpnViewModel: VpnViewModel
    private fun setVpnPermissionLauncher() {
        vpnViewModel = ViewModelProvider(App.get()).get(VpnViewModel::class.java)
        vpnPermissionLauncher =
        registerForActivityResult(VpnPermissionContract()) { granted ->
          if (granted) {
            Log.d(LOG_TAG, "VPN permission granted")
            vpnViewModel.setVpnPrepared(true)
            App.get().startVPN()
          } else {
            if (isAnotherVpnActive(this)) {
              Log.d(LOG_TAG, "VPN permission denied: another VPN is likely active")
              showOtherVPNConflictDialog()
            } else {
              Log.d(LOG_TAG, "VPN permission was denied by the user")
              vpnViewModel.setVpnPrepared(false)
            }
          }
          runOnUiThread {
            methodChannel?.invokeMethod("vpnPermissionResult", mapOf(
                "granted" to granted
            ))
          }
        }
        viewModel.setVpnPermissionLauncher(vpnPermissionLauncher)
    }

    private fun showOtherVPNConflictDialog() {
        AlertDialog.Builder(this)
            .setTitle(IPNR.string.vpn_permission_denied)
            .setMessage(IPNR.string.multiple_vpn_explainer)
            .setPositiveButton(IPNR.string.go_to_settings) { _, _ ->
              // Intent to open the VPN settings
              val intent = Intent(Settings.ACTION_VPN_SETTINGS)
              startActivity(intent)
            }
            .setNegativeButton(IPNR.string.cancel, null)
            .show()
    }

    fun isAnotherVpnActive(context: Context): Boolean {
        val connectivityManager =
            context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager

        val activeNetwork = connectivityManager.activeNetwork
        if (activeNetwork != null) {
          val networkCapabilities = connectivityManager.getNetworkCapabilities(activeNetwork)
          if (networkCapabilities != null &&
              networkCapabilities.hasTransport(NetworkCapabilities.TRANSPORT_VPN)) {
            return true
          }
        }
        return false
    }

    private var ipnState: Ipn.State = Ipn.State.NoState
    fun onIpnStateChanged(state: Ipn.State) {
        val isPrepared = vpnViewModel.vpnPrepared.value
        Log.d(LOG_TAG, "$ipnState -> $state vpn isPrepared=$isPrepared")
        if (ipnState != state && state == Ipn.State.Running) {
            when {
                !isPrepared -> viewModel.showVPNPermissionLauncherIfUnauthorized()
                isPrepared -> App.get().startVPN()
            }
        }
        ipnState = state
    }

	// Set bluetooth name.
	fun setBluetoothName(name: String?): String? {
		if (name == null) {
			return "name cannot be null"
		}
		val adapter = BluetoothAdapter.getDefaultAdapter()
		if (adapter == null) {
			return "Failed to get bluetooth adapator."
		}
		val oldName = adapter.getName();
		if (oldName == name) {
			Log.w(LOG_TAG, "same bluetooth name!")
			return null
		}
		if (!adapter.isEnabled()) {
			return "Bluetooth is not yet enabled."
		}
		if (!adapter.setName(name)) {
			return "Failed to set bluetooth name."
		}
		return null
	}

	// Get bluetooth name.
	fun getBluetoothName(): String? {
		val adapter = BluetoothAdapter.getDefaultAdapter()
		if (adapter == null) {
			Log.e(LOG_TAG, "Failed to get bluetooth adapator.")
			return null;
		}
		return adapter.getName();
	}

	override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        )

		methodChannel?.setMethodCallHandler { call, result ->
			when (call.method) {
				"check_app_update" -> {
					val url = call.argument<String>("url")
					var showDialog = call.argument<Boolean>("show_dialog") ?: true
					var showProgress = call.argument<Boolean>("show_progress") ?: true
					result.success("DONE")
				}
				"get_bluetooth_name" -> {
					Log.d(LOG_TAG, "get bluetooth name")
					val name = getBluetoothName()
					if (name == null) {
						result.error("ERROR", "failed to get bluetooth name", null)
					} else {
						Log.d(LOG_TAG, "bluetooth name is " + name);
						result.success(name)
					}
				}
				"set_bluetooth_name" -> {
					val name = call.argument<String>("name")
					Log.d(LOG_TAG, "set bluetooth name to " + name)
					val err = setBluetoothName(name)
					if (err != null) {
						Log.e(LOG_TAG, err)
						result.error("ERROR", err, null)
					} else {
						Log.d(LOG_TAG, "set bluetooth name success")
						result.success("DONE")
					}
				}
				"set_landscape_mode" -> {
					setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE)
					Log.d(LOG_TAG, "set landscape mode")
					result.success("DONE")
				}
				"set_portrait_mode" -> {
					setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_PORTRAIT)
					Log.d(LOG_TAG, "set portrait mode")
					result.success("DONE")
				}
                "checkVPNPermission" -> {
                    Log.d(LOG_TAG, "checkVPNPermission")
                    try {
                        val id = call.arguments as String
                        Log.d(LOG_TAG, "Checking VPN permission for id: $id")
                        val state = vpnViewModel.vpnPrepared.value ?: false
                        methodChannel?.invokeMethod("tunnelCreated", mapOf(
                            "isCreated" to state,
                            "id" to id
                        ))
                        result.success("Success")
                    } catch (e: Exception) {
                        Log.e(LOG_TAG, "Error in checkVPNPermission: ${e.message}")
                        result.error(
                            "INVALID_ARGUMENT",
                            "Failed to process VPN permission check: ${e.message}",
                            null
                        )
                    }
                }
                "sendCommand" -> {
                    try {
                        val command = call.argument<String>("cmd")
                        val id = call.argument<String>("id")
                        val args = call.argument<String>("args")
                        //Log.d(LOG_TAG, "sendCommand: cmd=$command, id=$id, ars=$args")
                        handleSendCommand(command, id, args)
                    } catch (e: Exception) {
                        Log.e(LOG_TAG, "Error in sendCommand: ${e.message}")
                        result.error(
                            "INVALID_ARGUMENT",
                            "Failed to process sendCommand request: ${e.message}",
                            null
                        )
                        return@setMethodCallHandler
                    }
                    result.success("Success")
                }
                "loginComplete" -> {
                    Log.d(LOG_TAG, "loginComplete called")
                    loginComplete()
                    result.success("Success")
                }
                "getLogs" -> {
                    Log.d(LOG_TAG, "logs called")
                    try {
                        val id = call.arguments as String
                        Log.d(LOG_TAG, "Fetching logs for id: $id")
                        val logContent = App.get().getLogContent(true)
                        val logLines = logContent.split("\n").filter { it.isNotEmpty() }
                        methodChannel?.invokeMethod("logs", mapOf(
                            "logs" to logLines,
                            "id" to id
                        ))
                    } catch (e: Exception) {
                        Log.e(LOG_TAG, "Error in logs: ${e.message}")
                        result.error(
                            "INVALID_ARGUMENT",
                            "Failed to process logs request: ${e.message}",
                            null
                        )
                        return@setMethodCallHandler
                    }
                    result.success("Success")
                }
				else -> {
					Log.e(LOG_TAG, call.method + " is not implemented.")
					result.notImplemented()
				}
			}
		}
	}

    private fun handleSendCommand(command: String?, id: String?, args: String?) {
        if (command == null || command.isEmpty()) {
            Log.e(LOG_TAG, "Invalid arguments for sendCommand: command=$command")
            return
        }
        //Log.d(LOG_TAG, "Handling sendCommand: command=$command, id=$id, args=$args")
        // Fork a thread to handle the command
        Thread {
            var cmdResult = App.get().sendCommand(command, args ?: "")
            //Log.d(LOG_TAG, "command result: $cmdResult")
            // If we have an ID, send the result back through method channel
            if (!id.isNullOrEmpty()) {
                runOnUiThread {
                    methodChannel?.invokeMethod("commandResult", mapOf(
                        "id" to id,
                        "cmd" to command,
                        "result" to cmdResult
                    ))
                }
            }
        }.start()
    }

    private var lastNotification: Notify? = null
    private fun onNotificationReceived(notification: Notify) {
        //Log.d(LOG_TAG, "Notification received: $notification")
        lastNotification = notification.copy(
            State = notification.State ?: lastNotification?.State,
            NetMap = notification.NetMap ?: lastNotification?.NetMap,
            Prefs = notification.Prefs ?: lastNotification?.Prefs,
            Engine = notification.Engine ?: lastNotification?.Engine,
            Health = notification.Health ?: lastNotification?.Health,
        )
        runOnUiThread {
            methodChannel?.invokeMethod("notification", Json.encodeToString(notification))
        }
    }

    private fun loginComplete() {
        Log.d(LOG_TAG, "Login completion")
        try {
            val intent =
            Intent(applicationContext, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                action = Intent.ACTION_MAIN
                addCategory(Intent.CATEGORY_LAUNCHER)
                putExtra(START_AT_ROOT, true)
            }
            startActivity(intent)
        } catch (e: Exception) {
            Log.e(LOG_TAG, "Login: failed to start MainActivity: $e")
        }
    }
}

class VpnPermissionContract : ActivityResultContract<Intent, Boolean>() {
    override fun createIntent(context: Context, input: Intent): Intent {
      return input
    }

    override fun parseResult(resultCode: Int, intent: Intent?): Boolean {
      return resultCode == Activity.RESULT_OK
    }
}
