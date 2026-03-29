import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/basic_operator_quiz_service.dart';
import '../models/basic_operator_quiz.dart';

class BasicOperatorQuizProvider with ChangeNotifier {
  final _service = BasicOperatorQuizService();

  List<BasicOperatorQuiz> _quizzes = [];
  List<BasicOperatorQuiz> get quizzes => _quizzes;
  bool isLoading = false;
  String? error;

  Future<void> loadQuizzes(String operator, {String? classroomId}) async {
    isLoading = true;
    notifyListeners();

    try {
      _quizzes = await _service.getQuizzes(operator, classroomId: classroomId);
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

  Future<void> createQuiz({
    required String operator,
    required String title,
    required List<Map<String, dynamic>> questions,
    required String teacherId,
    String? classroomId,
    required String lessonId, // Required - quiz must be attached to a lesson
  }) async {
    try {
      await _service.createQuiz(
        operator: operator,
        title: title,
        questions: questions,
        teacherId: teacherId,
        classroomId: classroomId,
        lessonId: lessonId,
      );
      await loadQuizzes(operator, classroomId: classroomId);
      error = null;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateQuiz({
    required String quizId,
    required String title,
    required List<Map<String, dynamic>> questions,
    required String operator,
    String? classroomId,
  }) async {
    try {
      await _service.updateQuiz(
        quizId: quizId,
        title: title,
        questions: questions,
      );
      await loadQuizzes(operator, classroomId: classroomId);
      error = null;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteQuiz(String quizId, String operator, {String? classroomId}) async {
    try {
      await _service.deleteQuiz(quizId);
      await loadQuizzes(operator, classroomId: classroomId);
      error = null;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}

