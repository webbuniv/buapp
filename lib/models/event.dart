class Event {
  final String id;
  final String title;
  final String description;
  final DateTime eventDate;
  final String location;
  final String organizerId;
  final String organizerName;
  final String? imageUrl;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.eventDate,
    required this.location,
    required this.organizerId,
    required this.organizerName,
    this.imageUrl,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      eventDate: DateTime.parse(json['event_date'] as String),
      location: json['location'] as String,
      organizerId: json['organizer_id'] as String,
      organizerName: json['organizer_name'] as String,
      imageUrl: json['image_url'] as String?,
    );
  }
}

