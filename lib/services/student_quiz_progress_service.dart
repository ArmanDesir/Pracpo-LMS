import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuizProgressData {
  final String quizId;
  final String quizTitle;
  final int totalQuestions;
  final int? try1Score;
  final int? try2Score;
  final int? try3Score;
  final int attemptsCount;
  final int highestScore;
  final bool isGame;
  final String? difficulty; 
  final String? lessonTitle;
  final String? operator; 

  QuizProgressData({
    required this.quizId,
    required this.quizTitle,
    required this.totalQuestions,
    this.try1Score,
    this.try2Score,
    this.try3Score,
    required this.attemptsCount,
    required this.highestScore,
    this.isGame = false,
    this.difficulty,
    this.lessonTitle,
    this.operator,
  });

  double? _getActualScore(int? score) {
    if (score == null) return null;
    // Scores in activity_progress are already raw scores (number correct)
    // For quizzes, they're stored as raw scores, not percentages
      return score.toDouble();
  }

  int get totalActualScore {
    // For games, we need to sum ALL attempts, not just the 3 displayed
    // The service should pass all scores, but for backward compatibility,
    // we'll sum the displayed scores. The service will handle summing all attempts.
    final scores = [try1Score, try2Score, try3Score]
        .map((p) => _getActualScore(p))
        .where((s) => s != null)
        .cast<double>()
        .toList();
    return scores.fold(0.0, (sum, score) => sum + score).round();
  }

  int get totalPossible {
    // For games, totalPossible should be totalQuestions * attemptsCount
    // Each attempt has the same number of items (rounds), so multiply by number of attempts
    if (isGame) {
      return totalQuestions * attemptsCount;
    }

    // For quizzes, calculate based on attempts
    final actualAttempts = [try1Score, try2Score, try3Score]
        .where((s) => s != null)
        .length;
    final maxAttempts = actualAttempts > 3 ? 3 : actualAttempts;
    return totalQuestions * maxAttempts;
  }
  
  int get totalScore {
    return totalActualScore;
  }
  
  double get passingRate {
    return generalAverage;
  }

  double get generalAverage {
    final scores = [try1Score, try2Score, try3Score].where((s) => s != null).cast<int>().toList();
    if (scores.isEmpty) return 0;

    if (isGame) {
      // For games, calculate average percentage
      if (totalQuestions > 0) {
        final percentages = scores.map((score) => (score / totalQuestions) * 100).toList();
        return percentages.reduce((a, b) => a + b) / percentages.length;
      }
      return scores.reduce((a, b) => a + b) / scores.length;
    }

    // For quizzes, scores are raw (number correct), calculate average percentage
    if (totalQuestions > 0) {
      final percentages = scores.map((score) => (score / totalQuestions) * 100).toList();
      return percentages.reduce((a, b) => a + b) / percentages.length;
    }
    
    return 0;
  }

  int get highestScorePercentage {
    if (isGame) {
      // For games, scores are raw (number correct)
      if (totalQuestions > 0 && highestScore > 0) {
        return ((highestScore / totalQuestions) * 100).round();
      }
      return 0;
    }

    // For quizzes, scores are raw (number correct), calculate percentage
    if (totalQuestions > 0 && highestScore > 0) {
      return ((highestScore / totalQuestions) * 100).round();
    }
    return 0;
  }
}

