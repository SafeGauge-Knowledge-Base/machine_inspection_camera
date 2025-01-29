import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:android_path_provider/android_path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jni/jni.dart';
import 'package:machine_inspection_camera/Previewplayer.dart';
import 'package:machine_inspection_camera/live.dart';
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
  final int httpPort = 8082; // HTTP port for VLC

  List<HttpResponse> _clients = [];
  bool isStreaming = false;

  String ssid = 'X4 1G3PYC.OSC';
  String password = '88888888';

  @override
  void initState() {
    super.initState();

    initializeCameraSdk();
    //starthttp();

    // Mock data for testing
  }

  @override
  void dispose() {
    isStreaming = false;

    InstaCameraManager.getInstance().closePreviewStream();
    super.dispose();
  }

  List<int>? spsHeader;
  List<int>? ppsHeader;
  int findNextStartCode(List<int> data, int start) {
    final List<int> startCode = [0x00, 0x00, 0x00, 0x01];

    for (int i = start; i < data.length - 4; i++) {
      if (data.sublist(i, i + 4).every(
          (byte) => byte == startCode[data.sublist(i, i + 4).indexOf(byte)])) {
        return i;
      }
    }
    return data.length; // Return end of data if no start code found
  }

  void extractSpsPps(List<int> h264Data) {
    final List<int> startCode = [0x00, 0x00, 0x00, 0x01]; // H.264 Start Code
    int index = 0;

    while (index < h264Data.length - 4) {
      // Check if current position is a start code
      if (h264Data.sublist(index, index + 4).every((byte) =>
          byte ==
          startCode[h264Data.sublist(index, index + 4).indexOf(byte)])) {
        int nalType = h264Data[index + 4] & 0x1F; // Extract NAL unit type

        if (nalType == 7) {
          // SPS
          print("📌 SPS Found at index $index");
          int spsEnd = findNextStartCode(h264Data, index + 4);
          spsHeader = h264Data.sublist(index, spsEnd);
        } else if (nalType == 8) {
          // PPS
          print("📌 PPS Found at index $index");
          int ppsEnd = findNextStartCode(h264Data, index + 4);
          ppsHeader = h264Data.sublist(index, ppsEnd);
        }
      }
      index++;
    }

    if (spsHeader != null && ppsHeader != null) {
      print("✅ Extracted SPS: $spsHeader");
      print("✅ Extracted PPS: $ppsHeader");
    } else {
      print("❌ SPS or PPS not found!");
    }
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
        onOpened: () async {
          print("Preview has started.");

          final cameraManager = InstaCameraManager.getInstance();
          cameraManager.setStreamEncode();
          final pipeline = capturePlayerView.getPipeline();

          cameraManager.setPipeline(pipeline);

          // capturePlayerView.setPlayerViewListener(
          //     PlayerViewListener.implement($PlayerViewListener(
          //   onReleaseCameraPipeline: () {},
          //   onFail: (i, string) {},
          //   onLoadingStatusChanged: (z) {},
          //   onLoadingFinish: () {
          //     print("loading");
          //     final pipeline = capturePlayerView.getPipeline();

          //     cameraManager.setPipeline(pipeline);
          //   },
          // )));

          // capturePlayerView.prepare(createParams());
          // capturePlayerView.play();
        },
        onIdle: () {
          print("Preview is idle...");
        },
        onError: () {
          print("An error occurred...");
        },
        onVideoData: (videoData) {
          // Convert JArray<jbyte> to List<int>
          List<int> frameData = List<int>.generate(
              videoData.data.length, (i) => videoData.data[i] & 0xFF);

          // Extract SPS/PPS only once (on first frame)
          if (spsHeader == null || ppsHeader == null) {
            extractSpsPps(frameData);
          }

          // Save frame data to file
          _saveH264ToFile(frameData);
        },
        onGyroData: (gyroDataList) {
          //   print("Gyro data received: $gyroDataList");
        },
        onExposureData: (exposureData) {
          //  print("Exposure data received: $exposureData");
        },
      ),
    );
  }

  // HTTP clients connected to the server
  /// Stops the HTTP server and disconnects all VLC clients.
  Future<void> stop() async {
    for (final client in _clients) {
      await client.close();
    }
    _clients.clear();
    print('Streamer stopped');
  }

  Future<void> starthttp() async {
    try {
      final httpServer =
          await HttpServer.bind(InternetAddress.loopbackIPv4, httpPort);
      print('HTTP server started on http://127.0.0.1:$httpPort');
      httpServer.listen((HttpRequest request) {
        print('Incoming request: ${request.uri.path}');
        if (request.uri.path == '/stream') {
          print('New VLC client connected');
          _handleHttpConnection(request);
        } else {
          request.response
            ..statusCode = HttpStatus.notFound
            ..write('Not Found')
            ..close();
        }
      });
    } catch (e) {
      print('Failed to start HTTP server: $e');
    }
  }

  void _handleHttpConnection(HttpRequest request) {
    final response = request.response;
    response.bufferOutput = false;

    response.headers.contentType =
        ContentType("video", "h264"); // Correct MIME type for raw H.264
    response.headers.set('Transfer-Encoding', 'chunked');
    response.headers.set('Cache-Control',
        'no-store, no-cache, must-revalidate, proxy-revalidate');
    response.headers.set('Connection', 'keep-alive');
    response.headers.set('Pragma', 'no-cache');
    response.headers.set('Expires', '0');

    _clients.add(response);

    response.done.whenComplete(() {
      print('VLC client disconnected');
      _clients.remove(response);
    });
  }

  void _saveH264ToFile(List<int> frameData) async {
    final directory = await AndroidPathProvider.downloadsPath;
    final String filePath = '$directory/video_stream.h264';
    final File file = File(filePath);

    bool isIframe = frameData.length > 4 &&
        ((frameData[4] & 0x1F) == 5); // Check for I-frame

    List<int> finalFrame = frameData;

    if (isIframe && spsHeader != null && ppsHeader != null) {
      print("📌 I-frame detected! Prepending SPS/PPS...");
      finalFrame = [...spsHeader!, ...ppsHeader!, ...frameData];
    }

    try {
      // Append frame data without overwriting
      await file.writeAsBytes(finalFrame, mode: FileMode.append, flush: true);
      print("✅ Video frame written: ${finalFrame.length} bytes");
    } catch (e) {
      print("❌ Error writing to file: $e");
    }
  }

  // void _broadcastToClients(Uint8List data) {
  //   final Uint8List nalUnitStart = Uint8List.fromList([0, 0, 0, 1]);
  //   bool isIframe = (data.length > 4) && ((data[4] & 0x1F) == 5);

  //   for (final client in _clients) {
  //     print("Detected I-frame, adding SPS/PPS headers...");

  //     if (spsHeader != null && ppsHeader != null) {
  //       Uint8List fullFrame = Uint8List.fromList([
  //         ...nalUnitStart, // NAL start sequence
  //         ...spsHeader!, // SPS header
  //         ...nalUnitStart, // NAL start sequence
  //         ...ppsHeader!, // PPS header
  //         ...data // Actual frame data
  //       ]);

  //       client.add(fullFrame);
  //       _saveH264ToFile(fullFrame); // Save fixed video for debugging
  //     }
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

            // isStreaming
            //     ? const SizedBox(
            //         height: 400,
            //         child: PreviewPlayer(),
            //       )
            //     : const SizedBox(),

            // Start recording button
            ElevatedButton(
              onPressed: () {
                InstaCameraManager.getInstance()
                    .setPreviewStatusChangedListener(listener);
                InstaCameraManager.getInstance().startPreviewStream();

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
              onPressed: () {
                List<PreviewStreamResolution> supportedList =
                    InstaCameraManager.getInstance()
                        .getSupportedPreviewStreamResolution(0);
                print(supportedList);

                //   PreviewStreamResolution.STREAM_1440_720_30FPS

                List<PreviewStreamResolution> supportedList2 =
                    InstaCameraManager.getInstance()
                        .getSupportedPreviewStreamResolution(
                            InstaCameraManager.PREVIEW_TYPE_LIVE);

                print(supportedList2);
              },
              child: const Text('get'),
            ),
          ],
        ),
      ),
    );
  }
}

Uint8List convertJArrayToUint8List(JArray<jbyte> javaArray) {
  final int length = javaArray.length;
  final Uint8List result = Uint8List(length);

  // Convert each signed byte to unsigned (jbyte in Java is signed, Uint8List is unsigned)
  for (int i = 0; i < length; i++) {
    result[i] = (javaArray[i] & 0xFF); // Ensures values are within 0-255 range
  }

  return result;
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
