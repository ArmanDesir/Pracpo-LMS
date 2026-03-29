import 'package:pracpro/models/classroom.dart';
import 'package:pracpro/models/user.dart' as app_model;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class ClassroomService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Uuid _uuid = Uuid();

  String generateClassroomCode() {
    return _uuid.v4().substring(0, 6).toUpperCase();
  }

  Future<Classroom> createClassroom({
    required String name,
    required String description,
    required String teacherId,
  }) async {
    final code = generateClassroomCode();
    final classroom = Classroom(
      id: _uuid.v4(),
      name: name,
      teacherId: teacherId,
      description: description,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      code: code,
    );

    final jsonData = classroom.toJson();

    if (jsonData.containsKey('is_archived')) {
      jsonData['is_active'] = !(jsonData['is_archived'] as bool);
      jsonData.remove('is_archived');
    }
    await _supabase.from('classrooms').insert(jsonData);
    return classroom;
  }

  Future<void> requestToJoinClassroom({required String classroomCode, required String studentId,}) async {
    final classroom = await _supabase
        .from('classrooms')
        .select()
        .eq('code', classroomCode)
        .maybeSingle();

    if (classroom == null) {
      throw Exception('Classroom not found');
    }

    final classroomId = classroom['id'] as String;

    final existing = await _supabase
        .from('user_classrooms')
        .select()
        .eq('user_id', studentId)
        .eq('classroom_id', classroomId)
        .maybeSingle();

    if (existing != null) {
      throw Exception('Already requested or joined');
    }

    await _supabase.from('user_classrooms').insert({
      'user_id': studentId,
      'classroom_id': classroomId,
      'status': 'pending',
      'joined_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> acceptStudent({
    required String classroomId,
    required String studentId,
  }) async {
    final updated = await _supabase
        .from('user_classrooms')
        .update({
      'status': 'accepted',
      'joined_at': DateTime.now().toIso8601String(),
    })
        .eq('classroom_id', classroomId)
        .eq('user_id', studentId)
        .select();

    if (updated.isEmpty) {
      throw Exception('Student not found in pending list');
    }

    final classroom = await _supabase
        .from('classrooms')
        .select('student_ids')
        .eq('id', classroomId)
        .single();
    final studentIds = List<String>.from(classroom['student_ids'] ?? const []);

    if (!studentIds.contains(studentId)) {
      studentIds.add(studentId);
      await _supabase
          .from('classrooms')
          .update({
        'student_ids': studentIds,
        'updated_at': DateTime.now().toIso8601String(),
      })
          .eq('id', classroomId);
    }
  }

  Future<void> rejectStudent({required String classroomId, required String studentId,}) async {
    await _supabase
        .from('user_classrooms')
        .delete()
        .eq('classroom_id', classroomId)
        .eq('user_id', studentId)
        .eq('status', 'pending');
  }

  Future<void> removeStudent({
    required String classroomId,
    required String studentId,
  }) async {
    await _supabase
        .from('user_classrooms')
        .delete()
        .eq('classroom_id', classroomId)
        .eq('user_id', studentId)
        .eq('status', 'accepted');
    final classroom = await _supabase
        .from('classrooms')
        .select('student_ids')
        .eq('id', classroomId)
        .maybeSingle();

    if (classroom != null) {
      final List<dynamic> studentIds =
      (classroom['student_ids'] as List<dynamic>? ?? []).toList();
      studentIds.remove(studentId);

      await _supabase.from('classrooms').update({
        'student_ids': studentIds,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', classroomId);
    }
  }

  Future<Classroom?> getClassroomByCode(String code) async {
    final response = await _supabase
        .from('classrooms')
        .select()
        .eq('code', code)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return Classroom.fromJson(response);
  }

  Future<Classroom?> getClassroomById(String id) async {
    final response = await _supabase
        .from('classrooms')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Classroom.fromJson(response);
  }

  Future<List<Classroom>> getStudentClassrooms(
      String studentId, {
        int limit = 3,
        int offset = 0,
      }) async {
    final response = await _supabase
        .from('user_classrooms')
        .select('classroom_id, classrooms(*)')
        .eq('user_id', studentId)
        .eq('status', 'accepted')
        .order('joined_at', ascending: false)
        .range(offset, offset + limit - 1);

    if (response is! List) return [];

    return response.map((item) {
      final classroomData = Map<String, dynamic>.from(item['classrooms']);
      return Classroom.fromJson(classroomData);
    }).toList();
  }

  Future<List<app_model.User>> getAcceptedStudents(String classroomId) async {
    final userIdsResponse = await _supabase
        .from('user_classrooms')
        .select('user_id')
        .eq('classroom_id', classroomId)
        .eq('status', 'accepted');

    final userIds = (userIdsResponse as List)
        .map((e) => e['user_id'] as String)
        .toList();
    if (userIds.isEmpty) return [];

    final response = await _supabase
        .from('users')
        .select()
        .filter('id', 'in', '(${userIds.join(",")})');

    return (response as List)
        .map((u) => app_model.User.fromJson(Map<String, dynamic>.from(u)))
        .toList();
  }

  Future<List<app_model.User>> getPendingStudents(String classroomId) async {
    final userIdsResponse = await _supabase
        .from('user_classrooms')
        .select('user_id')
        .eq('classroom_id', classroomId)
        .eq('status', 'pending');

    final userIds = (userIdsResponse as List)
        .map((e) => e['user_id'] as String)
        .toList();
    if (userIds.isEmpty) return [];

    final response = await _supabase
        .from('users')
        .select()
        .filter('id', 'in', '(${userIds.join(",")})');

    return (response as List)
        .map((u) => app_model.User.fromJson(Map<String, dynamic>.from(u)))
        .toList();
  }

  Future<void> updateClassroom(Classroom classroom) async {
    await _supabase.from('classrooms').update({
      'name': classroom.name,
      'description': classroom.description,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', classroom.id);
  }

  Future<void> softDeleteClassroom(String classroomId) async {
    await _supabase.from('classrooms').update({
      'is_active': false,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', classroomId);
  }

}
