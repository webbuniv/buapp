import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Avatar extends StatefulWidget {
  final String? imageUrl;
  final Function(String) onUpload;

  const Avatar({
    super.key,
    this.imageUrl,
    required this.onUpload,
  });

  @override
  State<Avatar> createState() => _AvatarState();
}

class _AvatarState extends State<Avatar> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;

  Future<void> _upload() async {
    final picker = ImagePicker();
    final imageFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 300,
      maxHeight: 300,
    );

    if (imageFile == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _supabase.auth.currentUser!.id;
      final fileExt = imageFile.path.split('.').last;
      final fileName = '$userId-${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = await imageFile.readAsBytes();
      
      final response = await _supabase
          .storage
          .from('avatars')
          .uploadBinary(
            fileName,
            filePath,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );

      final imageUrlResponse = _supabase
          .storage
          .from('avatars')
          .getPublicUrl(fileName);

      widget.onUpload(imageUrlResponse);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error uploading image'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_isLoading)
          const CircularProgressIndicator()
        else
          GestureDetector(
            onTap: _upload,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
                image: widget.imageUrl != null && widget.imageUrl!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(widget.imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: widget.imageUrl == null || widget.imageUrl!.isEmpty
                  ? const Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.grey,
                    )
                  : null,
            ),
          ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _upload,
          icon: const Icon(Icons.upload),
          label: const Text('Change Photo'),
        ),
      ],
    );
  }
}

