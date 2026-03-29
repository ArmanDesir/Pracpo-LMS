import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/basic_operator_exercise_service.dart';
import '../models/basic_operator_exercise.dart';

class BasicOperatorExerciseProvider with ChangeNotifier {
  final _service = BasicOperatorExerciseService();

  List<BasicOperatorExercise> _exercises = [];
  List<BasicOperatorExercise> get exercises => _exercises;
  bool isLoading = false;
  String? error;

  Future<void> loadExercises(String operator, {String? classroomId}) async {
    isLoading = true;
    notifyListeners();

    try {
      _exercises = await _service.getExercises(operator, classroomId: classroomId);
      error = null;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createExercise({
    required String operator,
    required String title,
    required String lessonId,
    String? description,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    String? storagePath,
    String? classroomId,
  }) async {
    try {

      final supabase = Supabase.instance.client;
      await supabase.from('basic_operator_exercises').insert({
        'operator': operator,
        'title': title,
        'lesson_id': lessonId,
        'description': description,
        'file_url': fileUrl,
        'file_name': fileName,
        'file_size': fileSize,
        'storage_path': storagePath,
        'created_at': DateTime.now().toIso8601String(),
      });

      await loadExercises(operator, classroomId: classroomId);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createExerciseWithFile({
    required String operator,
    required String title,
    required String lessonId,
    required File file,
    String? description,
    String? classroomId,
  }) async {
    try {
      final service = BasicOperatorExerciseService();
      await service.createExercise(
        operator: operator,
        title: title,
        description: description,
        file: file,
        lessonId: lessonId,
      );

      await loadExercises(operator, classroomId: classroomId);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}
