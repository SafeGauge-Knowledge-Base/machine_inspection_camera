import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:panorama_viewer/panorama_viewer.dart';

class ThetaLivePreview extends StatefulWidget {
  const ThetaLivePreview({super.key});

  @override
  _ThetaLivePreviewState createState() => _ThetaLivePreviewState();
}

class _ThetaLivePreviewState extends State<ThetaLivePreview> {
  final String baseUrl = 'http://192.168.1.1';
  final String endpoint = '/osc/commands/execute';
  Dio dio = Dio();

  /// Receives frames to show in UI
  late StreamController<Uint8List> _imageStreamController;

  /// Controls streaming lifecycle
  bool _isStreaming = false;

  /// Collects incoming byte data for MJPEG parsing
  List<int> _bufferBytes = [];
  int? _startIndex;
  int? _endIndex;

  /// Queue for storing frames
  final Queue<Uint8List> _frameQueue = Queue<Uint8List>();

  @override
  void initState() {
    super.initState();
    _imageStreamController = StreamController<Uint8List>();
    startLivePreview();
  }

  /// Starts the camera’s live preview request
  void startLivePreview() async {
    if (_isStreaming) return;
    _isStreaming = true;

    final headers = {
      'Content-Type': 'application/json;charset=utf-8',
      'Accept': 'application/json',
      'X-XSRF-Protected': '1',
    };

    final Map<String, dynamic> payload = {"name": "camera.getLivePreview"};

    try {
      Response<ResponseBody> response = await dio.post<ResponseBody>(
        '$baseUrl$endpoint',
        data: payload,
        options: Options(
          headers: headers,
          responseType: ResponseType.stream, // Expecting an MJPEG stream
        ),
      );

      if (response.statusCode == 200) {
        // Start listening to the MJPEG stream immediately
        _processMJPEGStream(response.data!);
        _playFramesFromQueue();
      } else {
        debugPrint(
            'Failed to start live preview. Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error starting live preview: $e');
    }
  }

  /// Continuously parses the incoming MJPEG stream and adds complete JPEG frames to _frameQueue
  void _processMJPEGStream(ResponseBody responseBody) {
    responseBody.stream.listen(
      (List<int> data) {
        _bufferBytes.addAll(data); // Append incoming data

        // Attempt to find JPEG start (FFD8) and end (FFD9) markers
        for (int i = 0; i < data.length - 1; i++) {
          // JPEG Start?
          if (data[i] == 0xFF && data[i + 1] == 0xD8) {
            _startIndex = _bufferBytes.length - (data.length - i);
          }
          // JPEG End?
          if (data[i] == 0xFF && data[i + 1] == 0xD9 && _startIndex != null) {
            _endIndex = _bufferBytes.length;

            if (_endIndex! > _startIndex!) {
              // Extract JPEG frame
              Uint8List frame = Uint8List.fromList(
                _bufferBytes.sublist(_startIndex!, _endIndex!),
              );

              // Add to our queue
              _frameQueue.add(frame);

              // Remove processed bytes from buffer
              _bufferBytes = _bufferBytes.sublist(_endIndex!);

              // Reset
              _startIndex = null;
              _endIndex = null;
            }
          }
        }
      },
      onError: (error) {
        debugPrint("Stream Error: $error");
      },
      cancelOnError: true,
    );
  }

  /// Plays frames from the queue at ~30 FPS immediately
  void _playFramesFromQueue() async {
    while (_isStreaming) {
      if (_frameQueue.isNotEmpty) {
        // Pop the oldest frame
        final frame = _frameQueue.removeFirst();
        // Send the frame to the UI
        _imageStreamController.add(frame);

        // Aim for ~30 FPS
        //await Future.delayed(const Duration(milliseconds: 33));
      } else {
        // If queue is empty, wait briefly to avoid unnecessary CPU usage
        await Future.delayed(const Duration(milliseconds: 10));
      }
    }
  }

  @override
  void dispose() {
    _isStreaming = false;
    _imageStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("RICOH THETA Live Preview")),
      body: Center(
        child: StreamBuilder<Uint8List>(
          stream: _imageStreamController.stream,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return ClipRect(
                // Crops the edges
                child: SizedBox(
                  width: 800, // Fixed square size
                  height: 500,
                  child: PanoramaViewer(
                    child: Image.memory(
                      snapshot.data!,
                      fit: BoxFit.cover, // Crops and zooms in the image
                    ),
                  ),
                ),
              );
            } else {
              return const CircularProgressIndicator();
            }
          },
        ),
      ),
    );
  }
}
