// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'basic_operator_exercise.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BasicOperatorExercise _$BasicOperatorExerciseFromJson(
  Map<String, dynamic> json,
) => BasicOperatorExercise(
  id: json['id'] as String?,
  operator: json['operator'] as String,
  title: json['title'] as String,
  description: json['description'] as String?,
  fileUrl: json['file_url'] as String?,
  fileName: json['file_name'] as String?,
  fileSize: (json['file_size'] as num?)?.toInt(),
  storagePath: json['storage_path'] as String?,
  lessonId: json['lesson_id'] as String?,
  createdAt:
      json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
  updatedAt:
      json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$BasicOperatorExerciseToJson(
  BasicOperatorExercise instance,
) => <String, dynamic>{
  'id': instance.id,
  'operator': instance.operator,
  'title': instance.title,
  'description': instance.description,
  'file_url': instance.fileUrl,
  'file_name': instance.fileName,
  'file_size': instance.fileSize,
  'storage_path': instance.storagePath,
  'lesson_id': instance.lessonId,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
};