class StudentQuizProgressService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<QuizProgressData>> getStudentAllProgress({
    required String studentId,
    required String classroomId,
  }) async {
    final allProgress = <QuizProgressData>[];
    
    for (final op in ['addition', 'subtraction', 'multiplication', 'division']) {
      final progress = await getStudentQuizProgress(
        studentId: studentId,
        operator: op,
        classroomId: classroomId,
      );
      allProgress.addAll(progress);
    }
    
    return allProgress;
  }

  /// Get student quiz and game progress from unified activity_progress table
  Future<List<QuizProgressData>> getStudentQuizProgress({
    required String studentId,
    required String operator,
    required String classroomId,
  }) async {
    try {
      
      // Query activity_progress filtering by:
      // 1. Student user_id
      // 2. Operator
      // Note: We do client-side filtering for classroom_id to handle null values properly
      final allProgress = await _supabase
          .from('activity_progress')
          .select('*')
          .eq('user_id', studentId)
          .eq('operator', operator)
          .order('created_at', ascending: false);
      
      final progressList = (allProgress as List).cast<Map<String, dynamic>>();
      
      // Client-side filtering: Include records where classroom_id matches OR is null
      // This ensures progress saved before classroom_id was properly tracked still shows
      // If classroomId is empty, show all progress (backward compatibility)
      final filteredProgress = progressList.where((progress) {
        // If no classroom filter specified, show all progress
        if (classroomId.isEmpty || classroomId.trim().isEmpty) {
          return true;
        }
        
        // Get classroom_id from progress record, handling various types
        final progressClassroomIdRaw = progress['classroom_id'];
        String? progressClassroomId;
        
        if (progressClassroomIdRaw == null) {
          // Progress with null classroom_id - include for backward compatibility
          return true;
        } else if (progressClassroomIdRaw is String) {
          progressClassroomId = progressClassroomIdRaw.trim();
        } else {
          progressClassroomId = progressClassroomIdRaw.toString().trim();
        }
        
        // If progress has empty/null classroom_id, include it (backward compatibility)
        if (progressClassroomId == null || progressClassroomId.isEmpty) {
          return true;
        }
        
        // Compare normalized IDs (trim for safety, UUIDs are case-insensitive but normalize anyway)
        final normalizedProgressId = progressClassroomId.toLowerCase().trim();
        final normalizedClassroomId = classroomId.toLowerCase().trim();
        
        // Include if classroom_id matches
        return normalizedProgressId == normalizedClassroomId;
      }).toList();
      

      // Get quiz metadata for calculating total questions
      final quizzesResponse = await _supabase
          .from('basic_operator_quizzes')
          .select('id, title, classroom_id, basic_operator_quiz_questions(id)')
          .eq('operator', operator);

      List<Map<String, dynamic>> quizzes = (quizzesResponse as List).cast<Map<String, dynamic>>();
      if (classroomId.isNotEmpty) {
        quizzes = quizzes.where((q) => q['classroom_id']?.toString() == classroomId).toList();
      }

      // Group progress by entity (quiz or game)
      final Map<String, List<Map<String, dynamic>>> progressByEntity = {};

      for (final progress in filteredProgress) {
        final entityType = progress['entity_type']?.toString() ?? '';
        String? entityKey;

        if (entityType == 'quiz') {
          // For quizzes, use entity_id as key
          final entityId = progress['entity_id']?.toString();
          if (entityId != null && entityId.isNotEmpty) {
            entityKey = entityId;
          }
        } else if (entityType == 'game') {
          // For games, prioritize entity_id if available, otherwise use entity_title + difficulty + operator
          // This ensures games with different entity_ids (even same title) are grouped separately
          final entityId = progress['entity_id']?.toString();
          final entityTitle = progress['entity_title']?.toString() ?? '';
          final difficulty = progress['difficulty']?.toString() ?? '';
          final gameOperator = progress['operator']?.toString() ?? '';
          
          if (entityId != null && entityId.isNotEmpty) {
            // Use entity_id as key (most reliable for games with IDs)
            entityKey = entityId;
          } else if (entityTitle.isNotEmpty) {
            // For games without entity_id (like Crossword Math), use title + difficulty + operator
            // This ensures same game name across different operators are grouped separately
            entityKey = '$entityTitle|${difficulty.toLowerCase()}|$gameOperator';
          }
        }

        if (entityKey != null && entityKey.isNotEmpty) {
          progressByEntity.putIfAbsent(entityKey, () => []).add(progress);
        }
      }

      final List<QuizProgressData> results = [];

      // Process each entity's progress
      for (final entry in progressByEntity.entries) {
        final entityKey = entry.key;
        final attempts = entry.value;
        
        // Sort attempts by attempt_number (ascending) to get chronological order
        attempts.sort((a, b) {
          final aNum = a['attempt_number'] as int? ?? 0;
          final bNum = b['attempt_number'] as int? ?? 0;
          return aNum.compareTo(bNum);
        });

        if (attempts.isEmpty) continue;

        final firstAttempt = attempts.first;
        final entityType = firstAttempt['entity_type']?.toString() ?? '';
        final isGame = entityType == 'game';

        // Get metadata and calculate totals
        String quizTitle = 'Unknown';
        int totalQuestions = 0;
        String? lessonTitle;
        String? difficulty;

        if (isGame) {
          // For games
          quizTitle = firstAttempt['entity_title']?.toString() ?? 'Unknown Game';
          difficulty = firstAttempt['difficulty']?.toString();
          totalQuestions = firstAttempt['total_items'] as int? ?? 0;

          // If total_items is 0, try to get from game config
          if (totalQuestions == 0) {
            final entityId = firstAttempt['entity_id']?.toString();
            if (entityId != null) {
              try {
                final gameResponse = await _supabase
                    .from('operator_games')
                    .select('''
                      id,
                      operator_game_variants_game_id_fkey (
                        difficulty,
                        config
                      )
                    ''')
                    .eq('id', entityId)
                    .maybeSingle();

                if (gameResponse != null) {
                  final variants = gameResponse['operator_game_variants_game_id_fkey'] as List?;
                  if (variants != null) {
                    for (final variant in variants) {
                      if (variant is Map) {
                        final variantDifficulty = variant['difficulty']?.toString().toLowerCase() ?? '';
                        if (variantDifficulty == difficulty?.toLowerCase()) {
                          final config = variant['config'];
                          if (config is Map) {
                            final rounds = config['rounds'];
                            if (rounds is int && rounds > 0) {
                              totalQuestions = rounds;
                              break;
                            } else if (rounds is String) {
                              totalQuestions = int.tryParse(rounds) ?? 0;
                              if (totalQuestions > 0) break;
                            }
                          } else if (config is String) {
                            try {
                              final configMap = Map<String, dynamic>.from(jsonDecode(config) as Map);
                              final rounds = configMap['rounds'];
                              if (rounds is int && rounds > 0) {
                                totalQuestions = rounds;
            break;
                              } else if (rounds is String) {
                                totalQuestions = int.tryParse(rounds) ?? 0;
                                if (totalQuestions > 0) break;
                              }
                            } catch (e) {
                              // Ignore JSON parse errors
                            }
                          }
                        }
                      }
                    }
                  }
                }
              } catch (e) {
                // Ignore errors
              }
            }
          }

          // Fallback for Crossword Math - count blank cells
          if (totalQuestions == 0 && quizTitle.toLowerCase().contains('crossword')) {
            try {
            final puzzleResponse = await _supabase
                .from('crossword_puzzles')
                .select('grid')
                .eq('operator', operator)
                  .eq('difficulty', difficulty?.toLowerCase() ?? 'easy')
                .order('created_at', ascending: false)
                .limit(1)
                .maybeSingle();

            if (puzzleResponse != null && puzzleResponse['grid'] != null) {
              final gridData = puzzleResponse['grid'] as List;
              int blankCount = 0;
              for (final row in gridData) {
                for (final cell in row as List) {
                  if (cell is Map && cell['type'] == 'blank') {
                    blankCount++;
                  }
                }
              }
              if (blankCount > 0) {
                  totalQuestions = blankCount;
                }
              }
            } catch (e) {
              // Ignore errors
            }
          }

          // Final fallback: use highest score from attempts
          if (totalQuestions == 0) {
            final scores = attempts.map((a) => a['score'] as int? ?? 0).where((s) => s > 0).toList();
            if (scores.isNotEmpty) {
              totalQuestions = scores.reduce((a, b) => a > b ? a : b);
            } else {
              totalQuestions = 3; // Default fallback
            }
          }

          // Format title with difficulty
          if (difficulty != null && difficulty.isNotEmpty) {
            final difficultyCapitalized = difficulty.substring(0, 1).toUpperCase() + difficulty.substring(1);
            quizTitle = '$quizTitle ($difficultyCapitalized)';
                }
              } else {
          // For quizzes - only process if we have a valid entity_id
          final entityId = firstAttempt['entity_id']?.toString();
          if (entityId == null || entityId.isEmpty) {
            continue; // Skip quizzes without entity_id
          }
          
          quizTitle = firstAttempt['entity_title']?.toString() ?? 'Unknown Quiz';

          // Find quiz metadata
          bool quizFound = false;
      for (final quiz in quizzes) {
            if (quiz['id']?.toString() == entityId) {
              quizTitle = quiz['title']?.toString() ?? 'Untitled Quiz';
        final questions = quiz['basic_operator_quiz_questions'] as List? ?? [];
              totalQuestions = questions.length;
              quizFound = true;
              break;
            }
          }
          
          // Skip if quiz metadata not found (shouldn't happen, but defensive check)
          if (!quizFound) {
            continue;
          }

          // Get lesson title if available
          final lessonId = firstAttempt['lesson_id']?.toString();
          if (lessonId != null) {
            try {
              final lessonResponse = await _supabase
                  .from('basic_operator_lessons')
                  .select('title')
                  .eq('id', lessonId)
                  .maybeSingle();
              lessonTitle = lessonResponse?['title']?.toString();
            } catch (e) {
              // Ignore errors
            }
          }
        }

        // IMPORTANT: Only count the FIRST 3 attempts for My Progress display
        // Attempts beyond 3 will show in Recent Activity/Activity Logs but won't appear in Student Progress
        // Take only the first 3 attempts (sorted by attempt_number ascending)
        final firstThreeAttempts = attempts.take(3).toList();
        final attemptsCount = firstThreeAttempts.length; // Only count first 3 attempts (max 3)
        
        // Get scores from the first 3 attempts only (including 0 scores)
        // Handle both int and string representations of scores
        final allScores = firstThreeAttempts.map((a) {
          final scoreValue = a['score'];
          if (scoreValue == null) return null;
          if (scoreValue is int) return scoreValue;
          if (scoreValue is String) {
            return int.tryParse(scoreValue);
          }
          if (scoreValue is num) return scoreValue.toInt();
          return null;
        }).toList();
        
        // Calculate highest score from FIRST 3 attempts only
        final validScores = allScores.where((s) => s != null).map((s) => s!);
        final highestScore = validScores.isEmpty 
            ? 0 
            : validScores.fold(0, (max, score) => score > max ? score : max);
        
        // Skip this entity only if ALL attempts have null scores (not if they have 0)
        // We want to show attempts even if score is 0, as long as at least one has a valid score
        if (allScores.every((s) => s == null)) {
          continue;
        }
        
        // Map scores for display (keep null if score was null, but include 0 scores as 0)
        final scores = allScores.map((s) => s ?? 0).toList();

        // Create QuizProgressData
        // For games and quizzes, include all attempts (including score 0)
        // Store scores as integers (0 is valid, represents an attempt with 0 correct)
        // Only set to null if the attempt doesn't exist (not if score is 0)
        
        // Store scores from the first 3 attempts only (for My Progress calculations)
        // Attempts beyond 3 are ignored for totals but still show in Recent Activity
        final finalTry1Score = allScores.length > 0 && allScores[0] != null ? allScores[0] : null;
        final finalTry2Score = allScores.length > 1 && allScores[1] != null ? allScores[1] : null;
        final finalTry3Score = allScores.length > 2 && allScores[2] != null ? allScores[2] : null;
        
        final progressData = QuizProgressData(
          quizId: isGame ? entityKey : (firstAttempt['entity_id']?.toString() ?? entityKey),
          quizTitle: quizTitle,
          totalQuestions: totalQuestions > 0 ? totalQuestions : 1,
          try1Score: finalTry1Score,
          try2Score: finalTry2Score,
          try3Score: finalTry3Score,
          attemptsCount: attemptsCount, // Only counts first 3 attempts (max 3, attempts beyond 3 ignored)
          highestScore: highestScore, // Only from first 3 attempts
          isGame: isGame,
          difficulty: difficulty,
          lessonTitle: lessonTitle,
          operator: operator,
        );
        
        
        results.add(progressData);
      }

      // Filter out items with no attempts or all null scores
      // Show items where the user has actually made attempts (including 0 scores)
      final filteredResults = results.where((r) {
        // Must have at least one attempt
        if (r.attemptsCount == 0) {
          return false;
        }
        
        // Must have at least one score recorded (not all null)
        // 0 scores are valid - they represent attempts
        final hasAnyScore = (r.try1Score != null) ||
                           (r.try2Score != null) ||
                           (r.try3Score != null);
        
        return hasAnyScore;
      }).toList();
      
      return filteredResults;
    } catch (e, stackTrace) {
      return [];
    }
  }
}
