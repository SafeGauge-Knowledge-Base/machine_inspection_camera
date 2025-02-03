import 'dart:collection';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
part 'camera_event.dart';
part 'camera_state.dart';

class CameraBloc extends Bloc<CameraEvent, CameraState> {
  CameraBloc() : super(CameraState()) {
    const String baseUrl = 'http://192.168.1.1';
    const String endpoint = '/osc/commands/execute';
    final Queue<Uint8List> _frameQueue = Queue<Uint8List>();
    Dio dio = Dio();
    List<int> bufferBytes = [];
    int? startIndex;
    int? endIndex;

    /// Plays frames from the queue at ~30 FPS immediately
    void playFramesFromQueue() async {
      while (state.isStreaming) {
        if (_frameQueue.isNotEmpty) {
          // Pop the oldest frame
          final frame = _frameQueue.removeFirst();

          add(onPushImage(frame));
          // Send the frame to the UI

          // Aim for ~30 FPS
          //await Future.delayed(const Duration(milliseconds: 33));
        } else {
          // If queue is empty, wait briefly to avoid unnecessary CPU usage
          await Future.delayed(const Duration(milliseconds: 10));
        }
      }
    }

    /// Continuously parses the incoming MJPEG stream and adds complete JPEG frames to _frameQueue
    void processMJPEGStream(ResponseBody responseBody) {
      responseBody.stream.listen(
        (List<int> data) {
          bufferBytes.addAll(data); // Append incoming data

          // Attempt to find JPEG start (FFD8) and end (FFD9) markers
          for (int i = 0; i < data.length - 1; i++) {
            // JPEG Start?
            if (data[i] == 0xFF && data[i + 1] == 0xD8) {
              startIndex = bufferBytes.length - (data.length - i);
            }
            // JPEG End?
            if (data[i] == 0xFF && data[i + 1] == 0xD9 && startIndex != null) {
              endIndex = bufferBytes.length;

              if (endIndex! > startIndex!) {
                // Extract JPEG frame
                Uint8List frame = Uint8List.fromList(
                  bufferBytes.sublist(startIndex!, endIndex!),
                );

                // Add to our queue
                _frameQueue.add(frame);

                // Remove processed bytes from buffer
                bufferBytes = bufferBytes.sublist(endIndex!);

                // Reset
                startIndex = null;
                endIndex = null;
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

    on<StartLive>((event, emit) async {
      if (state.isStreaming) return;
      emit(state.copyWith(isStreaming: true));
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
          processMJPEGStream(response.data!);
          playFramesFromQueue();
        } else {
          debugPrint(
              'Failed to start live preview. Status: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('Error starting live preview: $e');
      }
    });

    on<onPushImage>((event, emit) {
      emit(state.copyWith(image: event.image));
    });
  }
}
