import 'package:json_annotation/json_annotation.dart';

part 'lesson.g.dart';

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class Lesson {
  final String? id;
  final String title;
  final String? description;
  final String classroomId;
  final String? fileUrl;
  final String? storagePath;
  final String? fileName;
  final String? youtubeUrl;
  final List<String> exerciseIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  Lesson({
    this.id,
    required this.title,
    this.description,
    required this.classroomId,
    this.fileUrl,
    this.storagePath,
    this.fileName,
    this.youtubeUrl,
    this.exerciseIds = const [],
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) =>
      _$LessonFromJson(json);

  Map<String, dynamic> toJson() => _$LessonToJson(this);

  Lesson copyWith({
    String? id,
    String? title,
    String? description,
    String? classroomId,
    String? fileUrl,
    String? storagePath,
    String? fileName,
    String? youtubeUrl,
    List<String>? exerciseIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Lesson(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      classroomId: classroomId ?? this.classroomId,
      fileUrl: fileUrl ?? this.fileUrl,
      storagePath: storagePath ?? this.storagePath,
      fileName: fileName ?? this.fileName,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      exerciseIds: exerciseIds ?? this.exerciseIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
