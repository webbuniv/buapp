import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/chat_message.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/custom_text_field.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _supabase = Supabase.instance.client;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    if (_messages.isEmpty) {
      setState(() {
        _messages.add(
          ChatMessage(
            id: 'welcome',
            senderId: 'bot',
            content: 'Hello! I\'m your Bugema University assistant. How can I help you today?',
            timestamp: DateTime.now(),
            isRead: true,
          ),
        );
      });
    }
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userId = _supabase.auth.currentUser!.id;
      final data = await _supabase
          .from('chatbot_messages')
          .select()
          .eq('user_id', userId)
          .order('timestamp', ascending: true);
      
      if (mounted) {
        setState(() {
          _messages.clear();
          _messages.addAll(
            data.map((message) => ChatMessage.fromJson(message)).toList(),
          );
          _isLoading = false;
        });
        
        _addWelcomeMessage();
        _scrollToBottom();
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load messages'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    
    final userId = _supabase.auth.currentUser!.id;
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: userId,
      content: message,
      timestamp: DateTime.now(),
      isRead: true,
    );
    
    setState(() {
      _messages.add(userMessage);
      _messageController.clear();
      _isLoading = true;
    });
    
    _scrollToBottom();
    
    try {
      // Save user message to database
      await _supabase.from('chatbot_messages').insert({
        'user_id': userId,
        'sender_id': userId,
        'content': message,
        'timestamp': userMessage.timestamp.toIso8601String(),
        'is_read': true,
      });
      
      // Simulate AI response
      await Future.delayed(const Duration(seconds: 1));
      
      final botResponse = _generateBotResponse(message);
      final botMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: 'bot',
        content: botResponse,
        timestamp: DateTime.now(),
        isRead: true,
      );
      
      // Save bot message to database
      await _supabase.from('chatbot_messages').insert({
        'user_id': userId,
        'sender_id': 'bot',
        'content': botResponse,
        'timestamp': botMessage.timestamp.toIso8601String(),
        'is_read': true,
      });
      
      if (mounted) {
        setState(() {
          _messages.add(botMessage);
          _isLoading = false;
        });
        
        _scrollToBottom();
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send message'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _generateBotResponse(String message) {
    final lowerMessage = message.toLowerCase();
    
    if (lowerMessage.contains('hello') || 
        lowerMessage.contains('hi') || 
        lowerMessage.contains('hey')) {
      return 'Hello! How can I assist you today?';
    } else if (lowerMessage.contains('course') && 
               (lowerMessage.contains('register') || lowerMessage.contains('enroll'))) {
      return 'To register for courses, go to the Courses tab and tap the + button to see available courses. You can then enroll in the courses you need.';
    } else if (lowerMessage.contains('fee') || lowerMessage.contains('payment')) {
      return 'For fee payments, go to the Home tab, tap on "Fees" in the Quick Actions section. You can view your balance and make payments through mobile money or bank transfer.';
    } else if (lowerMessage.contains('library')) {
      return 'The university library is open from 8:00 AM to 10:00 PM on weekdays, and 9:00 AM to 5:00 PM on weekends. You can access digital resources through the Library section in the app.';
    } else if (lowerMessage.contains('exam') || lowerMessage.contains('test')) {
      return 'Exam schedules are posted in the Calendar section. You can also check your course details for specific exam dates and requirements.';
    } else if (lowerMessage.contains('contact') && 
               (lowerMessage.contains('lecturer') || lowerMessage.contains('professor'))) {
      return 'You can contact your lecturers through the Messages tab. Select the Contacts tab to find your lecturer and start a conversation.';
    } else if (lowerMessage.contains('wifi') || lowerMessage.contains('internet')) {
      return 'The university provides free WiFi access across campus. Connect to "Bugema_WiFi" network and use your student credentials to log in.';
    } else if (lowerMessage.contains('thank')) {
      return 'You\'re welcome! Feel free to ask if you need any other assistance.';
    } else {
      return 'I\'m not sure I understand your question. Could you please rephrase or ask something else about courses, fees, library, exams, or contacting staff?';
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
        title: const Text('AI Assistant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMessages,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Text('No messages yet'),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isUser = message.senderId != 'bot';
                      
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
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(),
            ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
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

