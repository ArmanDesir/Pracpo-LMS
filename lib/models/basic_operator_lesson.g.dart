// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'basic_operator_lesson.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BasicOperatorLesson _$BasicOperatorLessonFromJson(Map<String, dynamic> json) =>
    BasicOperatorLesson(
      id: json['id'] as String?,
      title: json['title'] as String,
      operator: json['operator'] as String,
      classroomId: json['classroom_id'] as String?,
      description: json['description'] as String?,
      fileUrl: json['file_url'] as String?,
      fileName: json['file_name'] as String?,
      storagePath: json['storage_path'] as String?,
      youtubeUrl: json['youtube_url'] as String?,
      exerciseIds:
          (json['exercise_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      createdAt:
          json['created_at'] == null
              ? null
              : DateTime.parse(json['created_at'] as String),
      updatedAt:
          json['updated_at'] == null
              ? null
              : DateTime.parse(json['updated_at'] as String),
      isActive: json['is_active'] as bool? ?? true,
    );

Map<String, dynamic> _$BasicOperatorLessonToJson(
  BasicOperatorLesson instance,
) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'operator': instance.operator,
  'classroom_id': instance.classroomId,
  'file_url': instance.fileUrl,
  'file_name': instance.fileName,
  'storage_path': instance.storagePath,
  'youtube_url': instance.youtubeUrl,
  'exercise_ids': instance.exerciseIds,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
  'is_active': instance.isActive,
};
