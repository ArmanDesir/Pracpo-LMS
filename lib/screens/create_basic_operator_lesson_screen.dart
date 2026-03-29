import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/basic_operator_lesson.dart';
import '../providers/basic_operator_lesson_provider.dart';
import '../utils/youtube_utils.dart';

class CreateBasicOperatorLessonScreen extends StatefulWidget {
  final String operator;
  final String classroomId;
  final BasicOperatorLesson? existingLesson;

  const CreateBasicOperatorLessonScreen({
    super.key,
    required this.operator,
    required this.classroomId,
    this.existingLesson,
  });

  @override
  State<CreateBasicOperatorLessonScreen> createState() =>
      _CreateBasicOperatorLessonScreenState();
}

class _CreateBasicOperatorLessonScreenState
    extends State<CreateBasicOperatorLessonScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _youtubeUrlController = TextEditingController();

  File? _pdfFile;
  String? _pdfFileName;
  YoutubePlayerController? _youtubeController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    if (widget.existingLesson != null) {
      final lesson = widget.existingLesson!;
      _titleController.text = lesson.title;
      _descriptionController.text = lesson.description ?? '';
      _youtubeUrlController.text = lesson.youtubeUrl ?? '';
      _pdfFileName = lesson.fileName;

      if (lesson.youtubeUrl != null && lesson.youtubeUrl!.isNotEmpty) {
        _initializeYoutubePlayer(lesson.youtubeUrl!);
      }
    }
  }

  void _initializeYoutubePlayer(String url) {
    final videoId = YouTubeUtils.extractVideoId(url);
      setState(() {
        _youtubeController?.dispose();
      if (videoId != null && videoId.isNotEmpty) {
        // Validate video ID format (11 characters, alphanumeric with hyphens/underscores only)
        if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(videoId)) {
        _youtubeController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: false,
            mute: false,
          ),
        );
        } else {
          // Invalid video ID format - don't create controller
          _youtubeController = null;
        }
      } else {
        // No valid video ID extracted - clear controller
        _youtubeController = null;
    }
    });
  }

  Future<void> _pickPdfFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _pdfFile = File(result.files.single.path!);
        _pdfFileName = result.files.single.name;
      });
    }
  }

  Future<void> _saveLesson() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();

      String? normalizedYoutubeUrl;
      final youtubeUrlText = _youtubeUrlController.text.trim();
      if (youtubeUrlText.isNotEmpty) {
        normalizedYoutubeUrl = YouTubeUtils.normalizeUrl(youtubeUrlText) ?? youtubeUrlText;
      }

      final lesson = BasicOperatorLesson(
        operator: widget.operator,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        classroomId: widget.classroomId,
        youtubeUrl: normalizedYoutubeUrl,
        fileUrl: widget.existingLesson?.fileUrl ?? '',
        fileName: _pdfFileName ?? widget.existingLesson?.fileName,
        storagePath: widget.existingLesson?.storagePath,
        createdAt: widget.existingLesson?.createdAt ?? now,
      );

      final provider = Provider.of<BasicOperatorLessonProvider>(
        context,
        listen: false,
      );

      if (widget.existingLesson != null) {

        await provider.updateLesson(lesson);
      } else if (_pdfFile != null) {

        await provider.createLessonWithFile(lesson, _pdfFile!);
      } else {

        await provider.createLesson(lesson);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lesson saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back to the operator action selection screen (teacher management view)
      // Teachers should return to the management screen, not the student-facing module page
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save lesson: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getLessonTitle() {
    final title = _titleController.text.trim();
    if (title.isNotEmpty) {
      return title.toUpperCase();
    }

    return 'CREATE LESSON - ${_getOperatorDisplayName().toUpperCase()}';
  }

  String _getOperatorDisplayName() {
    switch (widget.operator.toLowerCase()) {
      case 'addition':
        return 'Addition';
      case 'subtraction':
        return 'Subtraction';
      case 'multiplication':
        return 'Multiplication';
      case 'division':
        return 'Division';
      default:
        return widget.operator.toUpperCase();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _youtubeUrlController.dispose();
    _youtubeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          _getLessonTitle(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.grey[100],
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const Text(
                'TITLE',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Enter lesson title (e.g., Introduction in Addition)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {});
                },
              ),
              const SizedBox(height: 24),

              const Text(
                'DESCRIPTION',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Enter lesson description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Description is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              const Text(
                'YOUTUBE PREVIEW/PLACEHOLDER',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _youtubeController != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: YoutubePlayer(
                          controller: _youtubeController!,
                          showVideoProgressIndicator: true,
                        ),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.play_circle_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'YouTube preview will appear here',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 16),

              const Text(
                'INSERT YOUTUBE URL',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _youtubeUrlController,
                decoration: InputDecoration(
                  hintText: 'https://www.youtube.com/watch?v=...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.link),
                ),
                onChanged: (value) {
                  final trimmedValue = value.trim();
                  if (trimmedValue.isNotEmpty) {

                    _initializeYoutubePlayer(trimmedValue);
                  } else {
                    setState(() {
                      _youtubeController?.dispose();
                      _youtubeController = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),

              const Text(
                'ATTACHMENT PDF FILE (OPTIONAL)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _pdfFileName ?? 'No file selected',
                        style: TextStyle(
                          color: _pdfFileName != null
                              ? Colors.black87
                              : Colors.grey[600],
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _pickPdfFile,
                      icon: const Icon(Icons.insert_drive_file),
                      label: const Text('Select PDF File'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveLesson,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'SAVE',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

