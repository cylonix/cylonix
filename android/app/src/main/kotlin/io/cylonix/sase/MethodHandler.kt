package io.cylonix.sase

import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result;

class MethodHandler {
	private val LOG_TAG = "cylonix-net"
	public fun handleMethod(call: MethodCall, result: Result): Boolean {
		when (call.method) {
			"logout" -> {
				Log.d(LOG_TAG, "user logout")
				//App.onLogout()
				result.success("DONE")
				return true
			}
			"start_stop_running" -> {
				val start = call.argument<Boolean>("start")
				Log.d(LOG_TAG, "start/stop: " + start.toString())
				if (start != null) {
					//App.onStartStopVPN(start)
					result.success("DONE")
				} else {
					result.error("BAD_ARG", "Invalid argument", null)
				}
				return true
			}
			"set_control_url" -> {
				val server = call.argument<String>("server")
				Log.d(LOG_TAG, "server: " + server)
				//App.onSetControlURL(server)
				result.success("DONE")
				return true
			}
			"set_exit_node_ip" -> {
				val exitNodeIP = call.argument<String>("exitNodeIP")
				Log.d(LOG_TAG, "exitNode ip: " + exitNodeIP)
				//App.onSetExitNodeIP(exitNodeIP)
				result.success("DONE")
				return true
			}
			"set_exit_node_id" -> {
				val exitNodeID = call.argument<String>("exitNodeID")
				Log.d(LOG_TAG, "exitNodeID: " + exitNodeID)
				//App.onSetExitNodeID(exitNodeID)
				result.success("DONE")
				return true
			}
			"get_status" -> {
				val includePeers = call.argument<Boolean>("includePeers")
				// Don't show logs as it is mostly periodical calls from UI.
				//Log.d(LOG_TAG, "includePeers: " + includePeers.toString())
				if (includePeers != null) {
					//var status = App.onGetStatus(includePeers)
					//Log.d(LOG_TAG, "status: " + status)
					//result.success(status)
                    result.success("{}")
				} else {
					result.error("BAD_ARG", "Invalid argument", null)
				}
				//val dns = App.onGetDnsServers()
				//Log.d(LOG_TAG, "DNS servers: " + dns.joinToString(" "))
				return true
			}
			"get_dns_servers" -> {
				//val dns = App.onGetDnsServers().joinToString(" ")
				//Log.d(LOG_TAG, "DNS servers: " + dns)
				//result.success(dns)
                result.success("")
				return true
			}
			"get_auth_key_in_use" -> {
				//val authKey = App.onGetAuthKeyInUse()
				//Log.d(LOG_TAG, "Auth key in use: " + authKey)
				//result.success(authKey)
                result.success("")
				return true
			}
			"get_logs" -> {
				//val logs = App.onGetLogs()
				Log.d(LOG_TAG, "get logs")
				//result.success(logs)
                result.success("")
				return true
			}
			else -> {
				return false
			}
		}
	}
}