import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/chat_message.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/custom_text_field.dart';
import 'package:logging/logging.dart';

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _supabase = Supabase.instance.client;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _logger = Logger('ChatScreen');
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  late String _currentUserId;
  late RealtimeChannel _channel;

  @override
  void initState() {
    super.initState();
    _currentUserId = _supabase.auth.currentUser!.id;
    _loadMessages();
    _subscribeToMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _supabase.removeChannel(_channel);
    super.dispose();
  }

  void _subscribeToMessages() {
    _channel = _supabase.channel('private:messages:${widget.otherUserId}');
    
    _channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      callback: (payload) {
        final message = ChatMessage.fromJson(payload.newRecord);
        if ((message.senderId == _currentUserId && 
             message.recipientId == widget.otherUserId) ||
            (message.senderId == widget.otherUserId && 
             message.recipientId == _currentUserId)) {
          setState(() {
            _messages.add(message);
          });
          _scrollToBottom();
        }
      },
    ).subscribe();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final data = await _supabase
          .from('messages')
          .select()
          .or('sender_id.eq.$_currentUserId,recipient_id.eq.$_currentUserId')
          .or('sender_id.eq.${widget.otherUserId},recipient_id.eq.${widget.otherUserId}')
          .order('timestamp');
      
      if (mounted) {
        setState(() {
          _messages = data.map<ChatMessage>((item) => ChatMessage.fromJson(item)).toList();
          _isLoading = false;
        });
        
        // Mark messages as read
        _markMessagesAsRead();
        
        _scrollToBottom();
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading messages: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markMessagesAsRead() async {
    try {
      await _supabase
          .from('messages')
          .update({'is_read': true})
          .eq('recipient_id', _currentUserId)
          .eq('sender_id', widget.otherUserId);
    } catch (error) {
      _logger.warning('Error marking messages as read: $error');
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    
    _messageController.clear();
    
    try {
      final timestamp = DateTime.now().toIso8601String();
      
      await _supabase.from('messages').insert({
        'sender_id': _currentUserId,
        'recipient_id': widget.otherUserId,
        'content': message,
        'timestamp': timestamp,
        'is_read': false,
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUserName),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // Show user info
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(
                        child: Text('No messages yet. Start a conversation!'),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isUser = message.senderId == _currentUserId;
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ChatBubble(
                              message: message.content,
                              isUser: isUser,
                              time: message.timestamp,
                            ),
                          );
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 5,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _messageController,
                    hintText: 'Type a message...',
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  mini: true,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

