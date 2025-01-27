import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:machine_inspection_camera/live.dart';
import 'package:machine_inspection_camera/stream.dart';
import 'package:udp/udp.dart';
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

  String ssid = 'GP24551423';
  String password = 'MXH-C#X-5v4';

  @override
  void initState() {
    super.initState();

    // initializeCameraSdk();
  }

  @override
  void dispose() {
    isStreaming = false;

    super.dispose();
  }

  void initializeCameraSdk() {
    // final capturePlayerView = InstaCapturePlayerView(activity);

    // listener = IPreviewStatusListener.implement(
    //   $IPreviewStatusListener(
    //     onOpening: () {
    //       print("Preview is opening...");
    //     },
    //     onOpened: () {
    //       print("Preview has started.");
    //       final cameraManager = InstaCameraManager.getInstance();
    //       cameraManager.setStreamEncode();

    //       capturePlayerView.setPlayerViewListener(
    //           PlayerViewListener.implement($PlayerViewListener(
    //         onReleaseCameraPipeline: () {},
    //         onFail: (i, string) {},
    //         onLoadingStatusChanged: (z) {},
    //         onLoadingFinish: () {
    //           print("loading");
    //           final pipeline = capturePlayerView.getPipeline();

    //           cameraManager.setPipeline(pipeline);
    //         },
    //       )));

    //       // capturePlayerView.prepare(createParams());
    //       // capturePlayerView.play();
    //     },
    //     onIdle: () {
    //       print("Preview is idle...");
    //     },
    //     onError: () {
    //       print("An error occurred...");
    //     },
    //     onVideoData: (videoData) async {},
    //     onGyroData: (gyroDataList) {
    //       //   print("Gyro data received: $gyroDataList");
    //     },
    //     onExposureData: (exposureData) {
    //       //  print("Exposure data received: $exposureData");
    //     },
    //   ),
    // );
  }

  final Dio _dio = Dio();
  connect() {}

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

            // Start recording button
            ElevatedButton(
              onPressed: () {
                // InstaCameraManager.getInstance()
                //     .setPreviewStatusChangedListener(listener);
                // InstaCameraManager.getInstance().startPreviewStream();

                setState(() {
                  isStreaming = true;
                });
              },
              child: const Text('Start Preview'),
            ),
            // Stop recording button
            ElevatedButton(
              onPressed: () {
                setState(() {
                  isStreaming = false;
                });
              },
              child: const Text('Stop Preview'),
            ),

            ElevatedButton(
              onPressed: () async {
                // List<PreviewStreamResolution> supportedList =
                //     InstaCameraManager.getInstance()
                //         .getSupportedPreviewStreamResolution(0);
                // print(supportedList);

                //  PreviewStreamResolution.STREAM_1440_720_30FPS

                // List<PreviewStreamResolution> supportedList2 =
                //     InstaCameraManager.getInstance()
                //         .getSupportedPreviewStreamResolution(
                //             InstaCameraManager.PREVIEW_TYPE_NORMAL);

                //   print(supportedList2);
                // startGoProStream();
                startStreamAndListen();
              },
              child: const Text('start stream'),
            ),

            ElevatedButton(
              onPressed: () async {
                stopGoProStream();
              },
              child: const Text('stop stream'),
            ),

            ElevatedButton(
              onPressed: () async {
                sendKeepAliveRequest();
              },
              child: const Text('keep alive'),
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
                child: Text('Live Stream Page'))
          ],
        ),
      ),
    );
  }
}

Future<void> sendKeepAliveRequest() async {
  try {
    // Initialize Dio
    final Dio dio = Dio();

    // Define the URL
    const String url = 'http://10.5.5.9:8080/gopro/camera/keep_alive';

    // Perform the GET request
    final response = await dio.get(url);

    // Handle the response
    print('Keep-Alive Response: ${response.data}');
  } catch (e) {
    // Handle errors
    print('Error while sending keep-alive request: $e');

    if (e is DioError) {
      print('DioError Type: ${e.type}');
      print('DioError Message: ${e.message}');
      if (e.response != null) {
        print('DioError Response Data: ${e.response?.data}');
      }
    }
  }
}

Future<void> startGoProStream() async {
  try {
    final Dio dio = Dio();

    // Define the URL and query parameters
    const String url = 'http://10.5.5.9:8080/gopro/camera/stream/start';
    final Map<String, String> queryParameters = {'port': '8556'};

    // Send the GET request
    final response = await dio.get(url, queryParameters: queryParameters);

    if (response.statusCode == 200) {
      print('Stream started successfully: ${response.data}');
    } else {
      print('Failed to start stream: ${response.statusCode}');
    }
  } catch (e) {
    print('Error while starting GoPro stream: $e');
  }
}

void startListeningToUDP() async {
  try {
    // Bind the UDP listener to port 8554
    final udpReceiver = await UDP.bind(
        Endpoint.unicast(InternetAddress.anyIPv4, port: const Port(8556)));
    print('Listening for UDP packets on port 8554...');

    // Listen for incoming datagrams
    udpReceiver.asStream().listen((datagram) {
      print('Received UDP packet from: ${datagram}');
      if (datagram != null) {
        // Access the incoming data
        Uint8List data = datagram.data;
        print('Received UDP packet of size: ${data.length}');
        print(
            'Data (Hex): ${data.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(' ')}');

        // TODO: Pass the data to an MPEG TS decoder
      }
    });
  } catch (e) {
    print('Error listening to UDP packets: $e');
  }
}

void startStreamAndListen() async {
  // Start the stream
  await startGoProStream();

  // Start listening to the UDP stream
  //startListeningToUDP();
}

Future<void> stopGoProStream() async {
  try {
    final Dio dio = Dio();

    // Define the URL and query parameters
    const String url = 'http://10.5.5.9:8080/gopro/camera/stream/stop';

    // Send the GET request
    final response = await dio.get(url);

    if (response.statusCode == 200) {
      print('Stream stopped successfully: ${response.data}');
    } else {
      print('Failed to stop stream: ${response.statusCode}');
    }
  } catch (e) {
    print('Error while stopping GoPro stream: $e');
  }
}
