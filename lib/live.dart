import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

class LiveStreamPage extends StatefulWidget {
  @override
  _LiveStreamPageState createState() => _LiveStreamPageState();
}

class _LiveStreamPageState extends State<LiveStreamPage> {
  late VlcPlayerController _videoPlayerController;
  bool isListening = false;

  @override
  void initState() {
    super.initState();
    startstream();
  }

  Future<void> startstream() async {
    const streamUrl = 'http://127.0.0.1:8081/stream';
    final isStreamAvailable = await checkStreamAvailable(streamUrl);

    if (isStreamAvailable) {
      _videoPlayerController = VlcPlayerController.network(
        streamUrl,
        hwAcc: HwAcc.full,
        autoPlay: true,
        options: VlcPlayerOptions(
          http: VlcHttpOptions([
            VlcHttpOptions.httpContinuous(true),
          ]),
          advanced: VlcAdvancedOptions([
            VlcAdvancedOptions.networkCaching(200),
            VlcAdvancedOptions.liveCaching(200),
            VlcAdvancedOptions.fileCaching(200),
            VlcAdvancedOptions.clockJitter(0),
            VlcAdvancedOptions.clockSynchronization(1)
          ]),
        ),
      );

      setState(() {
        isListening = true;
      });
    } else {
      print('Stream is not available at $streamUrl');
    }
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
