package io.cylonix.sase

import com.tailscale.ipn.App as IPNApp

class App: IPNApp() {
    companion object {
        fun get(): IPNApp {
            return IPNApp.get()
        }
    }
}