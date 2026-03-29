import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'content.g.dart';

enum ContentType { lesson, quiz, exercise }

extension ContentTypeUI on ContentType {
  Color get color {
    switch (this) {
      case ContentType.lesson:
        return Colors.blue;
      case ContentType.exercise:
        return Colors.orange;
      case ContentType.quiz:
        return Colors.purple;
    }
  }

  IconData get icon {
    switch (this) {
      case ContentType.lesson:
        return Icons.book;
      case ContentType.exercise:
        return Icons.fitness_center;
      case ContentType.quiz:
        return Icons.quiz;
    }
  }
}

@JsonSerializable(fieldRename: FieldRename.snake)
class Content {
  final String id;
  final String classroomId;
  final String title;
  final String? description;
  final ContentType type;

  final String? fileUrl;
  final String? storagePath;
  final String? fileName;
  final int? fileSize;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? youtubeUrl;
  final bool isUnlocked;

  Content({
    required this.id,
    required this.classroomId,
    required this.title,
    this.description,
    required this.type,
    this.fileUrl,
    this.storagePath,
    this.fileName,
    this.fileSize,
    required this.createdAt,
    required this.updatedAt,
    this.youtubeUrl,
    this.isUnlocked = true,
  });

  factory Content.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'lesson';
    final type = _contentTypeFromString(typeStr);

    return Content(
      id: json['id'] as String,
      classroomId: json['classroom_id'] as String,
      title: json['title'] as String,
      description: type == ContentType.quiz ? null : json['description'] as String?,
      type: type,
      fileUrl: type == ContentType.quiz ? null : json['file_url'] as String?,
      storagePath: type == ContentType.quiz ? null : json['storage_path'] as String?,
      fileName: type == ContentType.quiz ? null : json['file_name'] as String?,
      fileSize: type == ContentType.quiz ? null : json['file_size'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      youtubeUrl: json['youtube_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => _$ContentToJson(this);

  Content copyWith({
    String? id,
    String? classroomId,
    String? title,
    String? description,
    ContentType? type,
    String? fileUrl,
    String? storagePath,
    String? fileName,
    int? fileSize,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? youtubeUrl,
  }) {
    return Content(
      id: id ?? this.id,
      classroomId: classroomId ?? this.classroomId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      fileUrl: fileUrl ?? this.fileUrl,
      storagePath: storagePath ?? this.storagePath,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
    );
  }

  static ContentType _contentTypeFromString(String type) {
    switch (type) {
      case 'lesson':
        return ContentType.lesson;
      case 'quiz':
        return ContentType.quiz;
      case 'exercise':
        return ContentType.exercise;
      default:
        return ContentType.lesson;
    }
  }
}
