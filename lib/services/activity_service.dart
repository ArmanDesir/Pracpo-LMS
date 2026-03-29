import 'package:pracpro/models/activity_progress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ActivityService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<ActivityProgress>> getActivityProgress(String classroomId) async {
    // Query activity_progress directly since the view was dropped
    // Filter by classroom_id and get user names
    
    List<Map<String, dynamic>> progressList = [];
    
    try {
      // Query by selected classroom_id - validates that classroom_id in activity_progress matches selected classroom
      var query = _supabase
          .from('activity_progress')
        .select('''
            id,
            user_id,
            entity_type,
            entity_id,
            entity_title,
            operator,
            difficulty,
            score,
            total_items,
            attempt_number,
            status,
            classroom_id,
            created_at
        ''')
          .eq('classroom_id', classroomId)  // Filter by selected classroom - validates match
          .order('created_at', ascending: false)
          .limit(200);

      final res = await query;
      if (res is! List) {
        return [];
      }

      progressList = (res as List).cast<Map<String, dynamic>>();
    } catch (e, stackTrace) {
      return [];
    }
    
    // Get user names for all user_ids
    final userIds = progressList
        .map((p) => p['user_id']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    
    final Map<String, String> usersMap = {};
    if (userIds.isNotEmpty) {
      try {
        final usersRes = await _supabase
            .from('users')
            .select('id, name')
            .inFilter('id', userIds);
        
        if (usersRes is List) {
          for (final user in usersRes) {
            final userId = user['id']?.toString();
            final userName = user['name']?.toString();
            if (userId != null && userName != null) {
              usersMap[userId] = userName;
            }
          }
        }
      } catch (e) {
        // Ignore errors fetching user names
      }
    }

    // Map to ActivityProgress model
    final List<ActivityProgress> activities = [];
    for (final progress in progressList) {
      final entityType = progress['entity_type']?.toString() ?? '';
      final operator = progress['operator']?.toString() ?? '';
      final difficulty = progress['difficulty']?.toString() ?? '';
      final totalItems = progress['total_items'] as int? ?? 0;
      
      // Format stage field (operator|difficulty for games, operator|total_items for quizzes)
      String stage = operator;
      if (entityType == 'game' && difficulty.isNotEmpty) {
        stage = '$operator|$difficulty|$totalItems';
      } else if (entityType == 'quiz') {
        stage = '$operator|$totalItems';
      }
      
      // Format title with difficulty for games
      String displayTitle = progress['entity_title']?.toString() ?? 'Unknown';
      if (entityType == 'game' && difficulty.isNotEmpty) {
        final difficultyCapitalized = difficulty.substring(0, 1).toUpperCase() + difficulty.substring(1);
        displayTitle = '$displayTitle ($difficultyCapitalized)';
      }

      activities.add(ActivityProgress(
        source: 'activity_progress',
        sourceId: progress['id']?.toString() ?? '',
        userId: progress['user_id']?.toString(),
        userName: usersMap[progress['user_id']?.toString() ?? ''],
        entityType: entityType,
        entityId: progress['entity_id']?.toString(),
        entityTitle: displayTitle,
        stage: stage,
        score: progress['score'] as int?,
        attempt: totalItems, // Use total_items for display (score/total_items format)
        highestScore: progress['score'] as int?,
        tries: progress['attempt_number'] as int?,
        status: progress['status']?.toString(),
        classroomId: progress['classroom_id']?.toString() ?? classroomId,
        createdAt: DateTime.parse(progress['created_at']?.toString() ?? DateTime.now().toIso8601String()),
      ));
    }

    return activities;
  }
}
