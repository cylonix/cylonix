package io.cylonix.sase

import android.util.Log
import com.tailscale.ipn.App as IPNApp

class App: IPNApp() {
    companion object {
        private const val TAG = "cylonix: App"
        fun get(): IPNApp {
            Log.d(TAG, "get()")
            return IPNApp.get()
        }
    }
}