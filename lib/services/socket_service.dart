import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? _socket;
  final Map<String, List<void Function(dynamic)>> _listeners = {};

  io.Socket? get socket => _socket;

  void connect() {
    if (_socket != null && _socket!.connected) {
      debugPrint('Socket already connected');
      return;
    }

    try {
      const String serverUrl = 'https://snapshhot-backend-mocha.vercel.app';

      _socket = io.io(serverUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
      });

      _socket!.onConnect((_) {
        debugPrint('Socket connected: ${_socket!.id}');
      });

      _socket!.onDisconnect((_) {
        debugPrint('Socket disconnected');
      });

      _socket!.onError((error) {
        debugPrint('Socket error: $error');
      });

      _socket!.connect();
    } catch (e) {
      debugPrint('Socket connection error: $e');
    }
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
      _listeners.clear();
    }
  }

  void joinUser(String userId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('join-user', userId);
      debugPrint('Joined user room: $userId');
    }
  }

  void leaveUser(String userId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('leave-user', userId);
      debugPrint('Left user room: $userId');
    }
  }

  void joinPost(String postId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('join-post', postId);
      debugPrint('Joined post: $postId');
    }
  }

  void leavePost(String postId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('leave-post', postId);
      debugPrint('Left post: $postId');
    }
  }

  void on(String event, Function(dynamic) callback) {
    if (_socket != null) {
      _socket!.on(event, callback);

      // Store listener for cleanup
      if (!_listeners.containsKey(event)) {
        _listeners[event] = [];
      }
      _listeners[event]!.add(callback);
    }
  }

  void off(String event) {
    if (_socket != null) {
      _socket!.off(event);
      _listeners.remove(event);
    }
  }

  void offAll() {
    if (_socket != null) {
      _listeners.forEach((event, callbacks) {
        _socket!.off(event);
      });
      _listeners.clear();
    }
  }

  bool get isConnected => _socket != null && _socket!.connected;
}
