import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';

class SocketService with ChangeNotifier {
  IO.Socket? _socket;
  
  // Use localhost for Web, 10.0.2.2 for Android Emulator
  String get _serverUrl {
    if (kIsWeb) {
      return 'http://localhost:5000';
    }
    return 'http://10.0.2.2:5000';
  }
  
  IO.Socket? get socket => _socket;
  bool get isConnected => _socket?.connected ?? false;

  List<String> _onlineUsers = [];
  List<String> get onlineUsers => _onlineUsers;

  void connect(String userId) {
    if (_socket != null && _socket!.connected) return;

    _socket = IO.io(_serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket!.connect();

    _socket!.onConnect((_) {
      debugPrint('Connected to Socket.IO');
      _socket!.emit('setup', {'_id': userId});
      notifyListeners();
    });

    _socket!.on('connected', (_) {
      debugPrint('Setup successful');
    });

    _socket!.on('online users', (data) {
      if (data is List) {
        _onlineUsers = List<String>.from(data);
        notifyListeners();
      }
    });

    _socket!.onDisconnect((_) {
      debugPrint('Disconnected from Socket.IO');
      notifyListeners();
    });
  }
  
  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
      notifyListeners();
    }
  }

  // Helper method to subscribe to events
  void on(String event, Function(dynamic) callback) {
    _socket?.on(event, callback);
  }
  
  // Helper method to emit events
  void emit(String event, dynamic data) {
      _socket?.emit(event, data);
  }

  void off(String event) {
      _socket?.off(event);
  }
}
