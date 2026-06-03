import 'package:socket_io_client/socket_io_client.dart' as IO;

class ChatSocketService {
  static final ChatSocketService _instance = ChatSocketService._internal();
  factory ChatSocketService() => _instance;
  ChatSocketService._internal();

  IO.Socket? _socket;

  bool get isConnected => _socket?.connected ?? false;

  void connect(String serverUrl) {
    if (isConnected) return;
    _socket = IO.io(
      serverUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setTimeout(5000)
          .build(),
    );
    _socket!.connect();
  }

  void joinConversation(String conversationId) =>
      _socket?.emit('join_conversation', conversationId);

  void leaveConversation(String conversationId) =>
      _socket?.emit('leave_conversation', conversationId);

  void joinSellerRoom(String sellerId) =>
      _socket?.emit('join_seller_room', sellerId);

  void leaveSellerRoom(String sellerId) =>
      _socket?.emit('leave_seller_room', sellerId);

  void emitMessage(Map<String, dynamic> data) =>
      _socket?.emit('send_message', data);

  void emitTyping(String conversationId, String senderId) =>
      _socket?.emit('typing', {
        'conversationId': conversationId,
        'senderId': senderId,
      });

  void emitStopTyping(String conversationId, String senderId) =>
      _socket?.emit('stop_typing', {
        'conversationId': conversationId,
        'senderId': senderId,
      });

  void emitSeen(String conversationId) =>
      _socket?.emit('message_seen', {'conversationId': conversationId});

  void on(String event, Function(dynamic) callback) =>
      _socket?.on(event, callback);

  void off(String event) => _socket?.off(event);
}
