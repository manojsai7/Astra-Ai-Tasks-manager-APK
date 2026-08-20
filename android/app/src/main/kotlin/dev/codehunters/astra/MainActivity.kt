package dev.codehunters.astra

import android.app.DownloadManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.os.Environment
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val SHARE_CHANNEL = "dev.codehunters.astra/share_bridge"
        private const val UPDATE_CHANNEL = "dev.codehunters.astra/update_bridge"
        private const val METHOD_GET_INITIAL_SHARE = "getInitialShareText"
        private const val METHOD_ON_SHARE_RECEIVED = "onShareReceived"
    }

    private var sharedText: String? = null
    private var methodChannel: MethodChannel? = null
    private var updateChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SHARE_CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            if (call.method == METHOD_GET_INITIAL_SHARE) {
                result.success(sharedText)
                sharedText = null
            } else {
                result.notImplemented()
            }
        }

        updateChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, UPDATE_CHANNEL)
        updateChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "enqueueUpdate" -> {
                    val url = call.argument<String>("url")
                    val fileName = call.argument<String>("fileName")
                    if (url.isNullOrBlank() || fileName.isNullOrBlank()) {
                        result.error("INVALID_ARGUMENT", "Update URL and file name are required.", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val request = DownloadManager.Request(Uri.parse(url))
                            .setTitle("ASTRA update")
                            .setDescription("Downloading ASTRA $fileName")
                            .setMimeType("application/vnd.android.package-archive")
                            .setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
                            .setAllowedOverMetered(true)
                            .setAllowedOverRoaming(false)
                            .setDestinationInExternalPublicDir(
                                Environment.DIRECTORY_DOWNLOADS,
                                "ASTRA/$fileName",
                            )

                        val manager = getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
                        val id = manager.enqueue(request)
                        result.success(id)
                    } catch (e: Exception) {
                        result.error("ENQUEUE_FAILED", "Android could not start the update download.", e.message)
                    }
                }

                "queryUpdate" -> {
                    val id = call.argument<Number>("downloadId")?.toLong()
                    if (id == null) {
                        result.error("INVALID_ARGUMENT", "Download ID is required.", null)
                        return@setMethodCallHandler
                    }
                    result.success(queryDownload(id))
                }

                "installUpdate" -> {
                    val id = call.argument<Number>("downloadId")?.toLong()
                    if (id == null) {
                        result.error("INVALID_ARGUMENT", "Download ID is required.", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val manager = getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
                        val uri = manager.getUriForDownloadedFile(id)
                        if (uri == null) {
                            result.error("NOT_READY", "The update has not finished downloading yet.", null)
                            return@setMethodCallHandler
                        }

                        val intent = Intent(Intent.ACTION_VIEW).apply {
                            setDataAndType(uri, "application/vnd.android.package-archive")
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("INSTALL_FAILED", "Android could not open the downloaded update.", e.message)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun queryDownload(id: Long): Map<String, Any?> {
        val manager = getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
        val cursor = manager.query(DownloadManager.Query().setFilterById(id))
        cursor.use {
            if (!it.moveToFirst()) {
                return mapOf("status" to "missing")
            }

            val status = it.getInt(it.getColumnIndexOrThrow(DownloadManager.COLUMN_STATUS))
            val bytes = it.getLong(it.getColumnIndexOrThrow(DownloadManager.COLUMN_BYTES_DOWNLOADED_SO_FAR))
            val total = it.getLong(it.getColumnIndexOrThrow(DownloadManager.COLUMN_TOTAL_SIZE_BYTES))
            val reason = it.getInt(it.getColumnIndexOrThrow(DownloadManager.COLUMN_REASON))

            val state = when (status) {
                DownloadManager.STATUS_PENDING -> "pending"
                DownloadManager.STATUS_RUNNING -> "running"
                DownloadManager.STATUS_PAUSED -> "paused"
                DownloadManager.STATUS_SUCCESSFUL -> "successful"
                DownloadManager.STATUS_FAILED -> "failed"
                else -> "unknown"
            }

            return mapOf(
                "status" to state,
                "bytes" to bytes,
                "total" to total,
                "reason" to reason,
            )
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
        sharedText?.let { text ->
            methodChannel?.invokeMethod(METHOD_ON_SHARE_RECEIVED, text)
            sharedText = null
        }
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) return
        val action = intent.action
        val type = intent.type

        if (Intent.ACTION_SEND == action && type != null && "text/plain" == type) {
            val text = intent.getStringExtra(Intent.EXTRA_TEXT)
            if (!text.isNullOrBlank()) {
                sharedText = text
            }
        }
    }
}
