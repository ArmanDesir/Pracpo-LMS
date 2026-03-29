import 'package:json_annotation/json_annotation.dart';

part 'basic_operator_quiz.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class BasicOperatorQuiz {
  final String? id;
  final String operator;
  final String title;
  final String? classroomId;
  final String? lessonId;
  final String? createdBy;
  final DateTime? createdAt;
  final List<BasicOperatorQuizQuestion> questions;

  BasicOperatorQuiz({
    this.id,
    required this.operator,
    required this.title,
    this.classroomId,
    this.lessonId,
    this.createdBy,
    this.createdAt,
    this.questions = const [],
  });
  factory BasicOperatorQuiz.fromJson(Map<String, dynamic> json) =>
      _$BasicOperatorQuizFromJson(json);

  Map<String, dynamic> toJson() => _$BasicOperatorQuizToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class BasicOperatorQuizQuestion {
  final String? id;
  final String quizId;
  final String questionText;
  final String choiceA;
  final String choiceB;
  final String choiceC;
  final String correctChoice;

  BasicOperatorQuizQuestion({
    this.id,
    required this.quizId,
    required this.questionText,
    required this.choiceA,
    required this.choiceB,
    required this.choiceC,
    required this.correctChoice,
  });

  factory BasicOperatorQuizQuestion.fromJson(Map<String, dynamic> json) =>
      _$BasicOperatorQuizQuestionFromJson(json);

  Map<String, dynamic> toJson() => _$BasicOperatorQuizQuestionToJson(this);
}
