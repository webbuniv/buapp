import 'package:flutter/material.dart';
import '../../models/course.dart';
import '../../utils/constants.dart';

class CourseDetailsScreen extends StatefulWidget {
  final Course course;
  final String userRole;

  const CourseDetailsScreen({
    super.key,
    required this.course,
    required this.userRole,
  });

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course.code),
        actions: [
          if (widget.userRole == Constants.roleLecturer || widget.userRole == Constants.roleStaff)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // Navigate to edit course screen
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.course.imageUrl != null && widget.course.imageUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        widget.course.imageUrl!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    widget.course.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.course.code,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.tertiaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${widget.course.credits} Credits',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.tertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.course.description,
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Lecturer',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      child: Text(widget.course.lecturerName[0]),
                    ),
                    title: Text(widget.course.lecturerName),
                    subtitle: const Text('Course Instructor'),
                  ),
                  const SizedBox(height: 24),
                  // Add more sections like materials, assignments, etc.
                ],
              ),
            ),
      floatingActionButton: widget.userRole == Constants.roleStudent
          ? FloatingActionButton.extended(
              onPressed: () {
                // Action for students (e.g., submit assignment)
              },
              icon: const Icon(Icons.assignment_turned_in),
              label: const Text('Submit Assignment'),
            )
          : widget.userRole == Constants.roleLecturer
              ? FloatingActionButton.extended(
                  onPressed: () {
                    // Action for lecturers (e.g., add material)
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Material'),
                )
              : null,
    );
  }
}

