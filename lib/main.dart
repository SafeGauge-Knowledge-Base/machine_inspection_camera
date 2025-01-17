import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jni/jni.dart';
import 'package:machine_inspection_camera/basecamera_bindings.dart';

import 'package:machine_inspection_camera/preview.dart';

import 'package:machine_inspection_camera/sdkcamera_bindings.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_iot/wifi_iot.dart';

void main() {
  // Ensure Flutter and native code are initialized
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

const platform = MethodChannel('samples.flutter.dev/ble');

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
  List<String> _devices = [];

  String _bleStatus = 'Idle';
  String _batteryLevel = 'Unknown';
  String ssid = 'X4 1G3PYC.OSC';
  String password = '88888888';

  @override
  initState() {
    super.initState();
    initializeCam();
  }

  initializeCam() {
    JObject activity = JObject.fromReference(Jni.getCachedApplicationContext());

    // Initialize the SDK
    InstaCameraSDK.init(
        // Initialize the SDK
        activity);
    InstaCameraManager.getInstance();
  }

  Future<void> _startBleScan() async {
    try {
      await platform.invokeMethod('startBleScan');
      setState(() {
        _bleStatus = 'Scanning for devices...';
      });
      _getScannedDevices();
    } on PlatformException catch (e) {
      setState(() {
        _bleStatus = "Failed to start scan: '${e.message}'.";
      });
    }
  }

  final Dio _dio = Dio();
  connect() {
    InstaCameraManager.getInstance()
        .openCamera(InstaCameraManager.CONNECT_TYPE_WIFI);
  }

  getData() {
    final manager = InstaCameraManager.getInstance();
    final type = manager.getCameraConnectedType();
    print('Camera Connected Type: $type');
    return manager;
  }

  getPreviewTypes() {
    List<PreviewStreamResolution> supportedList =
        InstaCameraManager.getInstance().getSupportedPreviewStreamResolution(
            InstaCameraManager.PREVIEW_TYPE_LIVE);
    print('Preview Types: $supportedList');
  }

  Future<void> getCameraInfo() async {
    // .startPreviewStream(

    // );
// InstaCameraManager.getInstance().startPreviewStream(resolution, 2);

    const String baseUrl = 'http://192.168.42.1'; // Camera's IP address
    const String endpoint = '/osc/info';

    // Headers required for the request
    final headers = {
      'Content-Type': 'application/json;charset=utf-8',
      'Accept': 'application/json',
      'X-XSRF-Protected': '1',
    };

    // Initialize Dio with optional timeout settings
    final Dio dio = Dio(
      BaseOptions(
          connectTimeout: Duration(seconds: 5), // 5 seconds
          receiveTimeout: Duration(seconds: 5)),
    );

    try {
      // Make the GET request
      final response = await dio.get(
        '$baseUrl$endpoint',
        options: Options(headers: headers),
      );

      // Check for successful response
      if (response.statusCode == 200) {
        print('Camera Info: ${response.data}');
      } else {
        print(
            'Failed to fetch camera info. Status Code: ${response.statusCode}');
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

  Future<void> _stopBleScan() async {
    try {
      await platform.invokeMethod('stopBleScan');
      setState(() {
        _bleStatus = 'Scan stopped.';
      });
    } on PlatformException catch (e) {
      setState(() {
        _bleStatus = "Failed to stop scan: '${e.message}'.";
      });
    }
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

  Future<void> _connectToWiFi() async {
    try {
      bool isConnected = await WiFiForIoTPlugin.connect(
        ssid,
        password: password,
        security: NetworkSecurity
            .WPA, // NetworkSecurity.NONE, NetworkSecurity.WEP, NetworkSecurity.WPA, NetworkSecurity.WPA2

        joinOnce: false,
        // withInternet:
        //     false, // Set to true if you expect internet access through this Wi-Fi
      );

      if (isConnected) {
        print("Successfully connected to Wi-Fi: $ssid");
      } else {
        print("Failed to connect to Wi-Fi: $ssid");
      }
    } catch (e) {
      print("Exception occurred while connecting to Wi-Fi: '${e.toString()}'.");
    }
    // bool isConnected = await WiFiConnector.connectToWiFi(ssid, password);

    // if (isConnected) {
    //   print("Successfully connected to Wi-Fi: $ssid");
    // } else {
    //   print("Failed to connect to Wi-Fi: $ssid");
    // }
  }

  Future<void> _connectByWiFi() async {
    try {
      final result = await platform.invokeMethod('connectByWiFi');
      print(result); // "Connected via Wi-Fi"
    } on PlatformException catch (e) {
      print("Failed to connect by Wi-Fi: '${e.message}'.");
    }
  }

  Future<void> _startPreview() async {
    try {
      final result = await platform.invokeMethod('startPreview');
      print(result); // "Preview started"
    } on PlatformException catch (e) {
      print("Failed to start preview: '${e.message}'.");
    }
  }

  Future<void> _getScannedDevices() async {
    try {
      final List<dynamic> devices =
          await platform.invokeMethod('getScannedDevices');
      setState(() {
        _devices = devices.cast<String>();
      });
    } on PlatformException catch (e) {
      setState(() {
        _bleStatus = "Failed to get devices: '${e.message}'.";
      });
    }
  }

  Future<void> _connectToDevice(String deviceId) async {
    try {
      await platform.invokeMethod('connectBle', {'deviceId': deviceId});
      setState(() {
        _bleStatus = 'Connecting to $deviceId...';
      });
    } on PlatformException catch (e) {
      setState(() {
        _bleStatus = "Failed to connect: '${e.message}'.";
      });
    }
  }

  Future<void> _disconnectDevice() async {
    try {
      await platform.invokeMethod('disconnectBle');
      setState(() {
        _bleStatus = 'Device disconnected.';
      });
    } on PlatformException catch (e) {
      setState(() {
        _bleStatus = "Failed to disconnect: '${e.message}'.";
      });
    }
  }

  Future<void> _getBatteryLevel() async {
    try {
      final int result = await platform.invokeMethod('getBatteryLevel');
      setState(() {
        _batteryLevel = 'Battery Level: $result%';
      });
    } on PlatformException catch (e) {
      setState(() {
        _batteryLevel = "Failed to get battery level: '${e.message}'.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // ElevatedButton(
            //   onPressed: _startBleScan,
            //   child: const Text('Start BLE Scan'),
            // ),
            // ElevatedButton(
            //   onPressed: _stopBleScan,
            //   child: const Text('Stop BLE Scan'),
            // ),

            ElevatedButton(
              onPressed: _getBatteryLevel,
              child: const Text('Get Battery Level'),
            ),
            Text(_batteryLevel),
            ElevatedButton(
              onPressed: _connectToWiFi,
              child: const Text('Connect via Wi-Fi'),
            ),
            ElevatedButton(
              onPressed: _startPreview,
              child: const Text('Start Preview'),
            ),
            ElevatedButton(
              onPressed: getCameraInfo,
              child: const Text('Get Camera info'),
            ),
            ElevatedButton(
              onPressed: () async {
                await Permission.location.request();
              },
              child: const Text('Request Location Permission'),
            ),
            ElevatedButton(
              onPressed: () async {
                connect();
              },
              child: const Text('SDK Connect'),
            ),
            ElevatedButton(
              onPressed: () async {
                //    WiFiForIoTPlugin.showWritePermissionSettings(true);
                // WiFiForIoTPlugin.isConnected().then((value) {
                //   print('Connected to Wi-Fi: $value');
                // });

                WiFiForIoTPlugin.getSSID().then((value) {
                  print('SSID: $value');
                });

                WiFiForIoTPlugin.forceWifiUsage(true).then(
                  (value) {
                    print('Force Wi-Fi usage: $value');
                  },
                );

                WiFiForIoTPlugin.getIP().then((value) {
                  print('IP: $value');
                });
              },
              child: const Text('test'),
            ),

            ElevatedButton(
              onPressed: setCameraOptions,
              child: const Text('take photo'),
            ),
            ElevatedButton(
              onPressed: getData,
              child: const Text('Check Camera'),
            ),
            ElevatedButton(
              onPressed: getPreviewTypes,
              child: const Text('get preview types'),
            ),

            ElevatedButton(
                onPressed: () {
                  // Set the listener for preview status changes

                  // Start the preview stream

                  // @override
                  // void onVideoData(VideoData videoData) {
                  //   // Handle video data
                  //   print(videoData);
                  // }
                  InstaCameraManager.getInstance().startNormalCapture(1);
                },
                child: Text('Start Preview Stream')),
            if (_devices.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _devices.length,
                  itemBuilder: (context, index) {
                    final device = _devices[index];
                    return ListTile(
                      title: Text(device),
                      onTap: () {
                        final parts = device.split(' ');
                        final deviceId =
                            parts.last.replaceAll('(', '').replaceAll(')', '');
                        _connectToDevice(deviceId);
                      },
                    );
                  },
                ),
              ),
            if (_devices.isEmpty) const Text('No devices found.'),
            Text(_bleStatus),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _disconnectDevice,
        tooltip: 'Disconnect',
        child: const Icon(Icons.bluetooth_disabled),
      ),
    );
  }
}
