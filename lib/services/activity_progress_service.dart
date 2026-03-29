import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for saving activity progress (quizzes and games)
/// Uses the unified activity_progress table to prevent duplicates
class ActivityProgressService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Save quiz progress
  /// 
  /// This method automatically handles attempt numbering and prevents duplicates
  /// using database-level unique constraints.
  Future<void> saveQuizProgress({
    required String userId,
    required String quizId,
    required String quizTitle,
    required String operator,
    required int score, // Raw score (number of correct answers)
    required int totalQuestions,
    String? classroomId,
    String? lessonId,
    int? elapsedTime, // Time taken in seconds
  }) async {
    try {
      // Get next attempt number from database function
      final nextAttempt = await _supabase.rpc(
        'get_next_attempt_number',
        params: {
          'p_user_id': userId,
          'p_entity_type': 'quiz',
          'p_entity_id': quizId,
        },
      );

      await _supabase.from('activity_progress').insert({
        'user_id': userId,
        'entity_type': 'quiz',
        'entity_id': quizId,
        'entity_title': quizTitle,
        'operator': operator,
        'score': score,
        'total_items': totalQuestions,
        'attempt_number': nextAttempt,
        // score_percentage will be auto-calculated as a generated column
        'classroom_id': classroomId,
        'lesson_id': lessonId,
        'elapsed_time': elapsedTime,
      });
    } catch (e) {
      // If duplicate (unique constraint violation), ignore or log
      // The database will prevent the duplicate automatically
      rethrow;
    }
  }

  /// Save game progress
  /// 
  /// This method automatically handles attempt numbering and prevents duplicates
  /// using database-level unique constraints.
  /// 
  /// STRICT VALIDATION: Only saves if the game was actually played.
  /// "Try Again" scenarios are handled correctly - saves as a new attempt for the same game.
  Future<void> saveGameProgress({
    required String userId,
    String? gameId, // Prefer game_id if available
    required String gameTitle,
    required String operator,
    required String difficulty, // 'easy', 'medium', or 'hard'
    required int score, // Raw score (number of correct answers)
    required int totalItems, // Total rounds/items in the game
    String? status, // 'completed' or 'incomplete'
    int? elapsedTime, // Time taken in seconds
    String? classroomId,
  }) async {
    // STRICT VALIDATION: Only save if the game was actually played
    // Validate required fields
    if (userId.isEmpty) {
      throw ArgumentError('userId cannot be empty');
    }
    
    if (gameTitle.isEmpty) {
      throw ArgumentError('gameTitle cannot be empty');
    }
    
    if (operator.isEmpty) {
      throw ArgumentError('operator cannot be empty');
    }
    
    if (difficulty.isEmpty) {
      throw ArgumentError('difficulty cannot be empty');
    }
    
    // Validate game data - ensure game was actually played
    if (totalItems <= 0) {
      // If totalItems is 0 or negative, game wasn't properly initialized
      // Don't save invalid game data
      throw ArgumentError('totalItems must be greater than 0. Game may not have been properly started.');
    }
    
    // Score must be non-negative and not exceed totalItems
    if (score < 0) {
      throw ArgumentError('score cannot be negative');
    }
    
    if (score > totalItems) {
      throw ArgumentError('score cannot exceed totalItems');
    }
    
    // Validate that game was actually played - must have some time elapsed or score > 0
    // Even if score is 0, elapsedTime > 0 indicates the user started playing
    final hasPlayTime = (elapsedTime != null && elapsedTime > 0);
    final hasScore = (score > 0);
    
    if (!hasPlayTime && !hasScore) {
      // Game wasn't actually played - user didn't start or interact with it
      // Don't save this as a game attempt
      throw ArgumentError(
        'Game was not actually played. Must have elapsedTime > 0 or score > 0. '
        'This prevents saving games that were never started or interacted with.'
      );
    }
    
    try {
      // Get next attempt number from database function
      // This handles "Try Again" correctly by incrementing attempt number for the same game
      final nextAttempt = await _supabase.rpc(
        'get_next_attempt_number',
        params: {
          'p_user_id': userId,
          'p_entity_type': 'game',
          'p_entity_id': gameId,
          'p_entity_title': gameId == null ? gameTitle : null,
          'p_difficulty': difficulty.toLowerCase(),
        },
      );

      // Only save if validation passes
      await _supabase.from('activity_progress').insert({
        'user_id': userId,
        'entity_type': 'game',
        'entity_id': gameId, // Can be null if game_id not available yet
        'entity_title': gameTitle,
        'operator': operator,
        'difficulty': difficulty.toLowerCase(),
        'score': score,
        'total_items': totalItems,
        'attempt_number': nextAttempt,
        'status': status ?? (score >= totalItems ? 'completed' : 'incomplete'),
        'elapsed_time': elapsedTime ?? 0,
        // score_percentage will be auto-calculated as a generated column
        'classroom_id': classroomId,
      });
    } catch (e) {
      // Re-throw validation errors
      if (e is ArgumentError) {
        rethrow;
      }
      // If duplicate (unique constraint violation), ignore or log
      // The database will prevent the duplicate automatically
      rethrow;
    }
  }

  /// Get all progress for a user
  Future<List<Map<String, dynamic>>> getUserProgress({
    required String userId,
    String? classroomId,
    String? operator,
    String? entityType,
  }) async {
    var query = _supabase
        .from('activity_progress')
        .select()
        .eq('user_id', userId);

    if (classroomId != null && classroomId.isNotEmpty) {
      query = query.eq('classroom_id', classroomId);
    }

    if (operator != null) {
      query = query.eq('operator', operator);
    }

    if (entityType != null) {
      query = query.eq('entity_type', entityType);
    }

    final result = await query.order('created_at', ascending: false);
    return (result as List).cast<Map<String, dynamic>>();
  }

  /// Get latest attempt for each activity
  Future<List<Map<String, dynamic>>> getLatestAttempts({
    required String userId,
    String? classroomId,
    String? operator,
  }) async {
    // This query gets the latest attempt (highest attempt_number) for each entity
    var query = _supabase
        .from('activity_progress')
        .select()
        .eq('user_id', userId);

    if (classroomId != null && classroomId.isNotEmpty) {
      query = query.eq('classroom_id', classroomId);
    }

    if (operator != null) {
      query = query.eq('operator', operator);
    }

    final result = await query
        .order('entity_type')
        .order('entity_id')
        .order('attempt_number', ascending: false);
    final progressList = (result as List).cast<Map<String, dynamic>>();

    // Deduplicate to get only latest attempt per entity
    final Map<String, Map<String, dynamic>> latestMap = {};
    for (final progress in progressList) {
      final entityKey = progress['entity_id']?.toString() ?? 
                       '${progress['entity_title']}_${progress['difficulty']}';
      
      if (!latestMap.containsKey(entityKey)) {
        latestMap[entityKey] = progress;
      }
    }

    return latestMap.values.toList();
  }

  /// Get attempt count for a specific activity
  Future<int> getAttemptCount({
    required String userId,
    required String entityType,
    String? entityId,
    String? entityTitle,
    String? difficulty,
  }) async {
    var query = _supabase
        .from('activity_progress')
        .select('attempt_number')
        .eq('user_id', userId)
        .eq('entity_type', entityType);

    if (entityId != null) {
      query = query.eq('entity_id', entityId);
    } else if (entityTitle != null) {
      query = query.eq('entity_title', entityTitle);
      if (difficulty != null) {
        query = query.eq('difficulty', difficulty);
      }
    }

    final result = await query.count(CountOption.exact);
    return result.count ?? 0;
  }

  /// Get best score for a specific activity
  Future<Map<String, dynamic>?> getBestScore({
    required String userId,
    required String entityType,
    String? entityId,
    String? entityTitle,
    String? difficulty,
  }) async {
    var query = _supabase
        .from('activity_progress')
        .select()
        .eq('user_id', userId)
        .eq('entity_type', entityType);

    if (entityId != null) {
      query = query.eq('entity_id', entityId);
    } else if (entityTitle != null) {
      query = query.eq('entity_title', entityTitle);
      if (difficulty != null) {
        query = query.eq('difficulty', difficulty);
      }
    }

    final result = await query.order('score', ascending: false).limit(1).maybeSingle();
    return result as Map<String, dynamic>?;
  }
}

