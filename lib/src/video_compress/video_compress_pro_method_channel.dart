import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import '../media/media_info.dart';
import 'isolate_helper.dart';
import 'video_compress_pro_platform_interface.dart';
import 'video_quality.dart';

class VideoCompressProMethodChannel extends VideoCompressProPlatformInterface {
  static const MethodChannel _channel = MethodChannel('video_compress');

  @override
  void setProgressCallback(Future<void> Function(MethodCall) callback) {
    _channel.setMethodCallHandler(callback);
  }

  @override
  Future<Uint8List?> getByteThumbnail(String path,
      {int quality = 100, int position = -1}) async {
    return await IsolateHelper.executeMethodCall<Uint8List>(
        'getByteThumbnail', {
      'path': path,
      'quality': quality,
      'position': position,
    });
  }

  @override
  Future<File> getFileThumbnail(String path,
      {int quality = 100, int position = -1}) async {
    final filePath =
        await IsolateHelper.executeMethodCall<String>('getFileThumbnail', {
      'path': path,
      'quality': quality,
      'position': position,
    });
    return File(Uri.decodeFull(filePath!));
  }

  @override
  Future<MediaInfo> getMediaInfo(String path) async {
    final jsonStr = await IsolateHelper.executeMethodCall<String>(
        'getMediaInfo', {'path': path});
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
    final jsonStr =
        await IsolateHelper.executeMethodCall<String>('compressVideo', {
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
    await IsolateHelper.executeMethodCall<void>('cancelCompression', {});
  }

  @override
  Future<bool?> deleteAllCache() async {
    return await IsolateHelper.executeMethodCall<bool>('deleteAllCache', {});
  }

  @override
  Future<void> setLogLevel(int logLevel) async {
    await IsolateHelper.executeMethodCall<void>('setLogLevel', {
      'logLevel': logLevel,
    });
  }
}
