package com.mored.attendanceApp
//
//import io.flutter.embedding.android.FlutterActivity

//class MainActivity : FlutterActivity()

//
//
//class MainActivity: FlutterActivity()
//import io.flutter.embedding.android.FlutterActivity




//package com.example.attendance

import android.media.MediaScannerConnection
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "scanFile") {
                    val path = call.argument<String>("path")
                    val mimeType = call.argument<String>("mimeType")

                    if (path != null && mimeType != null) {
                        MediaScannerConnection.scanFile(
                            applicationContext,
                            arrayOf(path),
                            arrayOf(mimeType),
                            null
                        )
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENTS", "Missing path or mimeType", null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }
}