import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:jni/jni.dart';
import 'package:machine_inspection_camera/sdkcamera_bindings.dart';

class LiveStreamPage extends StatefulWidget {
  const LiveStreamPage({super.key});

  @override
  State<LiveStreamPage> createState() => _LiveStreamPageState();
}

class _LiveStreamPageState extends State<LiveStreamPage> {
  late VlcPlayerController _videoPlayerController;
  bool isListening = false;

  late IPreviewStatusListener listener;

  List<int>? spsHeader;
  List<int>? ppsHeader;
  List<HttpResponse> _clients = [];
  final int httpPort = 8082; // HTTP port for VLC

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

    response.statusCode = HttpStatus.ok; // 200
    response.reasonPhrase = 'OK';

    response.headers.set('Content-Type', 'video/h264');
    response.headers.set('Transfer-Encoding', 'chunked');
    response.headers.set('Cache-Control', 'no-cache');
    response.headers.set('Pragma', 'no-cache');
    response.headers.set('Expires', '0');
    response.headers.set('Connection', 'keep-alive');

    // Ensure CORS (if needed)
    response.headers.set('Access-Control-Allow-Origin', '*');

    _clients.add(response);
    response.done.whenComplete(() {
      print('VLC client disconnected');
      _clients.remove(response);
    });

    print("✅ New VLC client connected. Streaming started.");
  }

  @override
  void initState() {
    super.initState();
    starthttp();

    listener = IPreviewStatusListener.implement(
      $IPreviewStatusListener(
        onOpening: () {
          print("Preview is opening...");
        },
        onOpened: () async {
          print("Preview has started.");

          // final pipeline = capturePlayerView.getPipeline();

          // cameraManager.setPipeline(pipeline);

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
          handleVideoData(videoData.data);

          // print("📌 Video data received: ${frameData.length} bytes");
        },
        onGyroData: (gyroDataList) {
          //   print("Gyro data received: $gyroDataList");
        },
        onExposureData: (exposureData) {
          //  print("Exposure data received: $exposureData");
        },
      ),
    );
    startstream();
    final cameraManager = InstaCameraManager.getInstance();
    cameraManager.setPreviewStatusChangedListener(listener);
    cameraManager.startPreviewStream();
    cameraManager.setStreamEncode();
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

  void extractSpsPps(List<int> h264Data) {
    int index = 0;

    while (index < h264Data.length - 4) {
      if (h264Data[index] == 0x00 &&
          h264Data[index + 1] == 0x00 &&
          h264Data[index + 2] == 0x00 &&
          h264Data[index + 3] == 0x01) {
        int nalType = h264Data[index + 4] & 0x1F;

        if (nalType == 7) {
          // SPS
          int nextNal = findNextStartCode(h264Data, index + 4);
          spsHeader = h264Data.sublist(index + 4, nextNal);
          print("✅ SPS Extracted: ${spsHeader!.length} bytes");
        } else if (nalType == 8) {
          // PPS
          int nextNal = findNextStartCode(h264Data, index + 4);
          ppsHeader = h264Data.sublist(index + 4, nextNal);
          print("✅ PPS Extracted: ${ppsHeader!.length} bytes");
        }
      }
      index++;
    }
  }

  int findNextStartCode(List<int> data, int start) {
    for (int i = start; i < data.length - 4; i++) {
      if (data[i] == 0x00 &&
          data[i + 1] == 0x00 &&
          data[i + 2] == 0x00 &&
          data[i + 3] == 0x01) {
        return i;
      }
    }
    return data.length; // No next start code found
  }

  void _broadcastToClients(List<int> frameData) {
    bool isIframe = isIframetest(frameData);
    List<int> finalFrame = frameData;

    if (isIframe && spsHeader != null && ppsHeader != null) {
      finalFrame = [
        0,
        0,
        0,
        1,
        ...spsHeader!,
        0,
        0,
        0,
        1,
        ...ppsHeader!,
        ...frameData
      ];
    }

    Uint8List optimizedFrame =
        Uint8List.fromList(finalFrame); // Efficient buffer
    for (final client in _clients) {
      client.add(optimizedFrame);
    }
  }

  void handleVideoData(JArray<jbyte> videoData) {
    List<int> frameData =
        List<int>.generate(videoData.length, (i) => videoData[i] & 0xFF);

    if (spsHeader == null || ppsHeader == null) {
      extractSpsPps(frameData);
    }

    if (isIframetest(frameData)) {
      print("📌 I-frame detected! Sending to VLC.");
    }

    _broadcastToClients(frameData);
  }

  Future<void> startstream() async {
    const streamUrl = 'http://127.0.0.1:8082/stream';

    _videoPlayerController = VlcPlayerController.network(
      streamUrl,
      hwAcc: HwAcc.full,
      autoPlay: true,
      options: VlcPlayerOptions(
        http: VlcHttpOptions([
          VlcHttpOptions.httpContinuous(true),
        ]),
        advanced: VlcAdvancedOptions([
          VlcAdvancedOptions.networkCaching(500), // Reduce caching to 500ms
          VlcAdvancedOptions.liveCaching(500),
          VlcAdvancedOptions.fileCaching(500),
          VlcAdvancedOptions.clockJitter(10), // Reduce jitter
          VlcAdvancedOptions.clockSynchronization(10),
        ]),
        extras: [
          '--rtsp-tcp', // Ensure TCP streaming
          '--no-video-title-show', // Disable title overlay
          '--avcodec-fast', // Enable fast decoding
        ],
      ),
    );

    setState(() {
      isListening = true;
    });
  }

  Future<bool> checkStreamAvailable(String url) async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      return response.statusCode == 200;
    } catch (e) {
      print('Stream check failed: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose(); // Properly dispose of the controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Stream')),
      body: Center(
        child: isListening
            ? VlcPlayer(
                controller: _videoPlayerController,
                aspectRatio: 16 / 9,
                placeholder: const Center(
                  child: Text(
                    'Initializing stream...',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}

bool isIframetest(List<int> frameData) {
  if (frameData.length < 5) return false;
  final int nalType = frameData[4] & 0x1F;
  bool result = (nalType == 5 || nalType == 19 || nalType == 20);

  if (result) {
    print("📌 I-frame detected with NAL type: $nalType");
  }

  return result;
}
