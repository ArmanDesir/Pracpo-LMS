import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pracpro/models/user.dart' as app_model;

class UserService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> saveUser({
    required String id,
    required String email,
    required String name,
    required app_model.UserType userType,
    String? contactNumber,
    String? studentId,
    String? guardianName,
    String? guardianEmail,
    String? guardianContactNumber,
    String? studentInfo,
    String? teacherCode,
    int? grade,
  }) async {
    final response = await _supabase.from('users').insert({
      'id': id,
      'email': email,
      'name': name,
      'user_type': userType == app_model.UserType.student ? 'student' : 'teacher',
      'is_teacher': userType == app_model.UserType.teacher,
      'contact_number': contactNumber,
      'student_id': studentId,
      'guardian_name': guardianName,
      'guardian_email': guardianEmail,
      'guardian_contact_number': guardianContactNumber,
      'student_info': studentInfo,
      'teacher_code': teacherCode,
      'grade': grade,
      'is_online': true,
      'last_sync_time': DateTime.now().toIso8601String(),
    }).select().maybeSingle();

    if (response == null) {
      throw Exception('Insert failed: no record returned');
    }
  }

  Future<app_model.User?> getUser(String id) async {
    final response = await _supabase
        .from('users')
        .select('*')
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return app_model.User.fromJson(response);
  }

  Future<void> updateUser(app_model.User user) async {
    await _supabase.from('users').update({
      'name': user.name,
      'email': user.email,
      'contact_number': user.contactNumber,
      'guardian_name': user.guardianName,
      'guardian_email': user.guardianEmail,
      'guardian_contact_number': user.guardianContactNumber,
      'student_info': user.studentInfo,
      'user_type': user.userType.name,
      'photo_url': user.photoUrl,
    }).eq('id', user.id);
  }

}
