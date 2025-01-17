import 'package:flutter/services.dart';

class WiFiConnector {
  static const _platform = MethodChannel('wifi_connector');

  static Future<bool> connectToWiFi(String ssid, String password) async {
    try {
      final result = await _platform.invokeMethod('connectToWiFi', {
        'ssid': ssid,
        'password': password,
      });
      return result;
    } on PlatformException catch (e) {
      print("Failed to connect to Wi-Fi: '${e.message}'.");
      return false;
    }
  }
}
