import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:video_compress/video_compress.dart';

import 'isolate_helper.dart';
import 'video_compress_pro_platform_interface.dart';

class VideoCompressPro {
  final compressProgress$ = ObservableBuilder<double>();
  bool _isCompressing = false;

  VideoCompressPro._() {
    // Initialize isolate helper for cross-isolate communication
    IsolateHelper.initializeRootIsolate();

    try {
      VideoCompressProPlatformInterface.instance.setProgressCallback(
        _progressCallback,
      );
    } catch (e) {
      print(
          'VideoCompress: Could not initialize method call handler (isolate context?): $e');
    }
  }

  static VideoCompressPro? _instance;

  static VideoCompressPro get instance {
    return _instance ??= VideoCompressPro._();
  }

  void dispose() {
    IsolateHelper.dispose();
    _instance = null;
  }

  bool get isCompressing => _isCompressing;
  void setProcessingStatus(bool status) {
    _isCompressing = status;
  }

  Future<void> _progressCallback(MethodCall call) async {
    switch (call.method) {
      case 'updateProgress':
        final progress = double.tryParse(call.arguments.toString());
        if (progress != null) compressProgress$.next(progress);
        break;
    }
  }

  /// getByteThumbnail return [Future<Uint8List>],
  /// quality can be controlled by [quality] from 1 to 100,
  /// select the position unit in the video by [position] is milliseconds
  Future<Uint8List?> getByteThumbnail(
    String path, {
    int quality = 100,
    int position = -1,
  }) async {
    assert(quality > 1 || quality < 100);
    return await VideoCompressProPlatformInterface.instance.getByteThumbnail(
      path,
      quality: quality,
      position: position,
    );
  }

  /// getFileThumbnail return [Future<File>]
  /// quality can be controlled by [quality] from 1 to 100,
  /// select the position unit in the video by [position] is milliseconds
  Future<File> getFileThumbnail(
    String path, {
    int quality = 100,
    int position = -1,
  }) async {
    assert(quality > 1 || quality < 100);
    return await VideoCompressProPlatformInterface.instance.getFileThumbnail(
      path,
      quality: quality,
      position: position,
    );
  }

  /// get media information from [path]
  ///
  /// get media information from [path] return [Future<MediaInfo>]
  ///
  /// ## example
  /// ```dart
  /// final info = await _flutterVideoCompress.getMediaInfo(file.path);
  /// debugPrint(info.toJson());
  /// ```
  Future<MediaInfo> getMediaInfo(String path) async {
    return await VideoCompressProPlatformInterface.instance.getMediaInfo(path);
  }

  /// compress video from [path]
  /// compress video from [path] return [Future<MediaInfo>]
  ///
  /// you can choose its quality by [quality],
  /// determine whether to delete his source file by [deleteOrigin]
  /// optional parameters [startTime] [duration] [includeAudio] [frameRate]
  ///
  /// ## example
  /// ```dart
  /// final info = await _flutterVideoCompress.compressVideo(
  ///   file.path,
  ///   deleteOrigin: true,
  /// );
  /// debugPrint(info.toJson());
  /// ```
  Future<MediaInfo?> compressVideo(
    String path, {
    VideoQuality quality = VideoQuality.DefaultQuality,
    bool deleteOrigin = false,
    int? startTime,
    int? duration,
    bool? includeAudio,
    int frameRate = 30,
  }) async {
    // Optionally, you can keep the isCompressing logic here if needed
    return await VideoCompressProPlatformInterface.instance.compressVideo(
      path,
      quality: quality,
      deleteOrigin: deleteOrigin,
      startTime: startTime,
      duration: duration,
      includeAudio: includeAudio,
      frameRate: frameRate,
    );
  }

  /// stop compressing the file that is currently being compressed.
  /// If there is no compression process, nothing will happen.
  Future<void> cancelCompression() async {
    await VideoCompressProPlatformInterface.instance.cancelCompression();
  }

  /// delete the cache folder, please do not put other things
  /// in the folder of this plugin, it will be cleared
  Future<bool?> deleteAllCache() async {
    return await VideoCompressProPlatformInterface.instance.deleteAllCache();
  }

  Future<void> setLogLevel(int logLevel) async {
    await VideoCompressProPlatformInterface.instance.setLogLevel(logLevel);
  }
}
