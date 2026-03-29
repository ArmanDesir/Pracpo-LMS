import 'dart:async';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lesson.dart';

class LessonService {
  LessonService({this.bucket = 'content-files'});

  final SupabaseClient _sb = Supabase.instance.client;
  final String bucket;

  Future<List<Lesson>> getLessons(
      String classroomId, {
        String? operatorFilter,
        int? difficulty,
      }) async {
    final rows = await Supabase.instance.client
        .from('lessons')
        .select('*')
        .eq('classroom_id', classroomId)
        .eq('is_active', true)
        .order('created_at', ascending: false);

    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(Lesson.fromJson)
        .toList();
  }

  Stream<List<Lesson>> streamLessons(
      String classroomId, {
        String? operatorFilter,
        int? difficulty,
      }) {
    final controller = StreamController<List<Lesson>>.broadcast();
    () async {
      controller.add(await getLessons(
        classroomId,
        operatorFilter: operatorFilter,
        difficulty: difficulty,
      ));
    }();

    final channel = _sb
        .channel('lessons-$classroomId')
        .onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'lessons',
    filter: PostgresChangeFilter(
    type: PostgresChangeFilterType.eq,
    column: 'classroom_id',
    value: classroomId,
    ),
    callback: (payload) async {
    controller.add(await getLessons(
    classroomId,
    operatorFilter: operatorFilter,
    difficulty: difficulty,
    ));
    },
    )
        .subscribe();

    controller.onCancel = () => _sb.removeChannel(channel);
    return controller.stream;
  }

  Future<Lesson> createLesson(Lesson lesson) async {
    final data = lesson.toJson()
      ..remove('id')
      ..remove('created_at')
      ..remove('updated_at');

    final inserted = await _sb
        .from('lessons')
        .insert(data)
        .select('*')
        .single();

    return Lesson.fromJson(Map<String, dynamic>.from(inserted));
  }

  Future<Lesson> attachFile({
    required Lesson lesson,
    required File file,
    String? fileNameOverride,
  }) async {
    if (lesson.id == null) {
      throw StateError('attachFile requires an existing lesson with id.');
    }

    final ext = file.path.split('.').last;
    final fileName = fileNameOverride ?? lesson.fileName ?? 'lesson.$ext';
    final path = 'classrooms/${lesson.classroomId}/lessons/${lesson.id}/$fileName';

    await _sb.storage.from(bucket).upload(
      path,
      file,
      fileOptions: const FileOptions(upsert: true),
    );

    final publicUrl = _sb.storage.from(bucket).getPublicUrl(path);

    final updated = await _sb
        .from('lessons')
        .update({
      'file_url': publicUrl,
      'storage_path': path,
      'file_name': fileName,
      'updated_at': DateTime.now().toIso8601String(),
    })
        .eq('id', lesson.id!)
        .select('*')
        .single();

    return Lesson.fromJson(Map<String, dynamic>.from(updated));
  }

  Future<void> updateLesson(Lesson lesson) async {
    if (lesson.id == null) throw ArgumentError('lesson.id is required');

    final data = lesson.toJson()
      ..['updated_at'] = DateTime.now().toIso8601String()
      ..removeWhere((_, v) => v == null);

    await _sb.from('lessons').update(data).eq('id', lesson.id!);
  }

  Future<void> deactivateLesson(String id) async {
    await _sb
        .from('lessons')
        .update({
      'is_active': false,
      'updated_at': DateTime.now().toIso8601String(),
    })
        .eq('id', id);
  }

  Future<void> deleteLesson(String id) async {
    await _sb.from('lessons').delete().eq('id', id);
  }

  Future<Lesson> createLessonWithOptionalFile({
    required Lesson draft,
    File? file,
    String? fileNameOverride,
  }) async {
    var created = await createLesson(draft);
    if (file != null) {
      created = await attachFile(
        lesson: created,
        file: file,
        fileNameOverride: fileNameOverride,
      );
    }
    return created;
  }
}

extension _ConditionalPostgrest on PostgrestFilterBuilder {
  PostgrestFilterBuilder if_(
      bool condition,
      PostgrestFilterBuilder Function(PostgrestFilterBuilder) apply,
      ) =>
      condition ? apply(this) : this;
}
