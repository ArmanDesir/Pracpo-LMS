import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/basic_operator_exercise.dart';

class BasicOperatorExerciseService {
  final SupabaseClient _sb = Supabase.instance.client;
  final String bucket = 'basic-operator';

  Future<List<BasicOperatorExercise>> getExercises(String operator, {String? classroomId}) async {

    if (classroomId != null) {

      final lessonsData = await _sb
          .from('basic_operator_lessons')
          .select('id')
          .eq('operator', operator)
          .eq('classroom_id', classroomId)
          .eq('is_active', true);

      final lessonIds = (lessonsData as List).map((l) => l['id'] as String).toList();

      List<Map<String, dynamic>> allExercises = [];

      if (lessonIds.isNotEmpty) {

        final linkedExercises = await _sb
            .from('basic_operator_exercises')
            .select('*')
            .eq('operator', operator)
            .inFilter('lesson_id', lessonIds)
            .order('created_at', ascending: false);

        allExercises.addAll((linkedExercises as List).cast<Map<String, dynamic>>());
      }

      final standaloneExercises = await _sb
          .from('basic_operator_exercises')
          .select('*')
          .eq('operator', operator)
          .isFilter('lesson_id', null)
          .order('created_at', ascending: false);

      allExercises.addAll((standaloneExercises as List).cast<Map<String, dynamic>>());

      final uniqueExercises = <String, Map<String, dynamic>>{};
      for (final ex in allExercises) {
        if (ex['id'] != null) {
          uniqueExercises[ex['id'] as String] = ex;
        }
      }

      final sorted = uniqueExercises.values.toList()
        ..sort((a, b) {
          final aDate = a['created_at'] as String?;
          final bDate = b['created_at'] as String?;
          if (aDate == null || bDate == null) return 0;
          return bDate.compareTo(aDate);
        });

      return sorted
          .map((row) => BasicOperatorExercise.fromJson(row))
          .toList();
    }

    final data = await _sb
        .from('basic_operator_exercises')
        .select('*')
        .eq('operator', operator)
        .order('created_at', ascending: false);

    return (data as List)
        .map((row) => BasicOperatorExercise.fromJson(row))
        .toList();
  }

  Future<(String publicUrl, String storagePath)> uploadExerciseFile(
      File file, String operator) async {
    final fileExt = file.path.split('.').last;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath = '$operator/exercises/$timestamp.$fileExt';

    await _sb.storage.from(bucket).upload(storagePath, file);
    final publicUrl = _sb.storage.from(bucket).getPublicUrl(storagePath);

    return (publicUrl, storagePath);
  }

  Future<void> createExercise({
    required String operator,
    required String title,
    String? description,
    File? file,
    required String lessonId,
  }) async {
    String? fileUrl;
    String? storagePath;
    int? fileSize;

    if (file != null) {
      final upload = await uploadExerciseFile(file, operator);
      fileUrl = upload.$1;
      storagePath = upload.$2;
      fileSize = file.lengthSync();
    }

    await _sb.from('basic_operator_exercises').insert({
      'operator': operator,
      'title': title,
      'description': description,
      'file_url': fileUrl,
      'file_name': file?.path.split('/').last,
      'file_size': fileSize,
      'storage_path': storagePath,
      'lesson_id': lessonId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> deleteExercise(String exerciseId) async {
    final data = await _sb
        .from('basic_operator_exercises')
        .select('storage_path')
        .eq('id', exerciseId)
        .maybeSingle();

    if (data != null && data['storage_path'] != null) {
      await _sb.storage.from(bucket).remove([data['storage_path']]);
    }

    await _sb.from('basic_operator_exercises').delete().eq('id', exerciseId);
  }
}
