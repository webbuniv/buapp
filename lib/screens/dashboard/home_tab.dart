import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/announcement.dart';
import '../../models/event.dart';
import '../../utils/constants.dart';
import '../../widgets/announcement_card.dart';
import '../../widgets/event_card.dart';
import '../../widgets/quick_action_button.dart';
import '../../screens/announcements/announcement_details_screen.dart';
import '../../screens/events/event_details_screen.dart';
import '../../screens/chatbot/chatbot_screen.dart';

class HomeTab extends StatefulWidget {
  final String userRole;

  const HomeTab({
    super.key,
    required this.userRole,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final _supabase = Supabase.instance.client;
  List<Announcement> _announcements = [];
  List<Event> _events = [];
  bool _isLoading = true;
  String _userName = '';
  String _greeting = '';

  @override
  void initState() {
    super.initState();
    _loadData();
    _setGreeting();
  }

  void _setGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      _greeting = 'Good Morning';
    } else if (hour < 17) {
      _greeting = 'Good Afternoon';
    } else {
      _greeting = 'Good Evening';
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Load user profile
      final userId = _supabase.auth.currentUser!.id;
      final userData = await _supabase
          .from('profiles')
          .select('full_name')
          .eq('id', userId)
          .single();
      
      // Load announcements
      final announcementsData = await _supabase
          .from('announcements')
          .select('*')
          .order('created_at', ascending: false)
          .limit(5);
      
      // Load events
      final eventsData = await _supabase
          .from('events')
          .select('*')
          .gte('event_date', DateTime.now().toIso8601String())
          .order('event_date')
          .limit(5);
    
      if (mounted) {
        setState(() {
          _userName = userData['full_name'] as String;
          _announcements = announcementsData
              .map((data) => Announcement.fromJson(data))
              .toList();
          _events = eventsData
              .map((data) => Event.fromJson(data))
              .toList();
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load data'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 180,
                    pinned: true,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.primaryContainer,
                            ],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                '$_greeting,',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _userName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      title: const Text('Bugema University'),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        onPressed: () {
                          // Navigate to notifications
                        },
                      ),
                    ],
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Quick Actions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildQuickActions(),
                          const SizedBox(height: 24),
                          const Text(
                            'Announcements',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (_announcements.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(
                              child: Text('No announcements available'),
                            ),
                          );
                        }
                        
                        final announcement = _announcements[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 4.0,
                          ),
                          child: AnnouncementCard(
                            announcement: announcement,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AnnouncementDetailsScreen(
                                    announcement: announcement,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                      childCount: _announcements.isEmpty ? 1 : _announcements.length,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Upcoming Events',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (_events.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(
                              child: Text('No upcoming events'),
                            ),
                          );
                        }
                        
                        final event = _events[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 4.0,
                          ),
                          child: EventCard(
                            event: event,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EventDetailsScreen(
                                    event: event,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                      childCount: _events.isEmpty ? 1 : _events.length,
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 24),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ChatbotScreen(),
            ),
          );
        },
        tooltip: 'Chat with AI Assistant',
        child: const Icon(Icons.chat_bubble_outline),
      ),
    );
  }

  Widget _buildQuickActions() {
    final List<Map<String, dynamic>> actions = [];
    
    // Common actions for all roles
    actions.add({
      'icon': Icons.calendar_today,
      'label': 'Calendar',
      'onTap': () {
        // Navigate to calendar
      },
    });
    
    actions.add({
      'icon': Icons.library_books,
      'label': 'Library',
      'onTap': () {
        // Navigate to library
      },
    });
    
    // Role-specific actions
    if (widget.userRole == Constants.roleStudent) {
      actions.add({
        'icon': Icons.payment,
        'label': 'Fees',
        'onTap': () {
          // Navigate to fees
        },
      });
      
      actions.add({
        'icon': Icons.assignment,
        'label': 'Assignments',
        'onTap': () {
          // Navigate to assignments
        },
      });
    } else if (widget.userRole == Constants.roleLecturer) {
      actions.add({
        'icon': Icons.people,
        'label': 'Students',
        'onTap': () {
          // Navigate to students
        },
      });
      
      actions.add({
        'icon': Icons.assignment,
        'label': 'Assignments',
        'onTap': () {
          // Navigate to assignments
        },
      });
    } else if (widget.userRole == Constants.roleStaff) {
      actions.add({
        'icon': Icons.announcement,
        'label': 'Announcements',
        'onTap': () {
          // Navigate to announcements
        },
      });
      
      actions.add({
        'icon': Icons.event,
        'label': 'Events',
        'onTap': () {
          // Navigate to events
        },
      });
    }
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return QuickActionButton(
          icon: action['icon'],
          label: action['label'],
          onTap: action['onTap'],
        );
      },
    );
  }
}

