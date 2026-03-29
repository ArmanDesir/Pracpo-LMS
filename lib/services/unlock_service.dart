import 'package:supabase_flutter/supabase_flutter.dart';

class UnlockService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  /// Test if the RPC function is available (cache refreshed)
  /// Returns true if RPC is accessible, false if it's still in cache
  Future<Map<String, dynamic>> testRpcAvailability() async {
    try {
      // Try to call the RPC with dummy parameters to test availability
      await _supabase.rpc(
        'unlock_after_quiz_completion',
        params: {
          'p_user_id': '00000000-0000-0000-0000-000000000000',
          'p_quiz_id': '00000000-0000-0000-0000-000000000000',
          'p_score': 0,
          'p_total_questions': 1,
          'p_attempts_count': 1,
        },
      );
      
      return {
        'available': true,
        'message': 'RPC function is available (cache refreshed!)',
      };
    } catch (e, stackTrace) {
      final errorStr = e.toString();
      if (errorStr.contains('schema cache') || errorStr.contains('PGRST202')) {
        return {
          'available': false,
          'message': 'RPC function not yet in cache (still using client-side fallback)',
          'error': errorStr,
        };
      } else {
        // Other errors (like invalid parameters) mean the function IS available
        return {
          'available': true,
          'message': 'RPC function is available (cache refreshed!)',
          'note': 'Got parameter validation error, which means function exists',
        };
      }
    }
  }

  /// Check if a lesson or quiz should be unlocked after quiz completion
  /// Uses database RPC function for atomic, server-side processing
  Future<Map<String, dynamic>?> checkAndUnlockAfterQuiz({
    required String userId,
    required String quizId,
    required int score,
    required int totalQuestions,
    required int attemptsCount,
    String? lessonId, // Optional lesson ID - if provided, checks if quiz is quiz 1 of that lesson
  }) async {
    // Validate UUID parameters - skip RPC if invalid, fall through to client-side
    // Note: If lessonId is provided, we must use client-side logic since RPC doesn't support lessonId yet
    if (userId.isNotEmpty && quizId.isNotEmpty && (lessonId == null || lessonId.isEmpty)) {
      // First, try the RPC function (preferred - atomic and server-side)
      // Only use RPC if lessonId is not provided (RPC doesn't support lessonId yet)
      try {
        final result = await _supabase.rpc(
          'unlock_after_quiz_completion',
          params: {
            'p_user_id': userId,
            'p_quiz_id': quizId,
            'p_score': score,
            'p_total_questions': totalQuestions,
            'p_attempts_count': attemptsCount,
          },
        );
        
        // RPC succeeded - cache has refreshed!
        final resultMap = result as Map<String, dynamic>?;
        if (resultMap != null) {
          resultMap['_method'] = 'rpc'; // Mark that RPC was used
        }
        return resultMap;
      } catch (e, stackTrace) {
        final errorStr = e.toString().toLowerCase();
        // Check for schema cache errors - if found, silently fall back to client-side
        final isSchemaCacheError = errorStr.contains('schema cache') ||
            errorStr.contains('pgrst202') ||
            errorStr.contains('could not find the function');
        
        // Check for UUID validation errors - also fall back to client-side
        final isUuidError = errorStr.contains('invalid input syntax for type uuid') ||
            errorStr.contains('22p02');
        
        if (isUuidError) {
          // UUID error - fall through to client-side implementation
        } else if (!isSchemaCacheError) {
          // For other errors, return them
          return {
            'unlocked': false,
            'error': e.toString(),
          };
        }
        // Schema cache error - silently fall through to client-side implementation
      }
    } else if (lessonId != null && lessonId.isNotEmpty) {
      // Fall through to client-side implementation when lessonId is provided
    } else {
      // Fall through to client-side implementation if UUIDs are invalid
    }
    
    // Client-side fallback (used when RPC is not available due to schema cache)
    try {
      // Calculate passing rate
      final passingRate = totalQuestions > 0 ? (score / totalQuestions * 100) : 0;
      
      // Check unlock conditions: 80% passing rate OR 3rd attempt
      final shouldUnlock = (passingRate >= 80) || (attemptsCount >= 3);
      
      if (!shouldUnlock) {
        return {
          'unlocked': false,
          'message': 'Unlock conditions not met',
        };
      }
      
      // Get quiz information
      final quizResult = await _supabase
          .from('basic_operator_quizzes')
          .select('id, operator, classroom_id, created_at')
          .eq('id', quizId)
          .maybeSingle();
      
      if (quizResult == null) {
        return {
          'unlocked': false,
          'message': 'Quiz not found',
        };
      }
      
      final operator = quizResult['operator'] as String?;
      final classroomIdRaw = quizResult['classroom_id'];
      // Handle empty strings - convert to null for UUID safety
      final classroomId = (classroomIdRaw is String && classroomIdRaw.isEmpty) 
          ? null 
          : classroomIdRaw as String?;
      final currentQuizCreatedAt = quizResult['created_at'] as String?;
      
      if (operator == null) {
        return {
          'unlocked': false,
          'message': 'Quiz operator not found',
        };
      }
      
      // Check if this is quiz 1
      // If lessonId is provided, check if it's the first quiz completed for that lesson
      // Otherwise, check if it's the oldest quiz for this operator/classroom
      bool isQuiz1 = false;
      
      if (lessonId != null && lessonId.isNotEmpty) {
        // Check if this is the first quiz completed for this lesson
        final lessonQuizProgress = await _supabase
            .from('activity_progress')
            .select('entity_id, created_at')
            .eq('user_id', userId)
            .eq('entity_type', 'quiz')
            .eq('lesson_id', lessonId)
            .order('created_at', ascending: true)
            .limit(1);
        
        if (lessonQuizProgress is List && lessonQuizProgress.isNotEmpty) {
          final firstQuizForLesson = lessonQuizProgress[0]['entity_id']?.toString();
          isQuiz1 = (firstQuizForLesson == quizId);
        } else {
          // This is the first quiz for this lesson
          isQuiz1 = true;
        }
      } else {
        // Fallback: Check if this is quiz 1 globally (oldest quiz by creation date)
        var firstQuizQuery = _supabase
            .from('basic_operator_quizzes')
            .select('id, created_at')
            .eq('operator', operator);
        
        if (classroomId != null && classroomId.isNotEmpty) {
          firstQuizQuery = firstQuizQuery.eq('classroom_id', classroomId);
        } else {
          firstQuizQuery = firstQuizQuery.isFilter('classroom_id', null);
        }
        
        final firstQuizResult = await firstQuizQuery
            .order('created_at', ascending: true)
            .limit(1);
        
        // Compare quiz IDs directly to determine if this is quiz 1
        isQuiz1 = firstQuizResult is List && 
            firstQuizResult.isNotEmpty && 
            firstQuizResult[0]['id']?.toString() == quizId;
      }
      
      // Only unlock if this is quiz 1
      if (!isQuiz1) {
        return {
          'unlocked': false,
          'message': 'Only quiz 1 can unlock the next lesson',
          'is_quiz_1': false,
        };
      }
      
      final unlockedItems = <Map<String, dynamic>>[];
      
      // Find the highest (most recently created) unlocked lesson for this user
      // The first lesson (oldest) should be unlocked by default
      // Then unlock the next lesson after the highest unlocked one
      
      // Get unlocked lesson IDs for this user
      var unlockedLessonIdsQuery = _supabase
          .from('unlocked_content')
          .select('entity_id')
          .eq('user_id', userId)
          .eq('entity_type', 'lesson')
          .eq('operator', operator);
      
      if (classroomId != null && classroomId.isNotEmpty) {
        unlockedLessonIdsQuery = unlockedLessonIdsQuery.eq('classroom_id', classroomId);
      } else {
        unlockedLessonIdsQuery = unlockedLessonIdsQuery.isFilter('classroom_id', null);
      }
      
      final unlockedLessonIdsResult = await unlockedLessonIdsQuery;
      final unlockedLessonIds = (unlockedLessonIdsResult as List)
          .map((e) => e['entity_id']?.toString())
          .where((id) => id != null && id.isNotEmpty)
          .cast<String>()
          .toList();
      
      // Find the highest unlocked lesson's created_at (most recently created)
      String? highestUnlockedLessonCreatedAt;
      if (unlockedLessonIds.isNotEmpty) {
        var highestLessonQuery = _supabase
            .from('basic_operator_lessons')
            .select('created_at')
            .eq('operator', operator)
            .eq('is_active', true)
            .inFilter('id', unlockedLessonIds);
        
        if (classroomId != null && classroomId.isNotEmpty) {
          highestLessonQuery = highestLessonQuery.eq('classroom_id', classroomId);
        } else {
          highestLessonQuery = highestLessonQuery.isFilter('classroom_id', null);
        }
        
        final highestLessons = await highestLessonQuery
            .order('created_at', ascending: false)
            .limit(1);
        
        if (highestLessons is List && highestLessons.isNotEmpty) {
          highestUnlockedLessonCreatedAt = highestLessons[0]['created_at']?.toString();
        }
      }
      
      // If no unlocked lesson found, use first lesson's created_at as baseline
      // (First lesson - oldest - should be unlocked by default)
      if (highestUnlockedLessonCreatedAt == null) {
        var firstLessonQuery = _supabase
            .from('basic_operator_lessons')
            .select('created_at')
            .eq('operator', operator)
            .eq('is_active', true);
        
        if (classroomId != null && classroomId.isNotEmpty) {
          firstLessonQuery = firstLessonQuery.eq('classroom_id', classroomId);
        } else {
          firstLessonQuery = firstLessonQuery.isFilter('classroom_id', null);
        }
        
        final firstLessons = await firstLessonQuery
            .order('created_at', ascending: true)
            .limit(1);
        
        if (firstLessons is List && firstLessons.isNotEmpty) {
          highestUnlockedLessonCreatedAt = firstLessons[0]['created_at']?.toString();
        }
      }
      
      // Find the next lesson after the highest unlocked one (or after first lesson)
      // This will unlock the next oldest lesson that isn't unlocked yet
      String? nextLessonId;
      if (highestUnlockedLessonCreatedAt != null) {
        var nextLessonQuery = _supabase
            .from('basic_operator_lessons')
            .select('id')
            .eq('operator', operator)
            .eq('is_active', true)
            .gt('created_at', highestUnlockedLessonCreatedAt);
        
        if (classroomId != null && classroomId.isNotEmpty) {
          nextLessonQuery = nextLessonQuery.eq('classroom_id', classroomId);
        } else {
          nextLessonQuery = nextLessonQuery.isFilter('classroom_id', null);
        }
        
        final nextLessons = await nextLessonQuery
            .order('created_at', ascending: true)
            .limit(1);
        
        if (nextLessons is List && nextLessons.isNotEmpty) {
          nextLessonId = nextLessons[0]['id']?.toString();
        }
      }
      
      // Unlock next lesson
      if (nextLessonId != null) {
        try {
          final unlockData = {
            'user_id': userId,
            'entity_type': 'lesson',
            'entity_id': nextLessonId,
            'operator': operator,
          };
          // Only include classroom_id if it's not null/empty
          if (classroomId != null && classroomId.isNotEmpty) {
            unlockData['classroom_id'] = classroomId;
          }
          await _supabase.from('unlocked_content').insert(unlockData);
          
          unlockedItems.add({
            'type': 'lesson',
            'id': nextLessonId,
          });
        } catch (e) {
          // Ignore duplicate key errors
        }
      }
      
      // Note: We don't unlock additional quizzes - only the next lesson
      // The requirement is that only quiz 1 unlocks lesson 2
      
      final result = {
        'unlocked': true,
        'items': unlockedItems,
        'passing_rate': passingRate,
        'is_quiz_1': true,
        '_method': 'client-side', // Mark that client-side fallback was used
      };
      return result;
    } catch (e, stackTrace) {
      return {
        'unlocked': false,
        'error': e.toString(),
      };
    }
  }

  /// Check if a lesson is unlocked for a user
  Future<bool> isLessonUnlocked({
    required String userId,
    required String lessonId,
  }) async {
    try {
      final result = await _supabase
          .from('unlocked_content')
          .select('id')
          .eq('user_id', userId)
          .eq('entity_type', 'lesson')
          .eq('entity_id', lessonId)
          .maybeSingle();
      
      return result != null;
    } catch (e, stackTrace) {
      return false;
    }
  }

  /// Check if a quiz is unlocked for a user
  Future<bool> isQuizUnlocked({
    required String userId,
    required String quizId,
  }) async {
    try {
      final result = await _supabase
          .from('unlocked_content')
          .select('id')
          .eq('user_id', userId)
          .eq('entity_type', 'quiz')
          .eq('entity_id', quizId)
          .maybeSingle();
      
      return result != null;
    } catch (e, stackTrace) {
      return true;
    }
  }

  /// Get all unlocked items for a user
  Future<Map<String, Set<String>>> getUnlockedItems({
    required String userId,
    String? operator,
    String? classroomId,
  }) async {
    try {
      var query = _supabase
          .from('unlocked_content')
          .select('entity_type, entity_id')
          .eq('user_id', userId);

      if (operator != null) {
        query = query.eq('operator', operator);
      }

      if (classroomId != null && classroomId.isNotEmpty) {
        query = query.eq('classroom_id', classroomId);
      }

      final result = await query;
      final items = (result as List).cast<Map<String, dynamic>>();

      final unlockedLessons = <String>{};
      final unlockedQuizzes = <String>{};

      for (final item in items) {
        final type = item['entity_type']?.toString() ?? '';
        final id = item['entity_id']?.toString() ?? '';
        if (type == 'lesson' && id.isNotEmpty) {
          unlockedLessons.add(id);
        } else if (type == 'quiz' && id.isNotEmpty) {
          unlockedQuizzes.add(id);
        }
      }

      return {
        'lessons': unlockedLessons,
        'quizzes': unlockedQuizzes,
      };
    } catch (e, stackTrace) {
      return {'lessons': <String>{}, 'quizzes': <String>{}};
    }
  }

  /// Unlock first lesson and first quiz for a new user
  Future<void> initializeFirstUnlocks({
    required String userId,
    required String operator,
    String? classroomId,
  }) async {
    try {
      // Get first lesson - build complete query before awaiting
      var firstLessonQuery = _supabase
          .from('basic_operator_lessons')
          .select('id')
          .eq('operator', operator)
          .eq('is_active', true);

      if (classroomId != null && classroomId.isNotEmpty) {
        firstLessonQuery = firstLessonQuery.eq('classroom_id', classroomId);
      }
      
      final firstLesson = await firstLessonQuery
          .order('created_at', ascending: true)
          .limit(1);

      String? firstLessonId;
      if (firstLesson is List && firstLesson.isNotEmpty) {
        firstLessonId = firstLesson[0]['id']?.toString();
      }

      // Get first quiz by operator/classroom (lesson_id column doesn't exist)
      String? firstQuizId;
      var firstQuizQuery = _supabase
          .from('basic_operator_quizzes')
          .select('id')
          .eq('operator', operator);

      if (classroomId != null && classroomId.isNotEmpty) {
        firstQuizQuery = firstQuizQuery.eq('classroom_id', classroomId);
      }

      // Chain order and limit directly without reassigning
      final firstQuiz = await firstQuizQuery
          .order('created_at', ascending: true)
          .limit(1);

      if (firstQuiz is List && firstQuiz.isNotEmpty) {
        firstQuizId = firstQuiz[0]['id']?.toString();
      }

      // Insert initial unlocks
      final unlocksToCreate = <Map<String, dynamic>>[];

      if (firstLessonId != null) {
        unlocksToCreate.add({
          'user_id': userId,
          'entity_type': 'lesson',
          'entity_id': firstLessonId,
          'operator': operator,
          if (classroomId != null && classroomId.isNotEmpty) 'classroom_id': classroomId,
        });
      }

      if (firstQuizId != null) {
        unlocksToCreate.add({
          'user_id': userId,
          'entity_type': 'quiz',
          'entity_id': firstQuizId,
          'operator': operator,
          if (classroomId != null && classroomId.isNotEmpty) 'classroom_id': classroomId,
        });
      }

      for (final unlock in unlocksToCreate) {
        try {
          await _supabase
              .from('unlocked_content')
              .insert(unlock)
              .select();
        } catch (e) {
          // Ignore duplicate key errors
        }
      }
    } catch (e, stackTrace) {
      // Error initializing unlocks - silently fail
    }
  }
}

