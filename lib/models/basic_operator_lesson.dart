import 'package:json_annotation/json_annotation.dart';

part 'basic_operator_lesson.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class BasicOperatorLesson {
  final String? id;
  final String title;
  final String? description;
  final String operator;
  final String? classroomId;
  final String? fileUrl;
  final String? fileName;
  final String? storagePath;
  final String? youtubeUrl;
  final List<String> exerciseIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  BasicOperatorLesson({
    this.id,
    required this.title,
    required this.operator,
    this.classroomId,
    this.description,
    this.fileUrl,
    this.fileName,
    this.storagePath,
    this.youtubeUrl,
    this.exerciseIds = const [],
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  factory BasicOperatorLesson.fromJson(Map<String, dynamic> json) =>
      _$BasicOperatorLessonFromJson(json);

  Map<String, dynamic> toJson() => _$BasicOperatorLessonToJson(this);

  BasicOperatorLesson copyWith({
    String? fileUrl,
    String? fileName,
    String? storagePath,
    String? classroomId,
  }) {
    return BasicOperatorLesson(
      id: id,
      title: title,
      description: description,
      operator: operator,
      classroomId: classroomId ?? this.classroomId,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      storagePath: storagePath ?? this.storagePath,
      youtubeUrl: youtubeUrl,
      exerciseIds: exerciseIds,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isActive: isActive,
    );
  }

}
