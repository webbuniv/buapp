import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/course.dart';
import '../../utils/constants.dart';
import '../../widgets/course_card.dart';
import '../../screens/courses/course_details_screen.dart';

class CoursesTab extends StatefulWidget {
  final String userRole;
  
  const CoursesTab({
    super.key,
    required this.userRole,
  });

  @override
  State<CoursesTab> createState() => _CoursesTabState();
}

class _CoursesTabState extends State<CoursesTab> {
  final _supabase = Supabase.instance.client;
  List<Course> _courses = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userId = _supabase.auth.currentUser!.id;
      List<dynamic> coursesData;
      
      if (widget.userRole == Constants.roleStudent) {
        // For students, get enrolled courses
        final enrollments = await _supabase
            .from('enrollments')
            .select('course_id')
            .eq('student_id', userId);
        
        final courseIds = enrollments.map((e) => e['course_id']).toList();
        
        if (courseIds.isEmpty) {
          coursesData = [];
        } else {
          coursesData = await _supabase
              .from('courses')
              .select('*')
              .in_('id', courseIds);
        }
      } else if (widget.userRole == Constants.roleLecturer) {
        // For lecturers, get courses they teach
        coursesData = await _supabase
            .from('courses')
            .select('*')
            .eq('lecturer_id', userId);
      } else {
        // For staff, get all courses
        coursesData = await _supabase
            .from('courses')
            .select('*');
      }
      
      if (mounted) {
        setState(() {
          _courses = coursesData
              .map((data) => Course.fromJson(data))
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
            content: Text('Failed to load courses'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterCourses(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  List<Course> get _filteredCourses {
    if (_searchQuery.isEmpty) {
      return _courses;
    }
    
    return _courses.where((course) {
      return course.title.toLowerCase().contains(_searchQuery) ||
          course.code.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Courses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCourses,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search courses',
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
                          _filterCourses('');
                        },
                      )
                    : null,
              ),
              onChanged: _filterCourses,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCourses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.school_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No courses match your search'
                                  : widget.userRole == Constants.roleStudent
                                      ? 'You are not enrolled in any courses'
                                      : widget.userRole == Constants.roleLecturer
                                          ? 'You are not teaching any courses'
                                          : 'No courses available',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredCourses.length,
                        itemBuilder: (context, index) {
                          final course = _filteredCourses[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: CourseCard(
                              course: course,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CourseDetailsScreen(
                                      course: course,
                                      userRole: widget.userRole,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: widget.userRole == Constants.roleStudent
          ? FloatingActionButton(
              onPressed: () {
                // Navigate to course enrollment screen
              },
              child: const Icon(Icons.add),
              tooltip: 'Enroll in a course',
            )
          : widget.userRole == Constants.roleLecturer || widget.userRole == Constants.roleStaff
              ? FloatingActionButton(
                  onPressed: () {
                    // Navigate to create course screen
                  },
                  child: const Icon(Icons.add),
                  tooltip: 'Create a course',
                )
              : null,
    );
  }
}

