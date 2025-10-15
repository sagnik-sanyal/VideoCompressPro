import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'subscription.dart';

class CompressMixin {
  final compressProgress$ = ObservableBuilder<double>();
  final _channel = const MethodChannel('video_compress');
  bool _callbackInitialized = false;

  @protected
  void initProcessCallback() {
    // Ensure Flutter bindings are initialized before setting method call handler
    // This is critical for isolate support
    try {
      WidgetsFlutterBinding.ensureInitialized();
      if (!_callbackInitialized) {
        _channel.setMethodCallHandler(_progressCallback);
        _callbackInitialized = true;
      }
    } catch (e) {
      // In isolate contexts, we may not be able to initialize bindings
      // In this case, progress callbacks won't work, but basic operations will
      debugPrint(
          'VideoCompress: Could not initialize method call handler (isolate context?): $e');
    }
  }

  MethodChannel get channel => _channel;

  bool _isCompressing = false;

  bool get isCompressing => _isCompressing;

  @protected
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
}
