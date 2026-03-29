import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:pracpro/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/database_helper.dart';
import '../models/task.dart';
class SyncService {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final SupabaseService _supabaseService = SupabaseService();
  final Connectivity _connectivity = Connectivity();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _syncTimer;
  bool _isOnline = false;

  SyncService() {
    _initializeConnectivity();
    _startPeriodicSync();
  }

  void _initializeConnectivity() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
        results,
        ) {
      _isOnline =
          results.isNotEmpty && results.first != ConnectivityResult.none;
      if (_isOnline) {
        _performSync();
      }
    });
  }

  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (_isOnline) {
        _performSync();
      }
    });
  }

  Future<void> _performSync() async {
    try {
      await _syncTasksToSupabase();
      await _syncTasksFromSupabase();
    } catch (e) {
      // Error during sync - continue silently
    }
  }

  Future<Task> createTask(Task task) async {
    await _databaseHelper.insertTask(task);
    if (_isOnline) {
      try {
        final supabaseId = await _supabaseService.createTask(task);
        final updatedTask = task.copyWith(
          id: supabaseId,
          isSynced: true,
        );
        await _databaseHelper.updateTask(updatedTask);
        return updatedTask;
      } catch (e) {
        // Error syncing task - continue silently
      }
    }
    return task;
  }

  Future<Task?> updateTask(Task task) async {
    await _databaseHelper.updateTask(task);

    if (_isOnline) {
      try {
        await _supabaseService.updateTask(task);
        final updatedTask = task.copyWith(isSynced: true);
        await _databaseHelper.updateTask(updatedTask);
        return updatedTask;
      } catch (e) {
        final unsyncedTask = task.copyWith(isSynced: false);
        await _databaseHelper.updateTask(unsyncedTask);
      }
    }

    return task;
  }

  Future<void> deleteTask(String taskId) async {
    final task = await _databaseHelper.getTaskById(taskId);
    if (task != null) {
      await _databaseHelper.deleteTask(taskId);
      if (_isOnline) {
        try {
          await _supabaseService.deleteTask(task.id);
        } catch (e) {
          // Error deleting task - continue silently
        }
      }
    }
  }

  Future<List<Task>> getTasksByUserId(String userId) async {
    List<Task> localTasks = await _databaseHelper.getTasksByUserId(userId);
    if (_isOnline) {
      try {
        final supabaseTasks = await _supabaseService.getTasksByUserId(userId);
        await _mergeTasks(localTasks, supabaseTasks);
        return await _databaseHelper.getTasksByUserId(userId);
      } catch (e) {
        // Error syncing tasks - continue silently
      }
    }
    return localTasks;
  }

  Future<void> _mergeTasks(
      List<Task> localTasks,
      List<Task> supabaseTasks,
      ) async {
    final localTaskMap = {
      for (final task in localTasks) task.id: task,
    };
    final supabaseTaskMap = {
      for (final task in supabaseTasks) task.id: task,
    };

    for (final supabaseTask in supabaseTasks) {
      if (!localTaskMap.containsKey(supabaseTask.id)) {
        final newTask = supabaseTask.copyWith(isSynced: true);
        await _databaseHelper.insertTask(newTask);
      }
    }

    for (final localTask in localTasks) {
      if (supabaseTaskMap.containsKey(localTask.id)) {
        final supabaseTask = supabaseTaskMap[localTask.id]!;
        if (supabaseTask.updatedAt.isAfter(localTask.updatedAt)) {
          final updatedTask = supabaseTask.copyWith(
            isSynced: true,
          );
          await _databaseHelper.updateTask(updatedTask);
        }
      }
    }
  }

  Future<void> _syncTasksToSupabase() async {
    final unsyncedTasks = await _databaseHelper.getUnsyncedTasks();
    for (final task in unsyncedTasks) {
      try {
        if (task.id.startsWith('temp_')) {
          final supabaseId = await _supabaseService.createTask(task);
          final updatedTask = task.copyWith(
            id: supabaseId,
            isSynced: true,
          );
          await _databaseHelper.updateTask(updatedTask);
        } else {
          await _supabaseService.updateTask(task);
          final updatedTask = task.copyWith(isSynced: true);
          await _databaseHelper.updateTask(updatedTask);
        }
      } catch (e) {
        // Error syncing task - continue silently
      }
    }
  }

  Future<void> _syncTasksFromSupabase() async {
  }

  bool get isOnline => _isOnline;

  void dispose() {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
  }
}
