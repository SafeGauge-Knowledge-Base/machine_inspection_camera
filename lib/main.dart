import 'dart:async';
import 'package:flutter/material.dart';
import 'package:jni/jni.dart';
import 'package:machine_inspection_camera/Previewplayer.dart';
import 'package:machine_inspection_camera/sdkcamera_bindings.dart';
import 'package:machine_inspection_camera/sdkmedia_bindings.dart';

import 'package:dio/dio.dart';
import 'package:wifi_iot/wifi_iot.dart';

void main() {
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
  late IPreviewStatusListener listener;

  bool isStreaming = false;

  String ssid = 'X4 1G3PYC.OSC';
  String password = '88888888';

  @override
  void initState() {
    super.initState();

    initializeCameraSdk();
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
    InstaMediaSDK.init(activity);
    final capturePlayerView = InstaCapturePlayerView(activity);

    listener = IPreviewStatusListener.implement(
      $IPreviewStatusListener(
        onOpening: () {
          print("Preview is opening...");
        },
        onOpened: () {
          print("Preview has started.");
          final cameraManager = InstaCameraManager.getInstance();
          cameraManager.setStreamEncode();

          capturePlayerView.setPlayerViewListener(
              PlayerViewListener.implement($PlayerViewListener(
            onReleaseCameraPipeline: () {},
            onFail: (i, string) {},
            onLoadingStatusChanged: (z) {},
            onLoadingFinish: () {
              print("loading");
              final pipeline = capturePlayerView.getPipeline();

              cameraManager.setPipeline(pipeline);
            },
          )));

          // capturePlayerView.prepare(createParams());
          // capturePlayerView.play();
        },
        onIdle: () {
          print("Preview is idle...");
        },
        onError: () {
          print("An error occurred...");
        },
        onVideoData: (videoData) async {},
        onGyroData: (gyroDataList) {
          //   print("Gyro data received: $gyroDataList");
        },
        onExposureData: (exposureData) {
          //  print("Exposure data received: $exposureData");
        },
      ),
    );
  }

  final Dio _dio = Dio();
  connect() {
    InstaCameraManager.getInstance()
        .openCamera(InstaCameraManager.CONNECT_TYPE_WIFI);
  }

  void setCameraOptions() async {
    const String baseUrl = 'http://192.168.42.1'; // Camera's IP address
    const String endpoint =
        '/osc/commands/execute'; // Endpoint for executing commands

    // Request headers
    final headers = {
      'Content-Type': 'application/json;charset=utf-8',
      'Accept': 'application/json',
      'X-XSRF-Protected': '1',
    };

    // Request payload
    final Map<String, dynamic> payload = {
      "name": "camera.takePicture",
      // "parameters": {
      //   "options": {
      //     "captureMode": "image",
      //     "hdr": "hdr",
      //     "photoStitching":
      //         "ondevice" //add this option only when on-device stitching is supported
      //   }
      // }
    };

    // Initialize Dio with optional timeout settings
    final Dio dio = Dio(
      BaseOptions(
          connectTimeout: Duration(seconds: 5), // 5 seconds
          receiveTimeout: Duration(seconds: 5)),
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
        print('Camera options set successfully: ${response.data}');
      } else {
        print(
            'Failed to set camera options. Status Code: ${response.statusCode}');
      }
    } on DioError catch (e) {
      // Handle errors
      if (e.type == DioErrorType.connectionTimeout) {
        print('Connection timeout. Unable to reach the camera.');
      } else if (e.type == DioErrorType.receiveTimeout) {
        print('Response timeout. Camera took too long to respond.');
      } else if (e.response != null) {
        print('Error: ${e.response?.data}');
      } else {
        print('Unknown error: ${e.message}');
      }
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
            // Start preview button

            // SDK connect button
            ElevatedButton(
              onPressed: () async {
                connect();
              },
              child: const Text('SDK Connect'),
            ),
            // Test Wi-Fi details
            ElevatedButton(
              onPressed: () async {
                WiFiForIoTPlugin.getSSID().then((value) {
                  print('SSID: $value');
                });
                WiFiForIoTPlugin.forceWifiUsage(true).then((value) {
                  print('Force Wi-Fi usage: $value');
                });
                WiFiForIoTPlugin.getIP().then((value) {
                  print('IP: $value');
                });
              },
              child: const Text('Test Wi-Fi Info'),
            ),
            // Take a photo button
            ElevatedButton(
              onPressed: setCameraOptions,
              child: const Text('Take Photo'),
            ),
            // PlatformView for InstaCapturePlayerView
            const SizedBox(
              height: 400,
              child: PreviewPlayer(),
            ),
            // Start recording button
            ElevatedButton(
              onPressed: () {
                InstaCameraManager.getInstance()
                    .setPreviewStatusChangedListener(listener);
                InstaCameraManager.getInstance().startPreviewStream();
              },
              child: const Text('Start Preview'),
            ),
            // Stop recording button
            ElevatedButton(
              onPressed: () {
                InstaCameraManager.getInstance().closePreviewStream();
              },
              child: const Text('Stop Preview'),
            ),
          ],
        ),
      ),
    );
  }
}

CaptureParamsBuilder createParams() {
  CaptureParamsBuilder builder = new CaptureParamsBuilder()
      .setCameraType(InstaCameraManager.getInstance().getCameraType())
      .setMediaOffset(InstaCameraManager.getInstance().getMediaOffset())
      .setMediaOffsetV2(InstaCameraManager.getInstance().getMediaOffsetV2())
      .setMediaOffsetV3(InstaCameraManager.getInstance().getMediaOffsetV3())
      .setCameraSelfie(InstaCameraManager.getInstance().isCameraSelfie())
      .setGyroTimeStamp(InstaCameraManager.getInstance().getGyroTimeStamp())
      .setBatteryType(InstaCameraManager.getInstance().getBatteryType());
  return builder;
}
