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
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
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
  int _counter = 0;
  String _bleStatus = 'BLE Status: Idle';
  String _batteryLevel = 'Unknown battery level.';

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  Future<void> _getBatteryLevel() async {
    String batteryLevel;
    try {
      final int? result = await platform.invokeMethod('getBatteryLevel');
      batteryLevel = 'Battery level at $result%.';
    } on PlatformException catch (e) {
      batteryLevel = "Failed to get battery level: '${e.message}'.";
    }

    setState(() {
      _batteryLevel = batteryLevel;
    });
  }

  Future<void> _startBleScan() async {
    try {
      await platform.invokeMethod('startBleScan');
      setState(() {
        _bleStatus = 'Scanning for devices...';
      });
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

  Future<void> _connectToDevice(String deviceName) async {
    try {
      await platform.invokeMethod('connectBle', {'deviceName': deviceName});
      setState(() {
        _bleStatus = 'Connecting to $deviceName...';
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
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            ElevatedButton(
              onPressed: _getBatteryLevel,
              child: const Text('Get Battery Level'),
            ),
            Text(_batteryLevel),
            ElevatedButton(
              onPressed: _startBleScan,
              child: const Text('Start BLE Scan'),
            ),
            ElevatedButton(
              onPressed: _stopBleScan,
              child: const Text('Stop BLE Scan'),
            ),
            ElevatedButton(
              onPressed: () => _connectToDevice("YourDeviceName"),
              child: const Text('Connect to Device'),
            ),
            ElevatedButton(
              onPressed: _disconnectDevice,
              child: const Text('Disconnect Device'),
            ),
            Text(_bleStatus),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
