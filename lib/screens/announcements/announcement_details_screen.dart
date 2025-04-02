import 'package:flutter/material.dart';
import '../../models/announcement.dart';
import '../../utils/date_formatter.dart';

class AnnouncementDetailsScreen extends StatelessWidget {
  final Announcement announcement;

  const AnnouncementDetailsScreen({
    super.key,
    required this.announcement,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcement'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              announcement.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  'Posted by ${announcement.authorName}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  DateFormatter.formatDate(announcement.createdAt),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              announcement.content,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),
            if (announcement.attachments != null && announcement.attachments!.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Attachments',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...announcement.attachments!.map((attachment) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.attach_file),
                      title: Text(attachment.split('/').last),
                      trailing: const Icon(Icons.download),
                      onTap: () {
                        // Download or open attachment
                      },
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

