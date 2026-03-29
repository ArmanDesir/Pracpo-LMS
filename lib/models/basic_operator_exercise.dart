import 'package:json_annotation/json_annotation.dart';
part 'basic_operator_exercise.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class BasicOperatorExercise {
  final String? id;
  final String operator;
  final String title;
  final String? description;
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  final String? storagePath;
  final String? lessonId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BasicOperatorExercise({
    this.id,
    required this.operator,
    required this.title,
    this.description,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.storagePath,
    this.lessonId,
    this.createdAt,
    this.updatedAt,
  });

  factory BasicOperatorExercise.fromJson(Map<String, dynamic> json) =>
      _$BasicOperatorExerciseFromJson(json);

  Map<String, dynamic> toJson() => _$BasicOperatorExerciseToJson(this);
}
