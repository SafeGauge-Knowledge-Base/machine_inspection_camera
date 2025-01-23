import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class PreviewPlayer extends StatefulWidget {
  const PreviewPlayer({Key? key}) : super(key: key);

  @override
  State<PreviewPlayer> createState() => _PreviewPlayerState();
}

class _PreviewPlayerState extends State<PreviewPlayer> {
  late final AndroidViewController _controller;

  @override
  void initState() {
    super.initState();
    // Initialize the controller
    _controller = PlatformViewsService.initSurfaceAndroidView(
      id: 0,
      viewType:
          'com.arashivision.sdkmedia.player.capture.InstaCapturePlayerView',
      layoutDirection: TextDirection.ltr,
      creationParams: null,
      creationParamsCodec: const StandardMessageCodec(),
    )..create();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview Player'),
      ),
      body: Center(
        child: AndroidViewSurface(
          controller: _controller,
          gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
          hitTestBehavior: PlatformViewHitTestBehavior.opaque,
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Dispose the controller when the widget is removed from the widget tree
    _controller.dispose();
    super.dispose();
  }
}
