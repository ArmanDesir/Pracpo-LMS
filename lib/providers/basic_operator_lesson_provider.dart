import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pracpro/models/basic_operator_lesson.dart';
import 'package:pracpro/services/basic_operator_lesson_service.dart';

class BasicOperatorLessonProvider with ChangeNotifier {
  final _service = BasicOperatorLessonService();

  List<BasicOperatorLesson> lessons = [];
  bool isLoading = false;
  String? error;

  Future<List<BasicOperatorLesson>> loadLessons(String operator, {String? classroomId}) async {
    isLoading = true;
    notifyListeners();

    try {
      lessons = await _service.getLessons(operator, classroomId: classroomId);
      error = null;
    } catch (e) {
      error = e.toString();
    }

    isLoading = false;
    notifyListeners();
    return lessons;
  }

  Future<void> createLesson(BasicOperatorLesson lesson) async {
    try {
      final created = await _service.createLesson(lesson);
      lessons.add(created);
      error = null;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> createLessonWithFile(
      BasicOperatorLesson lesson, File file) async {
    try {
      final created = await _service.createLessonWithFile(lesson, file);
      lessons.add(created);
      error = null;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateLesson(BasicOperatorLesson lesson) async {
    try {
      final updated = await _service.updateLesson(lesson);
      final index = lessons.indexWhere((l) => l.id == lesson.id);
      if (index != -1) {
        lessons[index] = updated;
      }
      error = null;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteLesson(String lessonId) async {
    try {
      await _service.deleteLesson(lessonId);
      lessons.removeWhere((l) => l.id == lessonId);
      error = null;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
