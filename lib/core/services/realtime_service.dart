import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:turf_app/core/constants/api_constants.dart';

part 'realtime_service.g.dart';

class RealtimeService {
  final Map<String, WebSocketChannel> _channels = {};
  final Map<String, StreamController<Map<String, dynamic>>> _controllers = {};
  final Map<String, int> _reconnectAttempts = {};
  final Map<String, Timer> _reconnectTimers = {};
  Timer? _heartbeatTimer;
  String? _lastActivePath;
  bool _isDisposed = false;

  RealtimeService() {
    _startHeartbeat();
  }

  static String getBaseWsUrl() => ApiConstants.baseWsUrl;

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    // Send ping every 25 seconds to keep all active cloud WebSockets alive
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (_isDisposed) return;
      for (final entry in _channels.entries) {
        try {
          entry.value.sink.add(jsonEncode({'type': 'ping', 'timestamp': DateTime.now().millisecondsSinceEpoch}));
        } catch (_) {}
      }
    });
  }

  Stream<Map<String, dynamic>> subscribeToChannel(String path) => connectToChannel(path);

  Stream<Map<String, dynamic>> connectToChannel(String path) {
    if (_isDisposed) {
      final closedController = StreamController<Map<String, dynamic>>.broadcast()..close();
      return closedController.stream;
    }
    _lastActivePath = path;

    if (_controllers.containsKey(path) && !_controllers[path]!.isClosed) {
      return _controllers[path]!.stream;
    }

    final controller = StreamController<Map<String, dynamic>>.broadcast();
    _controllers[path] = controller;
    _reconnectAttempts[path] = 0;

    _openChannel(path, controller);

    return controller.stream;
  }

  void _openChannel(String path, StreamController<Map<String, dynamic>> controller) {
    if (_isDisposed || controller.isClosed) return;
    final wsUrl = '${getBaseWsUrl()}/$path';

    try {
      final channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _channels[path] = channel;

      channel.stream.listen(
        (data) {
          _reconnectAttempts[path] = 0; // reset attempts on message received
          try {
            final jsonMap = jsonDecode(data as String) as Map<String, dynamic>;
            if (jsonMap['type'] == 'pong') {
              return; // Keepalive response handled
            }
            if (!_isDisposed && !controller.isClosed) {
              controller.add(jsonMap);
            }
          } catch (e) {
            debugPrint('Realtime parse error [$path]: $e');
          }
        },
        onError: (err) {
          debugPrint('Realtime connection error [$path]: $err');
          if (!_isDisposed) _scheduleReconnect(path, controller);
        },
        onDone: () {
          debugPrint('Realtime connection closed [$path]');
          _channels.remove(path);
          if (!_isDisposed) _scheduleReconnect(path, controller);
        },
      );
    } catch (e) {
      debugPrint('Realtime connection failed [$path]: $e');
      if (!_isDisposed) _scheduleReconnect(path, controller);
    }
  }

  void _scheduleReconnect(String path, StreamController<Map<String, dynamic>> controller) {
    if (_isDisposed || controller.isClosed) return;
    if (!_controllers.containsKey(path)) return; // Disconnected deliberately

    _reconnectTimers[path]?.cancel();
    final attempts = _reconnectAttempts[path] ?? 0;
    _reconnectAttempts[path] = attempts + 1;
    final delaySeconds = (attempts < 5) ? (2 * (attempts + 1)).clamp(2, 15) : 15;

    _reconnectTimers[path] = Timer(Duration(seconds: delaySeconds), () {
      if (_isDisposed || controller.isClosed || !_controllers.containsKey(path)) return;
      debugPrint('Attempting realtime reconnect to [$path] (attempt ${attempts + 1})...');
      _openChannel(path, controller);
    });
  }

  void sendMessage(Map<String, dynamic> message, {String? channelPath}) {
    if (_isDisposed) return;
    final targetPath = channelPath ?? _lastActivePath;
    if (targetPath != null && _channels.containsKey(targetPath)) {
      try {
        _channels[targetPath]!.sink.add(jsonEncode(message));
      } catch (e) {
        debugPrint('Failed to send message to [$targetPath]: $e');
      }
    }
  }

  void emit(String channelPath, Map<String, dynamic> message) => emitToChannel(channelPath, message);

  void emitToChannel(String channelPath, Map<String, dynamic> message) {
    sendMessage(message, channelPath: channelPath);
  }

  bool isConnected(String path) => _channels.containsKey(path);

  void disconnectChannel(String path) {
    _reconnectTimers.remove(path)?.cancel();
    _reconnectAttempts.remove(path);
    final channel = _channels.remove(path);
    try {
      channel?.sink.close();
    } catch (_) {}
    final controller = _controllers.remove(path);
    try {
      controller?.close();
    } catch (_) {}
  }

  void dispose() {
    _isDisposed = true;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    for (final timer in _reconnectTimers.values) {
      timer.cancel();
    }
    _reconnectTimers.clear();
    _reconnectAttempts.clear();
    final channelsToClose = List<WebSocketChannel>.from(_channels.values);
    _channels.clear();
    for (final channel in channelsToClose) {
      try {
        channel.sink.close();
      } catch (_) {}
    }
    final controllersToClose = List<StreamController<Map<String, dynamic>>>.from(_controllers.values);
    _controllers.clear();
    for (final controller in controllersToClose) {
      try {
        controller.close();
      } catch (_) {}
    }
  }
}

@riverpod
RealtimeService realtimeService(Ref ref) {
  final service = RealtimeService();
  ref.onDispose(() => service.dispose());
  return service;
}
