import 'dart:async';
import 'package:flutter/services.dart';

/// Platform bridge handling native Android text sharing intents.
///
/// Encapsulates all MethodChannel details, isolating presentation layers from native calls.
class NativeBridge {
  static const String channelName = 'dev.codehunters.astra/share_bridge';
  static const String methodGetInitialShare = 'getInitialShareText';
  static const String methodOnShareReceived = 'onShareReceived';

  final MethodChannel _channel;
  final _shareStreamController = StreamController<String>.broadcast();

  NativeBridge({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName) {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method == methodOnShareReceived) {
      final text = call.arguments as String?;
      if (text != null && text.isNotEmpty) {
        _shareStreamController.add(text);
      }
    }
  }

  /// Retrieves the initial share text that triggered the application cold start.
  ///
  /// Returns `null` if the app was started normally.
  Future<String?> getInitialShareText() async {
    try {
      return await _channel.invokeMethod<String>(methodGetInitialShare);
    } on PlatformException {
      return null;
    }
  }

  /// Stream of incoming text share actions from native Android while ASTRA is running.
  Stream<String> get shareStream => _shareStreamController.stream;
}
