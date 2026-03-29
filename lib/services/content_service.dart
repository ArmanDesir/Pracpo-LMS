import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/content.dart';
import 'package:uuid/uuid.dart';
class ContentService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final SupabaseStorageClient _storage = Supabase.instance.client.storage;
  final Uuid _uuid = const Uuid();

  Future<FilePickerResult?> pickPDFFile() async {
    try {
      return await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
    } catch (e) {
      throw Exception('Failed to pick file: $e');
    }
  }

  Future<(String fileUrl, String storagePath)> uploadPDFFile(
      File file,
      String classroomId,
      ContentType type,
      ) async {
    try {
      final fileName = '${_uuid.v4()}.pdf';

      final subFolder = switch (type) {
        ContentType.lesson => 'lessons',
        ContentType.quiz => 'quizzes',
        ContentType.exercise => 'exercises',
      };

      final storagePath = 'classrooms/$classroomId/$subFolder/$fileName';

      await _storage.from('content-files').uploadBinary(
        storagePath,
        file.readAsBytesSync(),
        fileOptions: const FileOptions(cacheControl: '3600'),
      );

      final fileUrl = _storage.from('content-files').getPublicUrl(storagePath);

      return (fileUrl, storagePath);
    } on StorageException catch (e) {
      throw Exception('Failed to upload file to storage: ${e.message}');
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  Future<Content> createContent({
    required String classroomId,
    required String title,
    required String description,
    required ContentType type,
    required File pdfFile,
  }) async {
    try {
      final (fileUrl, storagePath) =
      await uploadPDFFile(pdfFile, classroomId, type);

      final fileName = storagePath.split('/').last;

      final content = Content(
        id: _uuid.v4(),
        classroomId: classroomId,
        title: title,
        description: description,
        type: type,
        fileUrl: fileUrl,
        storagePath: storagePath,
        fileName: fileName,
        fileSize: await pdfFile.length(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _supabase.from('content').insert(content.toJson());
      return content;
    } catch (e) {
      throw Exception('Failed to create content: $e');
    }
  }

  Future<List<Content>> getContentByClassroom(String classroomId) async {
    try {
      final response = await _supabase
          .from('classroom_content')
          .select()
          .eq('classroom_id', classroomId)
          .order('created_at', ascending: false);

      return response.map<Content>((data) => Content.fromJson(data)).toList();
    } catch (e) {
      throw Exception('Failed to get content: $e');
    }
  }

  Future<void> deleteContent({
    required String contentId,
    required ContentType type,
  }) async {
    try {
      String table;
      switch (type) {
        case ContentType.lesson:
          table = 'lessons';
          break;
        case ContentType.quiz:
          table = 'quizzes';
          break;
        case ContentType.exercise:
          table = 'exercises';
          break;
      }

      final response = await _supabase
          .from(table)
          .select('storage_path, file_url')
          .eq('id', contentId)
          .maybeSingle();

      if (response == null) {
        throw Exception("No $table found with id=$contentId");
      }

      String? storagePath = response['storage_path'] as String?;
      if ((storagePath == null || storagePath.isEmpty) && response['file_url'] != null) {
        final fileUrl = response['file_url'] as String;
        final uri = Uri.parse(fileUrl);
        final segments = uri.pathSegments;

        final index = segments.indexOf('content-files');
        if (index != -1 && index + 1 < segments.length) {
          storagePath = segments.sublist(index + 1).join('/');
        }
      }

      if (storagePath != null && storagePath.isNotEmpty) {
        await _storage.from('content-files').remove([storagePath]);
      }

      await _supabase.from(table).delete().eq('id', contentId);
    } catch (e, stack) {
      throw Exception('Failed to delete content: $e');
    }
  }

  String? extractStoragePath(String? fileUrl) {
    if (fileUrl == null) return null;
    const marker = '/object/public/content-files/';
    final idx = fileUrl.indexOf(marker);
    if (idx == -1) return null;
    return fileUrl.substring(idx + marker.length);
  }

  Future<List<Content>> getAllContents({ContentType? type}) async {
    try {
      final query = _supabase.from('content');

      dynamic response;
      if (type != null) {
        response = await query
            .select()
            .eq('type', type.name)
            .order('created_at', ascending: false);
      } else {
        response = await query
            .select()
            .order('created_at', ascending: false);
      }

      return response.map<Content>((data) => Content.fromJson(data)).toList();
    } catch (e) {
      throw Exception('Failed to get all contents: $e');
    }
  }

  Future<void> attachExistingContent({
    required String classroomId,
    required String contentId,
  }) async {
    try {
      final response = await _supabase
          .from('content')
          .select()
          .eq('id', contentId)
          .single();

      final existing = Content.fromJson(response);
      final newContent = Content(
        id: _uuid.v4(),
        classroomId: classroomId,
        title: existing.title,
        description: existing.description,
        type: existing.type,
        fileUrl: existing.fileUrl,
        storagePath: existing.storagePath,
        fileName: existing.fileName,
        fileSize: existing.fileSize,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _supabase.from('content').insert(newContent.toJson());
    } catch (e) {
      throw Exception('Failed to attach existing content: $e');
    }
  }
}
