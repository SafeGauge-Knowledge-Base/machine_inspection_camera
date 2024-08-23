package com.example.machine_inspection_camera

import android.os.Bundle
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import com.arashivision.sdkcamera.InstaCameraSDK
import com.arashivision.sdkcamera.FlowCameraManager

class MainActivity : FlutterActivity() {

    private val CHANNEL = "flow_sdk"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        InstaCameraSDK.initFlow(this)
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "initializeFlowSdk" -> {
                    InstaCameraSDK.initFlow(applicationContext)
                    result.success(null)
                }
                "startBleScan" -> {
                    val duration: Int? = call.argument("duration")
                    duration?.let {
                        FlowCameraManager.getInstance().startBleScan(it)
                        result.success(null)
                    } ?: run {
                        result.error("INVALID_ARGUMENT", "Duration is required", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
