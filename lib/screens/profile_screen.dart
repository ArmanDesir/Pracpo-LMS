import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pracpro/services/user_service.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user.dart' as app_model;
import '../providers/auth_provider.dart';
import 'teacher_profile_screen.dart';

/// ===============================================================
/// EDIT STUDENT SCREEN (STUDENT ONLY)
/// ===============================================================

class EditStudentScreen extends StatefulWidget {
  final app_model.User student;
  const EditStudentScreen({super.key, required this.student});

  @override
  State<EditStudentScreen> createState() => _EditStudentScreenState();
}

class _EditStudentScreenState extends State<EditStudentScreen> {
  late TextEditingController guardianNameController;
  late TextEditingController guardianEmailController;
  late TextEditingController guardianContactController;
  late TextEditingController studentInfoController;

  @override
  void initState() {
    super.initState();
    guardianNameController =
        TextEditingController(text: widget.student.guardianName);
    guardianEmailController =
        TextEditingController(text: widget.student.guardianEmail);
    guardianContactController =
        TextEditingController(text: widget.student.guardianContactNumber);
    studentInfoController =
        TextEditingController(text: widget.student.studentInfo);
  }

  @override
  void dispose() {
    guardianNameController.dispose();
    guardianEmailController.dispose();
    guardianContactController.dispose();
    studentInfoController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final updated = widget.student.copyWith(
      guardianName: guardianNameController.text,
      guardianEmail: guardianEmailController.text,
      guardianContactNumber: guardianContactController.text,
      studentInfo: studentInfoController.text,
    );

    await UserService().updateUser(updated);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Student')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            TextField(
              controller: guardianNameController,
              decoration: const InputDecoration(labelText: 'Guardian Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: guardianEmailController,
              decoration: const InputDecoration(labelText: 'Guardian Email'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: guardianContactController,
              decoration: const InputDecoration(labelText: 'Guardian Contact'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: studentInfoController,
              decoration: const InputDecoration(labelText: 'Student Info'),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

/// ===============================================================
/// PROFILE ROUTER (DECIDES TEACHER OR STUDENT)
/// ===============================================================

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = ModalRoute.of(context)?.settings.arguments as String?;
    final authProvider = Provider.of<AuthProvider>(context);

    /// ===========================================================
    /// VIEWING OWN PROFILE
    /// ===========================================================
    if (userId == null) {
      final user = authProvider.currentUser;

      if (user == null) {
        return const Scaffold(
          body: Center(child: Text('No user data available')),
        );
      }

      // ✅ TEACHER PROFILE
      if (user.userType == app_model.UserType.teacher) {
        return TeacherProfileScreen(teacher: user);
      }

      // ✅ STUDENT PROFILE
      return _StudentProfileScaffold(
        user: user,
        loggedInUser: user,
        isTeacherViewer: false,
      );
    }

    /// ===========================================================
    /// VIEWING ANOTHER USER PROFILE
    /// ===========================================================
    return FutureBuilder<app_model.User?>(
      future: UserService().getUser(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('No user data available')),
          );
        }

        final loggedInUser = authProvider.currentUser;

        // ✅ VIEWING A TEACHER
        if (user.userType == app_model.UserType.teacher) {
          return TeacherProfileScreen(teacher: user);
        }

        // ✅ VIEWING A STUDENT
        return _StudentProfileScaffold(
          user: user,
          loggedInUser: loggedInUser,
          isTeacherViewer:
          loggedInUser?.userType == app_model.UserType.teacher,
        );
      },
    );
  }
}

/// ===============================================================
/// STUDENT PROFILE (STUDENT DATA ONLY)
/// ===============================================================

class _StudentProfileScaffold extends StatefulWidget {
  final app_model.User user;
  final app_model.User? loggedInUser;
  final bool isTeacherViewer;

  const _StudentProfileScaffold({
    required this.user,
    required this.loggedInUser,
    required this.isTeacherViewer,
  });

  @override
  State<_StudentProfileScaffold> createState() =>
      _StudentProfileScaffoldState();
}

class _StudentProfileScaffoldState extends State<_StudentProfileScaffold> {
  void _editStudent(BuildContext context) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditStudentScreen(student: widget.user),
      ),
    );

    if (updated == true) {
      final refreshed = await UserService().getUser(widget.user.id);
      if (refreshed != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => _StudentProfileScaffold(
              user: refreshed,
              loggedInUser: widget.loggedInUser,
              isTeacherViewer: widget.isTeacherViewer,
            ),
          ),
        );
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    if (widget.loggedInUser?.id != widget.user.id) return;

    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image == null) return;

    final path =
        'avatars/${widget.user.id}_${DateTime.now().millisecondsSinceEpoch}.png';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await Supabase.instance.client.storage
          .from('pictures')
          .upload(path, File(image.path),
          fileOptions:
          const FileOptions(contentType: 'image/png', upsert: true));

      final url = Supabase.instance.client.storage
          .from('pictures')
          .getPublicUrl(path);

      await UserService().updateUser(
        widget.user.copyWith(photoUrl: url),
      );

      await Provider.of<AuthProvider>(context, listen: false)
          .refreshUserProfile();

      Navigator.pop(context);
    } catch (_) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwnProfile =
        widget.loggedInUser?.id == widget.user.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Profile'),
        actions: [
          if (widget.isTeacherViewer && !isOwnProfile)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editStudent(context),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            Center(
              child: GestureDetector(
                onTap: isOwnProfile ? _pickAndUploadImage : null,
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: widget.user.photoUrl != null
                      ? NetworkImage(widget.user.photoUrl!)
                      : null,
                  child: widget.user.photoUrl == null
                      ? const Icon(Icons.school, size: 40)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _ProfileField(label: 'Full Name', value: widget.user.name),
            const SizedBox(height: 16),
            _ProfileField(
              label: 'Student LRN',
              value: widget.user.studentId ?? 'N/A',
            ),
            const SizedBox(height: 16),
            _ProfileField(
              label: 'Guardian Name',
              value: widget.user.guardianName ?? 'N/A',
            ),
            const SizedBox(height: 16),
            _ProfileField(
              label: 'Guardian Email',
              value: widget.user.guardianEmail ?? 'N/A',
            ),
            const SizedBox(height: 16),
            _ProfileField(
              label: 'Guardian Contact Number',
              value: widget.user.guardianContactNumber ?? 'N/A',
            ),
          ],
        ),
      ),
    );
  }
}

/// ===============================================================
/// SHARED PROFILE FIELD
/// ===============================================================

class _ProfileField extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding:
          const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style:
            const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
