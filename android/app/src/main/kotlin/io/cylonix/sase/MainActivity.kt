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

import com.tailscale.ipn.R as IPNR
import com.tailscale.ipn.ui.model.Ipn
import com.tailscale.ipn.ui.viewModel.VpnViewModel
import com.tailscale.ipn.ui.viewModel.MainViewModel
import com.tailscale.ipn.ui.viewModel.MainViewModelFactory

class MainActivity: FlutterFragmentActivity() {
	private val CHANNEL = "io.cylonix.sase/ts"
	private val LOG_TAG = "cylonix: MainActivity"
	private val callbackByString: MutableMap<String, String> = HashMap()

	override fun onCreate(savedInstanceState: Bundle?) {
		if (intent.getIntExtra("org.chromium.chrome.extra.TASK_ID", -1) == this.taskId) {
			this.finish()
			intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
			startActivity(intent);
		}
        Log.d(LOG_TAG, "Starting cylonix activity")
		super.onCreate(savedInstanceState)

        App.get().setStateNotifyCallback(::stateNotify)
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
    fun stateNotify(state: Ipn.State) {
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
		MethodChannel(
			flutterEngine.dartExecutor.binaryMessenger,
			CHANNEL
		).setMethodCallHandler { call, result ->
			when (call.method) {
				"check_app_update" -> {
					val url = call.argument<String>("url")
					var showDialog = call.argument<Boolean>("show_dialog") ?: true
					var showProgress = call.argument<Boolean>("show_progress") ?: true
					result.success("DONE")
				}
				"register_voice" -> {
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
				else -> {
					if (!MethodHandler().handleMethod(call, result)) {
						Log.e(LOG_TAG, call.method + " is not implemented.")
						result.notImplemented()
					}
				}
			}
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
