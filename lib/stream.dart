import 'dart:io';
import 'dart:typed_data';

import 'package:udp/udp.dart';

class HttpUdpStreamer {
  final int udpPort = 8556; // UDP port receiving GoPro data
  final int httpPort = 8081; // HTTP port for VLC

  List<HttpResponse> _clients = []; // HTTP clients connected to the server
  late UDP _udpReceiver;

  Future<void> start() async {
    // Start the HTTP server
    final httpServer =
        await HttpServer.bind(InternetAddress.anyIPv4, httpPort, shared: true);

    // Handle HTTP connections
    httpServer.listen((HttpRequest request) {
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

    // Start listening for UDP packets
    _udpReceiver = await UDP.bind(
      Endpoint.unicast(InternetAddress.anyIPv4, port: Port(udpPort)),
    );
    print('Listening for UDP packets on port $udpPort...');

    // Forward UDP packets to all HTTP clients
    _udpReceiver.asStream().listen((datagram) {
      if (datagram != null) {
        // print(
        //     'Received UDP packet from ${datagram.address.address}:${datagram.port}');
        _broadcastToClients(datagram.data);
      }
    });
  }

  void _handleHttpConnection(HttpRequest request) {
    final response = request.response;
    response.bufferOutput = false;

    response.headers.contentType = ContentType('video', 'mp2t');

    response.headers.set('Keep-Alive', 'timeout=5, max=1000');
    response.headers.set('Cache-Control', 'no-cache');
    response.headers.set('Connection', 'keep-alive');
    _clients.add(response);

    // Remove the client when the connection is closed
    response.done.whenComplete(() {
      print('VLC client disconnected');
      _clients.remove(response);
    });
  }

  void _broadcastToClients(Uint8List data) {
    // Send the UDP data to all connected HTTP clients
    for (final client in _clients) {
      client.add(data);
    }
  }

  Future<void> stop() async {
    _udpReceiver.close();
    for (final client in _clients) {
      await client.close();
    }
    _clients.clear();
    print('Streamer stopped');
  }
}
