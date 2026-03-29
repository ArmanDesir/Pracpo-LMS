import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class ExerciseService {
  final supabase = Supabase.instance.client;

  Future<void> createExercise({
    required String classroomId,
    required String userId,
    required String title,
    String? description,
    File? pdfFile,
  }) async {
    String? fileUrl;
    String? storagePath;
    int? fileSize;

    if (pdfFile != null) {
      final fileName = pdfFile.path.split('/').last;
      final fileBytes = await pdfFile.readAsBytes();
      final path = 'classrooms/$classroomId/exercises/$fileName';
      final bucketName = 'content-files';
      try {
        await supabase.storage.from(bucketName).uploadBinary(path, fileBytes);
        fileUrl = supabase.storage.from(bucketName).getPublicUrl(path);
        storagePath = path;
        fileSize = pdfFile.lengthSync();

      } on StorageException catch (e) {
        rethrow;
      } catch (e) {
        rethrow;
      }
    } else {
    }

    final newExerciseId = const Uuid().v4();
    final record = {
      'id': newExerciseId,
      'classroom_id': classroomId,
      'title': title,
      'description': description,
      'type': 'exercise',
      'file_url': fileUrl,
      'file_name': pdfFile?.path.split('/').last,
      'file_size': fileSize,
      'storage_path': storagePath,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    try {
      await supabase.from('content').insert(record);
    } catch (e) {
      rethrow;
    }

  }

  Future<List<Map<String, dynamic>>> getExercisesByClassroom(String classroomId) async {

    try {
      final res = await supabase
          .from('content')
          .select('*')
          .eq('classroom_id', classroomId)
          .eq('type', 'exercise')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteExercise(String exerciseId) async {
    try {
      final res = await supabase
          .from('content')
          .select('storage_path')
          .eq('id', exerciseId)
          .maybeSingle();

      final storagePath = res?['storage_path'] as String?;
      if (storagePath != null && storagePath.isNotEmpty) {
        try {
          await supabase.storage.from('content-files').remove([storagePath]);
        } catch (e) {
        }
      }

      await supabase.from('content').delete().eq('id', exerciseId);
    } catch (e) {
      rethrow;
    }
  }
}
