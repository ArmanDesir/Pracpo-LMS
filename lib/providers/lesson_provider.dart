import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pracpro/models/lesson.dart';
import 'package:pracpro/services/lesson_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LessonProvider with ChangeNotifier {
  final LessonService _lessonService = LessonService();
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Lesson> lessons = [];
  bool isLoading = false;
  String? error;

  Future<(String publicUrl, String storagePath)> uploadLessonFile(
      File file, String classroomId) async {
    final storagePath =
        'classrooms/$classroomId/lessons/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';

    final response = await _supabase.storage.from('content-files').upload(storagePath, file);
    if (response == null) throw Exception('Failed to upload file');

    final publicUrl = _supabase.storage.from('content-files').getPublicUrl(storagePath);

    return (publicUrl, storagePath);
  }

  Future<void> createLesson(Lesson lesson) async {
    try {
      final created = await _lessonService.createLesson(lesson);
      lessons.add(created);
      error = null;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadLessons(String classroomId) async {
    isLoading = true;
    notifyListeners();
    try {
      lessons = await _lessonService.getLessons(classroomId);
      error = null;
    } catch (e) {
      error = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }
}
