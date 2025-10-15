import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../media/media_info.dart';
import 'video_compress_pro_platform_interface.dart';
import 'video_quality.dart';

class VideoCompressProMethodChannel extends VideoCompressProPlatformInterface {
  static const MethodChannel _channel = MethodChannel('video_compress');

  @override
  void setProgressCallback(Future<void> Function(MethodCall) callback) {
    WidgetsFlutterBinding.ensureInitialized();
    _channel.setMethodCallHandler(callback);
  }

  @override
  Future<Uint8List?> getByteThumbnail(String path,
      {int quality = 100, int position = -1}) async {
    WidgetsFlutterBinding.ensureInitialized();
    return await _channel.invokeMethod<Uint8List>('getByteThumbnail', {
      'path': path,
      'quality': quality,
      'position': position,
    });
  }

  @override
  Future<File> getFileThumbnail(String path,
      {int quality = 100, int position = -1}) async {
    WidgetsFlutterBinding.ensureInitialized();
    final filePath = await _channel.invokeMethod<String>('getFileThumbnail', {
      'path': path,
      'quality': quality,
      'position': position,
    });
    return File(Uri.decodeFull(filePath!));
  }

  @override
  Future<MediaInfo> getMediaInfo(String path) async {
    WidgetsFlutterBinding.ensureInitialized();
    final jsonStr =
        await _channel.invokeMethod<String>('getMediaInfo', {'path': path});
    final jsonMap = json.decode(jsonStr!);
    return MediaInfo.fromJson(jsonMap);
  }

  @override
  Future<MediaInfo?> compressVideo(
    String path, {
    VideoQuality quality = VideoQuality.DefaultQuality,
    bool deleteOrigin = false,
    int? startTime,
    int? duration,
    bool? includeAudio,
    int frameRate = 30,
  }) async {
    WidgetsFlutterBinding.ensureInitialized();
    final jsonStr = await _channel.invokeMethod<String>('compressVideo', {
      'path': path,
      'quality': quality.index,
      'deleteOrigin': deleteOrigin,
      'startTime': startTime,
      'duration': duration,
      'includeAudio': includeAudio,
      'frameRate': frameRate,
    });
    if (jsonStr != null) {
      final jsonMap = json.decode(jsonStr);
      return MediaInfo.fromJson(jsonMap);
    } else {
      return null;
    }
  }

  @override
  Future<void> cancelCompression() async {
    WidgetsFlutterBinding.ensureInitialized();
    await _channel.invokeMethod<void>('cancelCompression');
  }

  @override
  Future<bool?> deleteAllCache() async {
    WidgetsFlutterBinding.ensureInitialized();
    return await _channel.invokeMethod<bool>('deleteAllCache');
  }

  @override
  Future<void> setLogLevel(int logLevel) async {
    WidgetsFlutterBinding.ensureInitialized();
    await _channel.invokeMethod<void>('setLogLevel', {
      'logLevel': logLevel,
    });
  }
}
