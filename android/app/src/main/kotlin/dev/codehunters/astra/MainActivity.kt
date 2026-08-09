package dev.codehunters.astra

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "dev.codehunters.astra/share_bridge"
        private const val METHOD_GET_INITIAL_SHARE = "getInitialShareText"
        private const val METHOD_ON_SHARE_RECEIVED = "onShareReceived"
    }

    private var sharedText: String? = null
    private var methodChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Handle intent if the app is cold-started via a sharesheet
        handleIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            if (call.method == METHOD_GET_INITIAL_SHARE) {
                result.success(sharedText)
                // Consume cold-start text immediately so it is not processed twice
                sharedText = null 
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
        // If engine is already configured (warm intent), notify Flutter immediately
        sharedText?.let { text ->
            methodChannel?.invokeMethod(METHOD_ON_SHARE_RECEIVED, text)
            // Consume warm-intent text immediately
            sharedText = null
        }
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) return
        val action = intent.action
        val type = intent.type

        if (Intent.ACTION_SEND == action && type != null) {
            if ("text/plain" == type) {
                val text = intent.getStringExtra(Intent.EXTRA_TEXT)
                if (!text.isNullOrBlank()) {
                    sharedText = text
                }
            }
        }
    }
}
