import 'dart:async';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:video_compress/video_compress.dart';

/// Example of using VideoCompress in a Dart isolate
class IsolateVideoCompressExample extends StatefulWidget {
  const IsolateVideoCompressExample({Key? key}) : super(key: key);

  @override
  State<IsolateVideoCompressExample> createState() =>
      _IsolateVideoCompressExampleState();
}

class _IsolateVideoCompressExampleState
    extends State<IsolateVideoCompressExample> {
  String _status = 'Idle';
  double _progress = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Isolate Video Compress'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Status: $_status'),
            const SizedBox(height: 20),
            LinearProgressIndicator(value: _progress),
            const SizedBox(height: 20),
            Text('Progress: ${(_progress * 100).toStringAsFixed(1)}%'),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _compressInIsolate,
              child: const Text('Compress in Isolate'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _compressInIsolate() async {
    setState(() {
      _status = 'Starting compression in isolate...';
      _progress = 0.0;
    });

    try {
      // Create a receive port for communication from the isolate
      final receivePort = ReceivePort();

      // Spawn the isolate
      await Isolate.spawn(
        _compressionIsolate,
        IsolateMessage(
          sendPort: receivePort.sendPort,
          videoPath: '/path/to/your/video.mp4', // Replace with actual path
        ),
      );

      // Listen for messages from the isolate
      await for (final message in receivePort) {
        if (message is IsolateProgress) {
          setState(() {
            _progress = message.progress / 100.0;
            _status = 'Compressing...';
          });
        } else if (message is IsolateComplete) {
          setState(() {
            _status = 'Complete! Output: ${message.outputPath}';
            _progress = 1.0;
          });
          receivePort.close();
          break;
        } else if (message is IsolateError) {
          setState(() {
            _status = 'Error: ${message.error}';
          });
          receivePort.close();
          break;
        }
      }
    } catch (e) {
      setState(() {
        _status = 'Failed to start isolate: $e';
      });
    }
  }

  /// This function runs in a separate isolate
  static Future<void> _compressionIsolate(IsolateMessage message) async {
    try {
      // Subscribe to compression progress
      final subscription =
          VideoCompressPro.instance.compressProgress$.subscribe((progress) {
        message.sendPort.send(IsolateProgress(progress: progress));
      });

      // Compress the video
      final info = await VideoCompressPro.instance.compressVideo(
        message.videoPath,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
        includeAudio: true,
      );

      // Cancel subscription
      subscription.unsubscribe();

      if (info != null) {
        message.sendPort.send(IsolateComplete(
          outputPath: info.path ?? 'Unknown path',
        ));
      } else {
        message.sendPort.send(IsolateError(error: 'Compression cancelled'));
      }
    } catch (e) {
      message.sendPort.send(IsolateError(error: e.toString()));
    }
  }
}

/// Message to send to the isolate
class IsolateMessage {
  final SendPort sendPort;
  final String videoPath;

  IsolateMessage({
    required this.sendPort,
    required this.videoPath,
  });
}

/// Progress update from isolate
class IsolateProgress {
  final double progress;

  IsolateProgress({required this.progress});
}

/// Completion message from isolate
class IsolateComplete {
  final String outputPath;

  IsolateComplete({required this.outputPath});
}

/// Error message from isolate
class IsolateError {
  final String error;

  IsolateError({required this.error});
}
