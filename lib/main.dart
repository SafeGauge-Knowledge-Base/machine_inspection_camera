import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
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
            ElevatedButton(
              onPressed: _startBleScan,
              child: const Text('Start BLE Scan'),
            ),
            ElevatedButton(
              onPressed: _stopBleScan,
              child: const Text('Stop BLE Scan'),
            ),
            ElevatedButton(
              onPressed: _getBatteryLevel,
              child: const Text('Get Battery Level'),
            ),
            Text(_batteryLevel),
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
