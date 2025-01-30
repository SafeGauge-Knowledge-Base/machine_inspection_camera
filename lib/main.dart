import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jni/jni.dart';
import 'package:machine_inspection_camera/live.dart';
import 'package:machine_inspection_camera/sdkcamera_bindings.dart';
import 'package:dio/dio.dart';
import 'package:wifi_iot/wifi_iot.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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

  String ssid = 'X4 1G3PYC.OSC';
  String password = '88888888';

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

  // void _saveH264ToFile(List<int> frameData) async {
  //   const String filePath = '/storage/emulated/0/Download/video_stream.h264';
  //   final File file = File(filePath);

  //   // Ensure the file exists
  //   if (!await file.exists()) {
  //     await file.create();
  //   }

  //   // Identify if it's an I-frame
  //   bool isIframe = frameData.length > 5 &&
  //       ((frameData[4] & 0x1F) == 5 || // Standard I-frame
  //           (frameData[4] & 0x1F) == 19 || // High Profile I-frame
  //           (frameData[4] & 0x1F) == 20); // Extended I-frame

  //   // Ensure SPS/PPS are added before I-frames
  //   List<int> finalFrame = frameData;
  //   if (isIframe && spsHeader != null && ppsHeader != null) {
  //     print("📌 I-frame detected! Prepending SPS/PPS...");
  //     finalFrame = [
  //       ...[0, 0, 0, 1], ...spsHeader!, // SPS header
  //       ...[0, 0, 0, 1], ...ppsHeader!, // PPS header
  //       ...[0, 0, 0, 1], ...frameData // Actual I-frame
  //     ];
  //   }

  //   try {
  //     // Append data without overwriting
  //     await file.writeAsBytes(finalFrame, mode: FileMode.append, flush: true);
  //     print("✅ Video frame written: ${finalFrame.length} bytes");
  //   } catch (e) {
  //     print("❌ Error writing to file: $e");
  //   }
  // }

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
      "name": "camera.getOptions",
      "parameters": {
        "optionNames": ["photoStitching"]
      }
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

            // isStreaming
            //     ? const SizedBox(
            //         height: 400,
            //         child: PreviewPlayer(),
            //       )
            //     : const SizedBox(),

            // Start recording button
            ElevatedButton(
              onPressed: () {
                setState(() {
                  isStreaming = true;
                });
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
            ElevatedButton(
                onPressed: () async {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LiveStreamPage(),
                    ),
                  );
                },
                child: Text('Live Stream Page')),
            ElevatedButton(
              onPressed: () async {
                // List<PreviewStreamResolution> supportedList =
                //     InstaCameraManager.getInstance()
                //         .getSupportedPreviewStreamResolution(0);
                // print(supportedList);

                // //   PreviewStreamResolution.STREAM_1440_720_30FPS

                // List<PreviewStreamResolution> supportedList2 =
                //     InstaCameraManager.getInstance()
                //         .getSupportedPreviewStreamResolution(
                //             InstaCameraManager.PREVIEW_TYPE_LIVE);

                // print(supportedList2);
                setCameraOptions();
              },
              child: const Text('get'),
            ),
          ],
        ),
      ),
    );
  }
}
