// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'basic_operator_quiz.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BasicOperatorQuiz _$BasicOperatorQuizFromJson(Map<String, dynamic> json) =>
    BasicOperatorQuiz(
      id: json['id'] as String?,
      operator: json['operator'] as String,
      title: json['title'] as String,
      classroomId: json['classroom_id'] as String?,
      lessonId: json['lesson_id'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt:
          json['created_at'] == null
              ? null
              : DateTime.parse(json['created_at'] as String),
      questions:
          (json['questions'] as List<dynamic>?)
              ?.map(
                (e) => BasicOperatorQuizQuestion.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          const [],
    );

Map<String, dynamic> _$BasicOperatorQuizToJson(BasicOperatorQuiz instance) =>
    <String, dynamic>{
      'id': instance.id,
      'operator': instance.operator,
      'title': instance.title,
      'classroom_id': instance.classroomId,
      'lesson_id': instance.lessonId,
      'created_by': instance.createdBy,
      'created_at': instance.createdAt?.toIso8601String(),
      'questions': instance.questions,
    };

BasicOperatorQuizQuestion _$BasicOperatorQuizQuestionFromJson(
  Map<String, dynamic> json,
) => BasicOperatorQuizQuestion(
  id: json['id'] as String?,
  quizId: json['quiz_id'] as String,
  questionText: json['question_text'] as String,
  choiceA: json['choice_a'] as String,
  choiceB: json['choice_b'] as String,
  choiceC: json['choice_c'] as String,
  correctChoice: json['correct_choice'] as String,
);

Map<String, dynamic> _$BasicOperatorQuizQuestionToJson(
  BasicOperatorQuizQuestion instance,
) => <String, dynamic>{
  'id': instance.id,
  'quiz_id': instance.quizId,
  'question_text': instance.questionText,
  'choice_a': instance.choiceA,
  'choice_b': instance.choiceB,
  'choice_c': instance.choiceC,
  'correct_choice': instance.correctChoice,
};
