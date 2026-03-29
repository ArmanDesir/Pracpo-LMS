// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Content _$ContentFromJson(Map<String, dynamic> json) => Content(
  id: json['id'] as String,
  classroomId: json['classroom_id'] as String,
  title: json['title'] as String,
  description: json['description'] as String?,
  type: $enumDecode(_$ContentTypeEnumMap, json['type']),
  fileUrl: json['file_url'] as String?,
  storagePath: json['storage_path'] as String?,
  fileName: json['file_name'] as String?,
  fileSize: (json['file_size'] as num?)?.toInt(),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  youtubeUrl: json['youtube_url'] as String?,
  isUnlocked: json['is_unlocked'] as bool? ?? true,
);

Map<String, dynamic> _$ContentToJson(Content instance) => <String, dynamic>{
  'id': instance.id,
  'classroom_id': instance.classroomId,
  'title': instance.title,
  'description': instance.description,
  'type': _$ContentTypeEnumMap[instance.type]!,
  'file_url': instance.fileUrl,
  'storage_path': instance.storagePath,
  'file_name': instance.fileName,
  'file_size': instance.fileSize,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
  'youtube_url': instance.youtubeUrl,
  'is_unlocked': instance.isUnlocked,
};

const _$ContentTypeEnumMap = {
  ContentType.lesson: 'lesson',
  ContentType.quiz: 'quiz',
  ContentType.exercise: 'exercise',
};
