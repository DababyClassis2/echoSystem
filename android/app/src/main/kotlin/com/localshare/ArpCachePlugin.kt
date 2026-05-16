package com.localshare

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.BufferedReader
import java.io.FileReader

/**
 * ArpCachePlugin
 * 
 * This plugin reads the system ARP cache to discover IP addresses of devices on the local network.
 * 
 * WHY /proc/net/arp?
 * 1. Permissions: /proc/net/arp is a world-readable kernel file in Android (Linux). 
 *    Unlike many network discovery methods, reading this file does not require 
 *    specific Android permissions (like ACCESS_FINE_LOCATION which is often required 
 *    for WiFi scanning).
 * 
 * 2. VPN Bypass: ARP (Address Resolution Protocol) operates at Layer 2 (Data Link Layer).
 *    Most VPNs operate at Layer 3 (Network Layer) or higher. Because ARP is responsible 
 *    for mapping IP addresses to physical MAC addresses on the local link, it bypasses 
 *    the VPN tunnel logic which primarily routes IP traffic. This allows us to see 
 *    local peers even when a VPN is active.
 * 
 * 3. Flag 0x2: In the ARP cache, the flag 0x2 corresponds to ATF_COM (Complete).
 *    This indicates that the address resolution is complete and the hardware address 
 *    (MAC) is known and valid. This filters out incomplete or stale entries (0x0 or 0x1).
 */
class ArpCachePlugin: FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.localshare/arp")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        if (call.method == "getArpEntries") {
            result.success(getArpEntries())
        } else {
            result.notImplemented()
        }
    }

    private fun getArpEntries(): List<String> {
        val ips = mutableListOf<String>()
        try {
            BufferedReader(FileReader("/proc/net/arp")).use { reader ->
                // Skip header line: IP address, HW type, Flags, HW address, Mask, Device
                reader.readLine()
                
                var line: String?
                while (reader.readLine().also { line = it } != null) {
                    val parts = line!!.split("\\s+".toRegex()).filter { it.isNotBlank() }
                    if (parts.size >= 4) {
                        val ip = parts[0]
                        val flags = parts[2]
                        
                        // 0x2 = ATF_COM (Complete/Resolved)
                        // Exclude 0.0.0.0 (Invalid)
                        if (flags == "0x2" && ip != "0.0.0.0") {
                            ips.add(ip)
                        }
                    }
                }
            }
        } catch (e: Exception) {
            // Return empty list on any failure (e.g. file not accessible on some restricted builds)
            return emptyList()
        }
        return ips
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
