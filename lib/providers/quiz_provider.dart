import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuizProvider with ChangeNotifier {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> lessonQuizzes = [];
  List<Map<String, dynamic>> _quizzes = [];
  List<Map<String, dynamic>> get quizzes => _quizzes;

  Future<void> loadQuizzesForLesson(String lessonId) async {
    try {
      final data = await supabase
          .from('quizzes')
          .select('''
            id,
            title,
            classroom_id,
            quiz_questions (
              id,
              question_text,
              choice_a,
              choice_b,
              choice_c,
              correct_choice
            )
          ''')
          .eq('lesson_id', lessonId);

      if (data == null || (data is List && data.isEmpty)) {
        lessonQuizzes = [];
        notifyListeners();
        return;
      }

      lessonQuizzes = (data as List).map((quiz) {
        final rawQuestions = quiz['quiz_questions'] as List<dynamic>? ?? [];

        final parsedQuestions = rawQuestions.map((q) {
          return {
            'id': q['id'],
            'question_text': q['question_text'] ?? 'Untitled question',
            'options': [
              q['choice_a'] ?? '',
              q['choice_b'] ?? '',
              q['choice_c'] ?? '',
            ],
            'correct_choice': q['correct_choice'] ?? 'A',
          };
        }).toList();

        return {
          'id': quiz['id'],
          'title': quiz['title'] ?? 'Untitled Quiz',
          'classroom_id': quiz['classroom_id'],
          'questions': parsedQuestions,
        };
      }).toList();

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> loadQuizzes(String teacherId) async {
    try {
      final data = await supabase
          .from('quizzes')
          .select('id, title, classroom_id, quiz_questions (id)')
          .eq('created_by', teacherId);

      _quizzes = (data as List).map((q) {
        return {
          'id': q['id'],
          'title': q['title'] ?? 'Untitled Quiz',
          'classroom_id': q['classroom_id'],
          'questions': q['quiz_questions'] ?? [],
        };
      }).toList();

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createQuiz({
    required String classroomId,
    required String lessonId,
    required String title,
    required List<Map<String, dynamic>> questions,
    required String teacherId,
  }) async {
    try {
      final quiz = await supabase.from('quizzes').insert({
        'classroom_id': classroomId,
        'lesson_id': lessonId,
        'title': title,
        'created_by': teacherId,
      }).select().single();

      final quizId = quiz['id'];
      for (final q in questions) {
        await supabase.from('quiz_questions').insert({
          'quiz_id': quizId,
          'question_text': q['q'],
          'choice_a': q['options'][0],
          'choice_b': q['options'][1],
          'choice_c': q['options'][2],
          'correct_choice': q['a'],
        });
      }

      await loadQuizzes(teacherId);
    } catch (e) {
      rethrow;
    }
  }
}
