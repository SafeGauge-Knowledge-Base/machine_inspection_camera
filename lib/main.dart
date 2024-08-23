import 'package:flutter/material.dart';
import 'package:machine_inspection_camera/flow.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Flow SDK Integration'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                onPressed: () {
                  FlowSdkChannel.initializeFlowSdk();
                },
                child: Text('Initialize Flow SDK'),
              ),
              ElevatedButton(
                onPressed: () {
                  FlowSdkChannel.startBleScan(30000);
                },
                child: const Text('Start BLE Scan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
