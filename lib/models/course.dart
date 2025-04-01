class Course {
  final String id;
  final String code;
  final String title;
  final String description;
  final String lecturerId;
  final String lecturerName;
  final int credits;
  final String? imageUrl;

  Course({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.lecturerId,
    required this.lecturerName,
    required this.credits,
    this.imageUrl,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as String,
      code: json['code'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      lecturerId: json['lecturer_id'] as String,
      lecturerName: json['lecturer_name'] as String,
      credits: json['credits'] as int,
      imageUrl: json['image_url'] as String?,
    );
  }
}

