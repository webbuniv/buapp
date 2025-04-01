import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/chat.dart';
import '../../models/profile.dart';
import '../../screens/messages/chat_screen.dart';
import '../../widgets/chat_list_item.dart';
import '../../utils/date_formatter.dart';

class MessagesTab extends StatefulWidget {
  const MessagesTab({super.key});

  @override
  State<MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends State<MessagesTab> with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late TabController _tabController;
  List<Chat> _chats = [];
  List<Profile> _contacts = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    
    // Subscribe to realtime updates
    _subscribeToChats();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _supabase.removeAllChannels();
    super.dispose();
  }
  
  void _subscribeToChats() {
    final userId = _supabase.auth.currentUser!.id;
    
    _supabase
      .channel('public:messages')
      .on(
        RealtimeListenTypes.postgresChanges,
        SupabaseRealtimePayload(
          schema: 'public',
          table: 'messages',
          filter: 'recipient_id=eq.$userId',
        ),
        (payload, [ref]) {
          _loadData();
        },
      )
      .subscribe();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userId = _supabase.auth.currentUser!.id;
      
      // Load chats
      final chatsData = await _supabase.rpc(
        'get_recent_chats',
        params: {
          'user_id': userId,
        },
      );
      
      // Load contacts
      final contactsData = await _supabase
        .from('profiles')
        .select('*')
        .neq('id', userId);
      
      if (mounted) {
        setState(() {
          _chats = chatsData.map<Chat>((data) => Chat.fromJson(data)).toList();
          _contacts = contactsData.map<Profile>((data) => Profile.fromJson(data)).toList();
          _isLoading = false;
        });
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
  
  void _filterItems(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }
  
  List<Chat> get _filteredChats {
    if (_searchQuery.isEmpty) {
      return _chats;
    }
    
    return _chats.where((chat) {
      return chat.otherUserName.toLowerCase().contains(_searchQuery);
    }).toList();
  }
  
  List<Profile> get _filteredContacts {
    if (_searchQuery.isEmpty) {
      return _contacts;
    }
    
    return _contacts.where((contact) {
      return contact.fullName.toLowerCase().contains(_searchQuery) ||
          (contact.email?.toLowerCase().contains(_searchQuery) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Chats'),
            Tab(text: 'Contacts'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterItems('');
                        },
                      )
                    : null,
              ),
              onChanged: _filterItems,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // Chats tab
                      _filteredChats.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.chat_bubble_outline,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchQuery.isNotEmpty
                                        ? 'No chats match your search'
                                        : 'No conversations yet',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _filteredChats.length,
                              itemBuilder: (context, index) {
                                final chat = _filteredChats[index];
                                return ChatListItem(
                                  avatarUrl: chat.otherUserAvatarUrl,
                                  name: chat.otherUserName,
                                  lastMessage: chat.lastMessage,
                                  time: DateFormatter.formatChatTime(chat.lastMessageTime),
                                  unreadCount: chat.unreadCount,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChatScreen(
                                          otherUserId: chat.otherUserId,
                                          otherUserName: chat.otherUserName,
                                        ),
                                      ),
                                    ).then((_) => _loadData());
                                  },
                                );
                              },
                            ),
                      
                      // Contacts tab
                      _filteredContacts.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.people_outline,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchQuery.isNotEmpty
                                        ? 'No contacts match your search'
                                        : 'No contacts available',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _filteredContacts.length,
                              itemBuilder: (context, index) {
                                final contact = _filteredContacts[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: contact.avatarUrl != null && contact.avatarUrl!.isNotEmpty
                                        ? NetworkImage(contact.avatarUrl!)
                                        : null,
                                    child: contact.avatarUrl == null || contact.avatarUrl!.isEmpty
                                        ? Text(contact.fullName[0])
                                        : null,
                                  ),
                                  title: Text(contact.fullName),
                                  subtitle: Text(contact.role),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChatScreen(
                                          otherUserId: contact.id,
                                          otherUserName: contact.fullName,
                                        ),
                                      ),
                                    ).then((_) => _loadData());
                                  },
                                );
                              },
                            ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

