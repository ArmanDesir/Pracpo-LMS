// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Lesson _$LessonFromJson(Map<String, dynamic> json) => Lesson(
  id: json['id'] as String?,
  title: json['title'] as String,
  description: json['description'] as String?,
  classroomId: json['classroom_id'] as String,
  fileUrl: json['file_url'] as String?,
  storagePath: json['storage_path'] as String?,
  fileName: json['file_name'] as String?,
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

Map<String, dynamic> _$LessonToJson(Lesson instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'classroom_id': instance.classroomId,
  'file_url': instance.fileUrl,
  'storage_path': instance.storagePath,
  'file_name': instance.fileName,
  'youtube_url': instance.youtubeUrl,
  'exercise_ids': instance.exerciseIds,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
  'is_active': instance.isActive,
};
