import 'dart:io';

import 'package:flutter/services.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:video_compress/src/video_compress/video_compress_pro_method_channel.dart';

import '../media/media_info.dart';
import 'video_quality.dart';

abstract class VideoCompressProPlatformInterface extends PlatformInterface {
  VideoCompressProPlatformInterface() : super(token: _token);

  static final Object _token = Object();

  static VideoCompressProPlatformInterface _instance =
      VideoCompressProMethodChannel();

  static VideoCompressProPlatformInterface get instance => _instance;

  static set instance(VideoCompressProPlatformInterface instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  void setProgressCallback(Future<void> Function(MethodCall) callback) {
    throw UnimplementedError('setProgressCallback() has not been implemented.');
  }

  Future<Uint8List?> getByteThumbnail(String path,
      {int quality = 100, int position = -1}) {
    throw UnimplementedError('getByteThumbnail() has not been implemented.');
  }

  Future<File> getFileThumbnail(String path,
      {int quality = 100, int position = -1}) {
    throw UnimplementedError('getFileThumbnail() has not been implemented.');
  }

  Future<MediaInfo> getMediaInfo(String path) {
    throw UnimplementedError('getMediaInfo() has not been implemented.');
  }

  Future<MediaInfo?> compressVideo(
    String path, {
    VideoQuality quality = VideoQuality.DefaultQuality,
    bool deleteOrigin = false,
    int? startTime,
    int? duration,
    bool? includeAudio,
    int frameRate = 30,
  }) {
    throw UnimplementedError('compressVideo() has not been implemented.');
  }

  Future<void> cancelCompression() {
    throw UnimplementedError('cancelCompression() has not been implemented.');
  }

  Future<bool?> deleteAllCache() {
    throw UnimplementedError('deleteAllCache() has not been implemented.');
  }

  Future<void> setLogLevel(int logLevel) {
    throw UnimplementedError('setLogLevel() has not been implemented.');
  }
}
