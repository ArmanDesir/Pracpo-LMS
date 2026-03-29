import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user.dart' as app_model;
import '../providers/auth_provider.dart';
import '../services/user_service.dart';

class TeacherProfileScreen extends StatelessWidget {
  final app_model.User teacher;

  const TeacherProfileScreen({
    super.key,
    required this.teacher,
  });

  Future<void> _pickAndUploadImage(BuildContext context) async {
    final authProvider =
    Provider.of<AuthProvider>(context, listen: false);

    // 🔒 Only allow own profile upload
    if (authProvider.currentUser?.id != teacher.id) return;

    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image == null) return;

    final path =
        'avatars/${teacher.id}_${DateTime.now().millisecondsSinceEpoch}.png';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await Supabase.instance.client.storage
          .from('pictures')
          .upload(
        path,
        File(image.path),
        fileOptions:
        const FileOptions(upsert: true, contentType: 'image/png'),
      );

      final publicUrl = Supabase.instance.client.storage
          .from('pictures')
          .getPublicUrl(path);

      final updated = teacher.copyWith(photoUrl: publicUrl);
      await UserService().updateUser(updated);

      await authProvider.refreshUserProfile();

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated')),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authUser = Provider.of<AuthProvider>(context).currentUser;
    final isOwnProfile = authUser?.id == teacher.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Profile'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            Center(
              child: GestureDetector(
                onTap: isOwnProfile ? () => _pickAndUploadImage(context) : null,
                child: CircleAvatar(
                  radius: 42,
                  backgroundColor: Colors.blue.shade100,
                  backgroundImage: teacher.photoUrl != null
                      ? NetworkImage(teacher.photoUrl!)
                      : null,
                  child: teacher.photoUrl == null
                      ? const Icon(
                    Icons.person,
                    size: 46,
                    color: Colors.blue,
                  )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _ProfileField(label: 'Full Name', value: teacher.name),
            const SizedBox(height: 16),
            _ProfileField(label: 'Email', value: teacher.email ?? 'N/A'),
          ],
        ),
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileField({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
