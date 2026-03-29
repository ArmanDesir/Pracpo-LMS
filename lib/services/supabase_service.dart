import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as app_model;
import '../models/task.dart';
import '../models/classroom.dart';

class SupabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<AuthResponse?> signInWithEmailAndPassword(
      String email,
      String password,
      ) async {
    try {
      return await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      return null;
    }
  }

  Future<AuthResponse?> createUserWithEmailAndPassword(
      String email,
      String password,
      ) async {
    try {
      return await _supabase.auth.signUp(
        email: email,
        password: password,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<void> createUser(app_model.User user) async {
    try {
      await _supabase.from('users').insert(user.toJson());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateUser(app_model.User user) async {
    try {
      await _supabase.from('users').update(user.toJson()).eq('id', user.id);
    } catch (e) {
      rethrow;
    }
  }

  Future<app_model.User?> getUserById(String id) async {
    try {
      final response = await _supabase.from('users').select().eq('id', id).single();
      return app_model.User.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<List<app_model.User>> getAllUsers() async {
    try {
      final response = await _supabase.from('users').select();
      return response.map((data) => app_model.User.fromJson(data)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<String> createTask(Task task) async {
    try {
      final response = await _supabase.from('tasks').insert(task.toJson()).select().single();
      return response['id'] as String;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateTask(Task task) async {
    try {
      await _supabase.from('tasks').update(task.toJson()).eq('id', task.id);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _supabase.from('tasks').delete().eq('id', taskId);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Task>> getTasksByUserId(String userId) async {
    try {
      final response = await _supabase.from('tasks').select().eq('user_id', userId);
      return response.map((data) => Task.fromJson(data)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<String> createClassroom(Classroom classroom) async {
    try {
      final jsonData = classroom.toJson();
      if (jsonData.containsKey('is_archived')) {
        jsonData['is_active'] = !(jsonData['is_archived'] as bool);
        jsonData.remove('is_archived');
      }
      final response = await _supabase.from('classrooms').insert(jsonData).select().single();
      return response['id'] as String;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateClassroom(Classroom classroom) async {
    try {
      final jsonData = classroom.toJson();
      if (jsonData.containsKey('is_archived')) {
        jsonData['is_active'] = !(jsonData['is_archived'] as bool);
        jsonData.remove('is_archived');
      }
      await _supabase.from('classrooms').update(jsonData).eq('id', classroom.id);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteClassroom(String classroomId) async {
    try {
      await _supabase.from('classrooms').delete().eq('id', classroomId);
    } catch (e) {
      rethrow;
    }
  }

  Future<Classroom?> getClassroomById(String classroomId) async {
    try {
      final response = await _supabase.from('classrooms').select().eq('id', classroomId).single();
      return Classroom.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<List<Classroom>> getClassroomsByTeacherId(String teacherId) async {
    try {
      final response = await _supabase.from('classrooms').select().eq('teacher_id', teacherId);
      return response.map((data) => Classroom.fromJson(data)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Classroom>> getAllClassrooms() async {
    try {
      final response = await _supabase.from('classrooms').select();
      return response.map((data) => Classroom.fromJson(data)).toList();
    } catch (e) {
      return [];
    }
  }
}
