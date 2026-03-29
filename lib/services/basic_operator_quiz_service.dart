import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/basic_operator_quiz.dart';

class BasicOperatorQuizService {
  final SupabaseClient _sb = Supabase.instance.client;

  Future<List<BasicOperatorQuiz>> getQuizzes(String operator, {String? classroomId, String? lessonId}) async {
    var query = _sb
        .from('basic_operator_quizzes')
        .select('*, basic_operator_quiz_questions(*)')
        .eq('operator', operator);

    if (classroomId != null) {
      query = query.eq('classroom_id', classroomId);
    }

    if (lessonId != null && lessonId.isNotEmpty) {
      query = query.eq('lesson_id', lessonId);
    }

    final data = await query.order('created_at', ascending: false);

    if (data == null) return [];

    return (data as List).map((row) {
      final quizMap = Map<String, dynamic>.from(row);
      quizMap['questions'] = quizMap['basic_operator_quiz_questions'] ?? [];

      return BasicOperatorQuiz.fromJson(quizMap);
    }).toList();
  }

  Future<void> createQuiz({
    required String operator,
    required String title,
    required List<Map<String, dynamic>> questions,
    required String teacherId,
    String? classroomId,
    required String lessonId, // Required - quiz must be attached to a lesson
  }) async {
    // Validate that lessonId is provided
    if (lessonId.isEmpty) {
      throw Exception('A lesson must be selected to create a quiz');
    }

    final quizData = {
      'operator': operator,
      'title': title,
      'created_by': teacherId,
      'created_at': DateTime.now().toIso8601String(),
      'lesson_id': lessonId, // Required field
    };

    if (classroomId != null) {
      quizData['classroom_id'] = classroomId;
    }

    final quiz = await _sb.from('basic_operator_quizzes').insert(quizData).select().single();

    final quizId = quiz['id'];
    for (final q in questions) {
      await _sb.from('basic_operator_quiz_questions').insert({
        'quiz_id': quizId,
        'question_text': q['q'],
        'choice_a': q['options'][0],
        'choice_b': q['options'][1],
        'choice_c': q['options'][2],
        'correct_choice': q['a'],
      });
    }
  }

  Future<void> updateQuiz({
    required String quizId,
    required String title,
    required List<Map<String, dynamic>> questions,
  }) async {

    await _sb.from('basic_operator_quizzes').update({
      'title': title,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', quizId);

    await _sb.from('basic_operator_quiz_questions').delete().eq('quiz_id', quizId);

    for (final q in questions) {
      await _sb.from('basic_operator_quiz_questions').insert({
        'quiz_id': quizId,
        'question_text': q['q'],
        'choice_a': q['options'][0],
        'choice_b': q['options'][1],
        'choice_c': q['options'][2],
        'correct_choice': q['a'],
      });
    }
  }

  Future<void> deleteQuiz(String quizId) async {
    await _sb.from('basic_operator_quiz_questions').delete().eq('quiz_id', quizId);
    await _sb.from('basic_operator_quizzes').delete().eq('id', quizId);
  }
}
