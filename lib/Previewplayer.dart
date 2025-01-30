// import 'package:flutter/foundation.dart';
// import 'package:flutter/gestures.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
// import 'package:flutter/services.dart';

// class PreviewPlayer extends StatefulWidget {
//   const PreviewPlayer({Key? key}) : super(key: key);

//   @override
//   State<PreviewPlayer> createState() => _PreviewPlayerState();
// }

// class _PreviewPlayerState extends State<PreviewPlayer> {
//   late AndroidViewController _controller;

//   @override
//   void initState() {
//     super.initState();

//     // Initialize the controller with a unique ID
//     _controller = PlatformViewsService.initSurfaceAndroidView(
//       id: 0, // Use a unique ID if you have multiple views
//       viewType:
//           'com.arashivision.sdkmedia.player.capture.InstaCapturePlayerView',
//       layoutDirection: TextDirection.ltr,
//       creationParams: null,
//       creationParamsCodec: const StandardMessageCodec(),
//     );

//     // Create the platform view
//     _controller.create();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Preview Player'),
//       ),
//       body: Center(
//         child: SizedBox(
//           width: MediaQuery.of(context).size.width,
//           height: MediaQuery.of(context).size.height,
//           child: AndroidViewSurface(
//             controller: _controller,
//             gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
//             hitTestBehavior: PlatformViewHitTestBehavior.translucent,
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     // Dispose of the controller to release resources
//     _controller.dispose();
//     super.dispose();
//   }
// }
