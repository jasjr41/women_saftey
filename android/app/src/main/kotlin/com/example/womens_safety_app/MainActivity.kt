package com.example.womens_safety_app

import android.content.IntentFilter
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private lateinit var powerButtonReceiver: PowerButtonReceiver
    private val CHANNEL = "com.example.womens_safety_app/power_button"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Set up method channel to talk to Flutter
        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                result.success(null)
            }

        // Register power button receiver
        powerButtonReceiver = PowerButtonReceiver()
        PowerButtonReceiver.onPowerButtonPressed = {
            runOnUiThread {
                flutterEngine?.dartExecutor?.binaryMessenger?.let {
                    MethodChannel(it, CHANNEL).invokeMethod("powerButtonPressed", null)
                }
            }
        }

        val filter = IntentFilter().apply {
            addAction(android.content.Intent.ACTION_SCREEN_OFF)
            addAction(android.content.Intent.ACTION_SCREEN_ON)
        }
        registerReceiver(powerButtonReceiver, filter)
    }

    override fun onDestroy() {
        super.onDestroy()
        PowerButtonReceiver.onPowerButtonPressed = null
        unregisterReceiver(powerButtonReceiver)
    }
}