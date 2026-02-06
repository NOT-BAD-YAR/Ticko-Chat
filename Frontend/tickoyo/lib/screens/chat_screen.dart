import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'dart:convert';
import '../store/auth_provider.dart';
import '../store/chat_provider.dart';
import '../services/socket_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<dynamic> _messages = [];
  bool _isLoading = false;
  bool _isUploading = false;
  String? _chatId;
  String? _lastUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final chatProvider = Provider.of<ChatProvider>(context);
    final user = chatProvider.selectedUser;

    if (user != null && user['_id'] != _lastUserId) {
      _lastUserId = user['_id'];
      _messages = []; // Clear previous messages
      _chatId = null;
      _initializeChat(user['_id']);
    }
  }

  Future<void> _initializeChat(String userId) async {
    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final socketService = Provider.of<SocketService>(context, listen: false);

      // Access/Create Chat
      final chatRes = await http.post(
        Uri.parse(kIsWeb ? 'http://localhost:5000/api/chat' : 'http://10.0.2.2:5000/api/chat'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${auth.token}',
        },
        body: json.encode({'userId': userId}),
      );

      if (chatRes.statusCode == 200) {
        final chatData = json.decode(chatRes.body);
        _chatId = chatData['_id'];
        
        // Join Chat Room
        socketService.emit('join chat', _chatId);

        // Fetch Messages
        final msgRes = await http.get(
          Uri.parse(kIsWeb 
            ? 'http://localhost:5000/api/message/$_chatId' 
            : 'http://10.0.2.2:5000/api/message/$_chatId'),
           headers: {
            'Authorization': 'Bearer ${auth.token}',
          },
        );

        if (msgRes.statusCode == 200) {
          if (mounted) {
            setState(() {
              _messages = json.decode(msgRes.body);
              _isLoading = false;
            });
            _scrollToBottom();
          }
        }
      }
      
      // Listen for new messages
      // Note: In a real app, manage listener lifecycle better to avoid duplicates
      socketService.off('message received'); // clear previous listeners safely?
      socketService.on('message received', (newMessage) {
        if (mounted && newMessage['chat']['_id'] == _chatId) {
          setState(() {
            _messages.add(newMessage);
          });
          _scrollToBottom();
        }
      });

    } catch (e) {
      print('Error initializing chat: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndSendImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      _uploadAndSendImage(image);
    }
  }

  Future<void> _uploadAndSendImage(XFile file) async {
    if (_chatId == null) return;
    setState(() => _isUploading = true);
    
    try {
      final uri = Uri.parse(kIsWeb 
          ? 'http://localhost:5000/api/upload' 
          : 'http://10.0.2.2:5000/api/upload');

      final request = http.MultipartRequest('POST', uri);
      final bytes = await file.readAsBytes();
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'file', 
          bytes,
          filename: file.name,
        )
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final imageUrl = data['url'];
        await _sendMessage(content: imageUrl, type: 'image');
      } else {
        throw Exception('Failed to upload image');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending image: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _sendMessage({String? content, String type = 'text'}) async {
    if ((content == null && _messageController.text.trim().isEmpty) || _chatId == null) return;

    final msgContent = content ?? _messageController.text;
    if (type == 'text') _messageController.clear();
    
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final socketService = Provider.of<SocketService>(context, listen: false);

      final res = await http.post(
        Uri.parse(kIsWeb 
            ? 'http://localhost:5000/api/message' 
            : 'http://10.0.2.2:5000/api/message'),
        headers: {
           'Content-Type': 'application/json',
           'Authorization': 'Bearer ${auth.token}',
        },
        body: json.encode({
          'content': msgContent,
          'chatId': _chatId,
          'type': type,
        }),
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        socketService.emit('new message', data);
        if (mounted) {
          setState(() {
            _messages.add(data);
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    final dt = DateTime.parse(timestamp).toLocal();
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final selectedUser = chatProvider.selectedUser;
    final auth = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);

    if (selectedUser == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: theme.disabledColor),
            const SizedBox(height: 16),
            Text('Select a user from Home to start chatting', style: TextStyle(color: theme.disabledColor)),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: (selectedUser['profilePic'] != null && selectedUser['profilePic'].startsWith('http'))
                  ? NetworkImage(selectedUser['profilePic'])
                  : null,
              onBackgroundImageError: (_, __) {},
              child: (selectedUser['profilePic'] == null || !selectedUser['profilePic'].startsWith('http'))
                  ? Text((selectedUser['fullName']?[0] ?? 'U').toUpperCase())
                  : null,
            ),
            const SizedBox(width: 10),
            Text(selectedUser['fullName'] ?? 'Chat'),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
             chatProvider.setTabIndex(0); // Go back to Home
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator()) 
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final isMe = msg['sender']['_id'] == auth.user?['_id'] || msg['sender'] == auth.user?['_id'];
                    final isImage = msg['type'] == 'image';
                    final time = _formatTime(msg['createdAt']);
                    
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? theme.primaryColor : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(20),
                            topRight: const Radius.circular(20),
                            bottomLeft: isMe ? const Radius.circular(20) : Radius.zero,
                            bottomRight: isMe ? Radius.zero : const Radius.circular(20),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (isImage)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  msg['content'],
                                  height: 200,
                                  width: 200,
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image),
                                  loadingBuilder: (ctx, child, progress) {
                                      if (progress == null) return child;
                                      return Container(
                                        height: 200, width: 200,
                                        color: Colors.black12,
                                        child: const Center(child: CircularProgressIndicator()),
                                      );
                                  },
                                ),
                              )
                            else
                              Text(
                                msg['content'] ?? '',
                                style: TextStyle(
                                  color: isMe ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                                  fontSize: 16,
                                ),
                              ),
                             const SizedBox(height: 4),
                             Text(
                               time,
                               style: TextStyle(
                                 fontSize: 10,
                                 color: isMe ? theme.colorScheme.onPrimary.withOpacity(0.7) : theme.colorScheme.onSurface.withOpacity(0.6),
                               ),
                             ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ),
          if (_isUploading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: (_isLoading || _isUploading) ? null : _pickAndSendImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                      filled: true,
                      fillColor: theme.cardColor,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: theme.primaryColor,
                  onPressed: (_isLoading || _isUploading) ? () => _sendMessage() : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
