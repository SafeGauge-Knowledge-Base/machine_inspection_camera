import 'dart:async';
import 'package:flutter/material.dart';
import 'package:jni/jni.dart';
import 'package:machine_inspection_camera/live.dart';
import 'package:machine_inspection_camera/sdkcamera_bindings.dart';
import 'package:dio/dio.dart';
import 'package:media_kit/media_kit.dart';
import 'package:wifi_iot/wifi_iot.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter binding
  MediaKit.ensureInitialized(); // 🔥 Fix: Initialize MediaKit before using it
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter BLE Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'BLE Device Scanner'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool isStreaming = false;

  String ssid = 'THETAYR20101998.OSC';
  String password = '20101998';

  @override
  void initState() {
    super.initState();
    initializeCameraSdk();

    // Mock data for testing
  }

  @override
  void dispose() {
    isStreaming = false;

    InstaCameraManager.getInstance().closePreviewStream();
    super.dispose();
  }

  void initializeCameraSdk() {
    final activity = JObject.fromReference(Jni.getCachedApplicationContext());

    InstaCameraSDK.init(activity);
  }

  connect() {
    InstaCameraManager.getInstance()
        .openCamera(InstaCameraManager.CONNECT_TYPE_WIFI);
  }

  void getCameraOptions() async {
    const String baseUrl = 'http://192.168.1.1'; // Camera's IP address
    const String endpoint = '/osc/commands/execute'; // API endpoint

    // Request headers
    final headers = {
      'Content-Type': 'application/json;charset=utf-8',
      'Accept': 'application/json',
      'X-XSRF-Protected': '1',
    };

    final Map<String, dynamic> payload = {
      "name": "camera.getOptions",
      "parameters": {
        "optionNames": ["previewFormat"]
      }
    };

    // Initialize Dio with proper timeout settings
    final Dio dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ),
    );

    try {
      // Make the POST request
      final response = await dio.post(
        '$baseUrl$endpoint',
        data: payload,
        options: Options(headers: headers),
      );

      // Handle the response
      if (response.statusCode == 200) {
        print('Camera options: ${response.data}');
      } else {
        print(
            'Failed to get camera options. Status Code: ${response.statusCode}');
      }
    } on DioException catch (e) {
      // Handle Dio errors
      if (e.type == DioExceptionType.connectionTimeout) {
        print('Connection timeout. Unable to reach the camera.');
      } else if (e.type == DioExceptionType.receiveTimeout) {
        print('Response timeout. Camera took too long to respond.');
      } else if (e.response != null) {
        print('Error response: ${e.response?.data}');
      } else {
        print('Unknown error: ${e.message}');
      }
    }
  }

  Future<void> setResolution(int width, int height, int framerate) async {
    const String baseUrl = 'http://192.168.1.1';
    const String endpoint = '/osc/commands/execute';

    final headers = {
      'Content-Type': 'application/json;charset=utf-8',
      'Accept': 'application/json',
      'X-XSRF-Protected': '1',
    };

    final Map<String, dynamic> payload = {
      "name": "camera.setOptions",
      "parameters": {
        "options": {
          "iso": 0,
          "_wlanFrequency": 5.0,
          "sleepDelay": 1000,
          "captureMode": "image",
          "previewFormat": {"framerate": 30, "height": 1920, "width": 3840},
          "offDelay": 1500
        }
      }
    };

    Dio dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ),
    );

    try {
      final response = await dio.post(
        '$baseUrl$endpoint',
        data: payload,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        print('Resolution set successfully: ${response.data}');
      } else {
        print('Failed to set resolution. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error setting resolution: $e');
    }
  }

  Future<void> connectToWiFi() async {
    try {
      final isConnected = await WiFiForIoTPlugin.connect(
        ssid,
        password: password,
        security: NetworkSecurity.WPA,
        joinOnce: false,
      );

      print(isConnected
          ? "Successfully connected to Wi-Fi: $ssid"
          : "Failed to connect to Wi-Fi: $ssid");

      WiFiForIoTPlugin.getSSID().then((value) {
        print('SSID: $value');
      });
      WiFiForIoTPlugin.forceWifiUsage(true).then((value) {
        print('Force Wi-Fi usage: $value');
      });
      WiFiForIoTPlugin.getIP().then((value) {
        print('IP: $value');
      });
    } catch (e) {
      print("Exception occurred while connecting to Wi-Fi: '${e.toString()}'.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            // Wi-Fi connection button
            ElevatedButton(
              onPressed: () => connectToWiFi(),
              child: const Text('Connect via Wi-Fi'),
            ),

            ElevatedButton(
              onPressed: () {
                getCameraOptions();
              },
              child: const Text('GET preview format'),
            ),

            ElevatedButton(
              onPressed: () async {
                setResolution(3840, 1920, 30);
              },
              child: const Text('Set preview format'),
            ),
            ElevatedButton(
                onPressed: () async {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>  ThetaLivePreview(),
                    ),
                  );
                },
                child: Text('Live Stream Page')),
          ],
        ),
      ),
    );
  }
}
