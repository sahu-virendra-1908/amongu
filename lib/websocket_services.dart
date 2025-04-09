import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// A singleton WebSocket service to be used throughout the app
class WebSocketService {
  // Singleton instance
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;

  // Private constructor
  WebSocketService._internal();

  // WebSocket connection
  WebSocketChannel? _channel;
  bool _isConnected = false;
  String? _connectedTeam;

  // Stream controllers to broadcast messages
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  // Listeners count for lifecycle management
  int _listenersCount = 0;
  Timer? _reconnectTimer;

  // For debugging
  void printStatus() {
    print(
        'WebSocketService status: connected=${_isConnected}, team=${_connectedTeam}, listeners=${_listenersCount}');
  }

  // Getters
  bool get isConnected => _isConnected;
  WebSocketChannel? get channel => _channel;
  String? get connectedTeam => _connectedTeam;

  // Initialize the connection
  Future<void> connect(String teamName) async {
    if (_channel != null) {
      // Already connected, just update team if needed
      if (_connectedTeam != teamName) {
        _connectedTeam = teamName;
        // Re-join with the new team name
        joinTeam(teamName);
      }
      return;
    }

    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('ws://74.225.188.86:8080'),
      );

      _connectedTeam = teamName;

      _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message);
            _messageController.add(data);
          } catch (e) {
            print('Error parsing WebSocket message: $e');
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          _isConnected = false;
          _scheduleReconnect();
        },
        onDone: () {
          print('WebSocket connection closed');
          _isConnected = false;
          _scheduleReconnect();
        },
      );

      _isConnected = true;
      joinTeam(teamName);

      print('WebSocket connected successfully');
    } catch (e) {
      print('Error connecting to WebSocket: $e');
      _isConnected = false;
      _scheduleReconnect();
    }
  }

  // Join team message
  void joinTeam(String teamName) {
    if (!_isConnected || _channel == null) {
      print('Cannot join team: WebSocket not connected');
      return;
    }

    try {
      _channel!.sink.add(jsonEncode({
        'type': 'joinTeam',
        'teamName': teamName,
      }));

      // If user is authenticated, also register the email
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _channel!.sink.add(jsonEncode({
          'type': 'join',
          'teamName': teamName,
          'email': user.email,
        }));
      }
    } catch (e) {
      print('Error joining team: $e');
      _isConnected = false;
      _scheduleReconnect();
    }
  }

  // Send a message through the WebSocket
  void send(Map<String, dynamic> message) {
    if (!_isConnected || _channel == null) {
      print('Cannot send message: WebSocket not connected');
      connect(_connectedTeam ?? '');
      return;
    }

    _channel!.sink.add(jsonEncode(message));
  }

  // Schedule reconnection
  void _scheduleReconnect() {
    // Cancel any existing reconnect timer
    _reconnectTimer?.cancel();

    // Only schedule a reconnect if we have active listeners
    if (_listenersCount > 0 && _connectedTeam != null) {
      _reconnectTimer = Timer(const Duration(seconds: 3), () {
        connect(_connectedTeam!);
      });
    }
  }

  // Register a listener
  void addListener() {
    _listenersCount++;
    // If we have our first listener, ensure connection is active
    if (_listenersCount == 1 && _connectedTeam != null && !_isConnected) {
      connect(_connectedTeam!);
    }
  }

  // Unregister a listener
  void removeListener() {
    if (_listenersCount > 0) {
      _listenersCount--;
    }

    // If no more listeners, we can close the connection to save resources
    if (_listenersCount == 0) {
      disconnect();
    }
  }

  // Disconnect WebSocket
  void disconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
    }
    _isConnected = false;
    print('WebSocket disconnected');
  }

  // Close the service when app is terminated
  void dispose() {
    disconnect();
    _messageController.close();
  }
}
