import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/services.dart';

/// Helper class to enable method channel communication from background isolates
class IsolateHelper {
  static const MethodChannel _channel = MethodChannel('video_compress');
  static const String _isolatePortName = 'video_compress_isolate_port';
  static ReceivePort? _receivePort;

  /// Initialize the isolate helper on the root isolate
  static void initializeRootIsolate() {
    if (_receivePort != null) return; // Already initialized

    _receivePort = ReceivePort();
    IsolateNameServer.removePortNameMapping(_isolatePortName);
    IsolateNameServer.registerPortWithName(
        _receivePort!.sendPort, _isolatePortName);

    _receivePort!.listen((message) {
      if (message is _IsolateMessage) {
        _handleMessage(message);
      }
    });
  }

  /// Cleanup the isolate helper
  static void dispose() {
    IsolateNameServer.removePortNameMapping(_isolatePortName);
    _receivePort?.close();
    _receivePort = null;
  }

  /// Check if we're running on the root isolate
  static bool get isRootIsolate {
    try {
      // Try to access a method channel - this will only work on root isolate
      _channel.binaryMessenger;
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Execute a method channel call from any isolate
  static Future<T?> executeMethodCall<T>(
    String methodName,
    Map<String, dynamic> arguments,
  ) async {
    if (isRootIsolate) {
      // Direct call on root isolate
      return await _channel.invokeMethod<T>(methodName, arguments);
    } else {
      // Send message to root isolate
      return await _sendMessageToRootIsolate<T>(methodName, arguments);
    }
  }

  static Future<T?> _sendMessageToRootIsolate<T>(
    String methodName,
    Map<String, dynamic> arguments,
  ) async {
    final responsePort = ReceivePort();
    final sendPort = IsolateNameServer.lookupPortByName(_isolatePortName);

    if (sendPort == null) {
      throw Exception(
        'VideoCompress: Root isolate not initialized. '
        'Please ensure VideoCompressPro.instance is created on the main isolate first.',
      );
    }

    final message = _IsolateMessage(
      methodName: methodName,
      arguments: arguments,
      responsePort: responsePort.sendPort,
    );

    sendPort.send(message);

    final response = await responsePort.first;
    responsePort.close();

    if (response is _IsolateResponse<T>) {
      if (response.error != null) {
        throw response.error!;
      }
      return response.result;
    }

    return null;
  }

  static Future<void> _handleMessage(_IsolateMessage message) async {
    try {
      final result =
          await _channel.invokeMethod(message.methodName, message.arguments);

      message.responsePort.send(_IsolateResponse(result: result));
    } catch (e) {
      message.responsePort.send(_IsolateResponse(error: e));
    }
  }
}

class _IsolateMessage {
  final String methodName;
  final Map<String, dynamic> arguments;
  final SendPort responsePort;

  _IsolateMessage({
    required this.methodName,
    required this.arguments,
    required this.responsePort,
  });
}

class _IsolateResponse<T> {
  final T? result;
  final dynamic error;

  _IsolateResponse({this.result, this.error});
}
