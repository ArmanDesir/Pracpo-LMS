import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../models/lesson.dart';
import '../providers/lesson_provider.dart';

class CreateLessonScreen extends StatefulWidget {
  final String classroomId;

  const CreateLessonScreen({super.key, required this.classroomId});

  @override
  State<CreateLessonScreen> createState() => _CreateLessonScreenState();
}

class _CreateLessonScreenState extends State<CreateLessonScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _youtubeController = TextEditingController();

  File? _selectedFile;
  String? _selectedFileName;
  final now = DateTime.now();
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    final lessonProvider = Provider.of<LessonProvider>(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text('Create Lesson')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Lesson Title'),
                validator: (value) =>
                value == null || value.isEmpty ? 'Enter a title' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _youtubeController,
                decoration: const InputDecoration(
                    labelText: 'YouTube Video URL (optional)'),
              ),
              const SizedBox(height: 16),
              Text('Attach Document / PDF', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedFileName ?? 'No file selected',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _pickFile,
                    child: const Text('Select File'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isUploading ? null : () async {
                  if (!_formKey.currentState!.validate()) return;
                  if (_selectedFile == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select a file.')),
                    );
                    return;
                  }

                  setState(() => _isUploading = true);

                  try {
                    final (uploadedUrl, storagePath) = await lessonProvider.uploadLessonFile(_selectedFile!, widget.classroomId);
                    final lesson = Lesson(
                      title: _titleController.text,
                      description: _descController.text,
                      classroomId: widget.classroomId,
                      fileUrl: uploadedUrl,
                      storagePath: storagePath,
                      fileName: _selectedFileName!,
                      youtubeUrl: _youtubeController.text.isNotEmpty
                          ? _youtubeController.text
                          : null,
                      createdAt: now,
                      updatedAt: now,
                    );

                    await lessonProvider.createLesson(lesson);
                    Navigator.pop(context, true);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to create lesson: $e')),
                    );
                  } finally {
                    setState(() => _isUploading = false);
                  }
                },
                child: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Create Lesson'),
              ),

              if (lessonProvider.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    lessonProvider.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _selectedFileName = result.files.single.name;
      });
    }
  }
}
