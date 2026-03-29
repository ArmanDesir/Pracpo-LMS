import 'package:supabase_flutter/supabase_flutter.dart';

class QuizService {
  final _sb = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getQuestionsForLesson(String lessonId) async {
    final quiz = await _sb
        .from('quizzes')
        .select('id')
        .eq('lesson_id', lessonId)
        .maybeSingle();
    if (quiz == null) return [];

    final List rows = await _sb
        .from('quiz_questions')
        .select()
        .eq('quiz_id', quiz['id'])
        .order('id');

    return rows.map<Map<String, dynamic>>((r) => {
      'question_text': r['question_text'],
      'options': [r['choice_a'], r['choice_b'], r['choice_c']],
      'correct_choice': r['correct_choice'],
    }).toList();
  }

  Future<String?> ensureQuizIdForLesson(String lessonId) async {
    final quiz = await _sb
        .from('quizzes')
        .select('id')
        .eq('lesson_id', lessonId)
        .maybeSingle();
    return quiz?['id'] as String?;
  }
}
