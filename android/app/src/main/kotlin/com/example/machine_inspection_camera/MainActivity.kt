package com.example.machine_inspection_camera

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.BatteryManager
import android.os.Build.VERSION
import android.os.Build.VERSION_CODES
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.arashivision.sdkcamera.camera.InstaCameraManager
import com.arashivision.sdkcamera.camera.callback.IScanBleListener
import com.arashivision.sdk.demo.util.CameraBindNetworkManager
import com.clj.fastble.data.BleDevice

class MainActivity : FlutterActivity() {
    private val CHANNEL = "samples.flutter.dev/ble"
    private val REQUEST_PERMISSION_CODE = 100
    private val scannedDevices = mutableListOf<BleDevice>()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getBatteryLevel" -> {
                    val batteryLevel = getBatteryLevel()
                    if (batteryLevel != -1) {
                        result.success(batteryLevel)
                    } else {
                        result.error("UNAVAILABLE", "Battery level not available.", null)
                    }
                }
                "startBleScan" -> {
                    if (checkPermissions()) {
                        startBleScan()
                        result.success("Scanning started")
                    } else {
                        requestPermissions()
                        result.error("PERMISSION_DENIED", "Required permissions not granted", null)
                    }
                }
                "stopBleScan" -> {
                    stopBleScan()
                    result.success("Scanning stopped")
                }
                "connectBle" -> {
                    val deviceId = call.argument<String>("deviceId")
                    connectBle(deviceId)
                    result.success("Connecting to device with ID: $deviceId")
                }
                "disconnectBle" -> {
                    disconnectBle()
                    result.success("Disconnected")
                }
                "connectByWiFi" -> {
                    connectByWiFi(result)
                }
                "getScannedDevices" -> {
                    val devices = scannedDevices.map { "${it.name} (${it.mac})" }
                    result.success(devices)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun getBatteryLevel(): Int {
        return if (VERSION.SDK_INT >= VERSION_CODES.LOLLIPOP) {
            val batteryManager = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
            batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
        } else {
            val intent = registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
            intent?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
        }
    }

    private fun checkPermissions(): Boolean {
        val permissions = arrayOf(
            Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.ACCESS_COARSE_LOCATION,
            Manifest.permission.BLUETOOTH_SCAN,
            Manifest.permission.BLUETOOTH_CONNECT
        )
        return permissions.all {
            ContextCompat.checkSelfPermission(this, it) == PackageManager.PERMISSION_GRANTED
        }
    }

    private fun requestPermissions() {
        val permissions = arrayOf(
            Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.ACCESS_COARSE_LOCATION,
            Manifest.permission.BLUETOOTH_SCAN,
            Manifest.permission.BLUETOOTH_CONNECT
        )
        ActivityCompat.requestPermissions(this, permissions, REQUEST_PERMISSION_CODE)
    }

    private fun startBleScan() {
        scannedDevices.clear()
        InstaCameraManager.getInstance().setScanBleListener(object : IScanBleListener {
            override fun onScanStartSuccess() {
                // Handle scan start success
            }

            override fun onScanStartFail() {
                // Handle scan start failure
            }

            override fun onScanning(bleDevice: BleDevice) {
                scannedDevices.add(bleDevice)
            }

            override fun onScanFinish(bleDeviceList: List<BleDevice>) {
                // Handle scan finish
            }
        })
        InstaCameraManager.getInstance().startBleScan(30_000) // Scan for 30 seconds
    }

    private fun stopBleScan() {
        InstaCameraManager.getInstance().stopBleScan()
    }

    private fun connectBle(deviceId: String?) {
        val bleDevice = scannedDevices.find { it.mac == deviceId }
        if (bleDevice != null) {
            InstaCameraManager.getInstance().connectBle(bleDevice)
        } else {
            println("Device with ID $deviceId not found")
        }
    }

    private fun disconnectBle() {
        InstaCameraManager.getInstance().disconnectBle()
    }

private fun connectByWiFi(result: MethodChannel.Result) {
    CameraBindNetworkManager.getInstance(this).bindNetwork(object : CameraBindNetworkManager.IBindNetWorkCallback {
        override fun onResult(errorCode: CameraBindNetworkManager.ErrorCode) {
            if (errorCode == CameraBindNetworkManager.ErrorCode.OK) {
                InstaCameraManager.getInstance().openCamera(InstaCameraManager.CONNECT_TYPE_WIFI)
                result.success("Connected via Wi-Fi")
            } else {
                result.error("WIFI_ERROR", "Failed to connect via Wi-Fi. Error code: $errorCode", null)
            }
        }
    })
}


}
