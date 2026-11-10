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
  String? _lastActivePath;

  static String getBaseWsUrl() => ApiConstants.baseWsUrl;

  Stream<Map<String, dynamic>> subscribeToChannel(String path) => connectToChannel(path);

  Stream<Map<String, dynamic>> connectToChannel(String path) {
    _lastActivePath = path;

    if (_controllers.containsKey(path) && !_controllers[path]!.isClosed) {
      return _controllers[path]!.stream;
    }

    final controller = StreamController<Map<String, dynamic>>.broadcast();
    _controllers[path] = controller;

    final wsUrl = '${getBaseWsUrl()}/$path';

    try {
      final channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _channels[path] = channel;

      channel.stream.listen(
        (data) {
          try {
            final jsonMap = jsonDecode(data as String) as Map<String, dynamic>;
            if (!controller.isClosed) {
              controller.add(jsonMap);
            }
          } catch (e) {
            debugPrint('Realtime parse error [$path]: $e');
          }
        },
        onError: (err) {
          debugPrint('Realtime connection error [$path]: $err');
          _reconnect(path, controller);
        },
        onDone: () {
          debugPrint('Realtime connection closed [$path]');
          _channels.remove(path);
        },
      );
    } catch (e) {
      debugPrint('Realtime connection failed [$path]: $e');
    }

    return controller.stream;
  }

  void _reconnect(String path, StreamController<Map<String, dynamic>> controller) {
    if (controller.isClosed) return;
    Future.delayed(const Duration(seconds: 3), () {
      if (controller.isClosed) return;
      final wsUrl = '${getBaseWsUrl()}/$path';
      try {
        final channel = WebSocketChannel.connect(Uri.parse(wsUrl));
        _channels[path] = channel;
        channel.stream.listen(
          (data) {
            try {
              final jsonMap = jsonDecode(data as String) as Map<String, dynamic>;
              if (!controller.isClosed) {
                controller.add(jsonMap);
              }
            } catch (e) {
              debugPrint('Realtime parse error [$path]: $e');
            }
          },
          onError: (err) => debugPrint('Realtime reconnect error [$path]: $err'),
          onDone: () => _channels.remove(path),
        );
      } catch (_) {}
    });
  }

  void sendMessage(Map<String, dynamic> message, {String? channelPath}) {
    final targetPath = channelPath ?? _lastActivePath;
    if (targetPath != null && _channels.containsKey(targetPath)) {
      _channels[targetPath]!.sink.add(jsonEncode(message));
    }
  }

  void emitToChannel(String channelPath, Map<String, dynamic> message) {
    sendMessage(message, channelPath: channelPath);
  }


  void disconnectChannel(String path) {
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
