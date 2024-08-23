import 'package:flutter/services.dart';

class FlowSdkChannel {
  static const MethodChannel _channel = MethodChannel('flow_sdk');

  static Future<void> initializeFlowSdk() async {
    try {
      await _channel.invokeMethod('initializeFlowSdk');
    } on PlatformException catch (e) {
      print("Failed to initialize Flow SDK: '${e.message}'.");
    }
  }

  static Future<void> startBleScan(int duration) async {
    try {
      await _channel.invokeMethod('startBleScan', {'duration': duration});
    } on PlatformException catch (e) {
      print("Failed to start BLE scan: '${e.message}'.");
    }
  }

  // Other SDK functions can be added here similarly
}
