import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/basic_operator_lesson.dart';

class BasicOperatorLessonService {
  final _sb = Supabase.instance.client;
  final String bucket = 'basic-operator';

  Future<List<BasicOperatorLesson>> getLessons(String operator, {String? classroomId}) async {
    var query = _sb
        .from('basic_operator_lessons')
        .select('*')
        .eq('operator', operator)
        .eq('is_active', true);

    if (classroomId != null) {
      query = query.eq('classroom_id', classroomId);
    }

    final rows = await query.order('created_at', ascending: false);

    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(BasicOperatorLesson.fromJson)
        .toList();
  }

  Future<BasicOperatorLesson> createLesson(BasicOperatorLesson lesson) async {
    final data = lesson.toJson()
      ..remove('id')
      ..remove('updated_at');

    if (data['created_at'] == null) {
      data['created_at'] = DateTime.now().toIso8601String();
    }

    data['is_active'] = lesson.isActive;

    final inserted = await _sb
        .from('basic_operator_lessons')
        .insert(data)
        .select('*')
        .single();

    return BasicOperatorLesson.fromJson(Map<String, dynamic>.from(inserted));
  }

  Future<BasicOperatorLesson> createLessonWithFile(
      BasicOperatorLesson lesson,
      File file,
      ) async {
    final fileExt = file.path.split('.').last;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '${lesson.operator}/lessons/$timestamp.$fileExt';

    try {
      await _sb.storage.from(bucket).upload(path, file);
      final fileUrl = _sb.storage.from(bucket).getPublicUrl(path);
      final newLesson = lesson.copyWith(
        fileUrl: fileUrl,
        storagePath: path,
        fileName: file.path.split('/').last,
      );

      final data = newLesson.toJson()
        ..remove('id')
        ..remove('updated_at');

      if (data['created_at'] == null) {
        data['created_at'] = DateTime.now().toIso8601String();
      }

      data['is_active'] = newLesson.isActive;

      final inserted = await _sb
          .from('basic_operator_lessons')
          .insert(data)
          .select()
          .single();

      return BasicOperatorLesson.fromJson(Map<String, dynamic>.from(inserted));
    } catch (e) {
      rethrow;
    }
  }

  Future<BasicOperatorLesson> updateLesson(BasicOperatorLesson lesson) async {
    if (lesson.id == null) {
      throw Exception('Cannot update lesson without an ID');
    }

    final data = lesson.toJson()
      ..remove('id')
      ..remove('created_at');

    data['updated_at'] = DateTime.now().toIso8601String();

    final updated = await _sb
        .from('basic_operator_lessons')
        .update(data)
        .eq('id', lesson.id!)
        .select('*')
        .single();

    return BasicOperatorLesson.fromJson(Map<String, dynamic>.from(updated));
  }

  Future<void> deleteLesson(String lessonId) async {
    await _sb
        .from('basic_operator_lessons')
        .update({'is_active': false})
        .eq('id', lessonId);
  }
}
