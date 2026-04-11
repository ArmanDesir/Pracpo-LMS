import 'package:flutter/material.dart';
import 'package:pracpro/services/operator_game_service.dart';
import 'package:pracpro/services/activity_progress_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'crossword_math_game.dart';
import 'ninja_math_game.dart';

class GameScreen extends StatelessWidget {
  final String operatorKey;
  final String? classroomId;

  const GameScreen({
    Key? key,
    required this.operatorKey,
    this.classroomId,
  }) : super(key: key);

  Future<void> _saveGameProgress({
    required ActivityProgressService activityProgressService,
    String? gameId,
    required String gameTitle,
    required String operator,
    required String difficulty,
    required int score,
    required int totalItems,
    required int elapsedSeconds,
    String? classroomId,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    await activityProgressService.saveGameProgress(
      userId: user.id,
      gameId: gameId,
      gameTitle: gameTitle,
      operator: operator,
      difficulty: difficulty,
      score: score,
      totalItems: totalItems,
      status: 'completed',
      elapsedTime: elapsedSeconds,
      classroomId: classroomId,
    );
  }

  Future<void> _startGame(
      BuildContext context,
      String gameName,
      String difficulty,
      ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final svc = OperatorGameService();
      final gameKey =
      gameName == 'Crossword Math' ? 'crossmath' : 'ninjamath';

      final preferred = await svc.getPreferredGame(
        operatorKey: operatorKey,
        gameKey: gameKey,
        difficulty: difficulty,
        classroomId: classroomId,
      );

      if (preferred == null) {
        throw Exception('Game not found for operator "$operatorKey"');
      }

      final gameData = preferred.game;
      final variant = preferred.variant;
      final config = variant.config;

      List<Map<String, dynamic>>? presetRounds;
      bool isAssigned = false;

      // ✅ FIXED: now fetch rounds by difficulty
      if (gameKey == 'ninjamath') {
        try {
          final rounds = await svc.getNinjaMathRounds(
            gameData.id,
            difficulty: difficulty,
          );

          if (rounds.isNotEmpty) {
            presetRounds = rounds;
            isAssigned = preferred.isClassroomScoped;
          }
        } catch (e) {
          debugPrint('Failed to fetch Ninja Math rounds: $e');
        }
      }

      Widget screen;
      if (gameKey == 'crossmath') {
        screen = CrosswordMathGameScreen(
          operator: operatorKey,
          difficulty: difficulty,
          config: config,
          classroomId: classroomId,
        );
      } else {
        screen = NinjaMathGameScreen(
          operator: operatorKey,
          difficulty: difficulty,
          config: config,
          classroomId: classroomId,
          presetRounds: presetRounds,
          isAssigned: isAssigned,
        );
      }

      Navigator.pop(context);

      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => screen),
      );

      if (result is Map<String, dynamic>) {
        final score = result['score'] as int? ?? 0;
        final elapsed = result['elapsed'] as int? ?? 0;

        int totalItems = 0;

        if (gameKey == 'ninjamath') {
          final rounds = config['rounds'];

          if (rounds is int) {
            totalItems = rounds;
          } else if (rounds is String) {
            totalItems = int.tryParse(rounds) ?? score;
          } else {
            totalItems = score;
          }
        } else if (gameKey == 'crossmath') {
          totalItems = result['totalBlanks'] as int? ?? 0;

          if (totalItems == 0) {
            try {
              final puzzle = await Supabase.instance.client
                  .from('crossword_puzzles')
                  .select('grid')
                  .eq('operator', operatorKey)
                  .eq('difficulty', difficulty.toLowerCase())
                  .order('created_at', ascending: false)
                  .limit(1)
                  .maybeSingle();

              if (puzzle != null && puzzle['grid'] != null) {
                final gridData = puzzle['grid'] as List;
                int blankCount = 0;

                for (final row in gridData) {
                  for (final cell in row as List) {
                    if (cell is Map && cell['type'] == 'blank') {
                      blankCount++;
                    }
                  }
                }

                totalItems = blankCount;
              }
            } catch (_) {
              totalItems = score > 0 ? score : 10;
            }
          }

          if (totalItems == 0) {
            totalItems = score > 0 ? score : 10;
          }
        }

        final gameTitle =
        gameKey == 'crossmath' ? 'Crossword Math' : 'Ninja Math';

        final String? finalGameId =
        gameKey == 'crossmath' ? null : gameData.id;

        String? finalClassroomId = classroomId;

        if (finalClassroomId == null || finalClassroomId.isEmpty) {
          try {
            final user = Supabase.instance.client.auth.currentUser;

            if (user != null) {
              final classroomsResponse = await Supabase.instance.client
                  .from('user_classrooms')
                  .select('classroom_id')
                  .eq('user_id', user.id)
                  .eq('status', 'accepted')
                  .order('joined_at', ascending: false)
                  .limit(1);

              if (classroomsResponse.isNotEmpty) {
                finalClassroomId =
                classroomsResponse.first['classroom_id'] as String?;
              }
            }
          } catch (_) {}
        }

        final activityProgressService = ActivityProgressService();

        await _saveGameProgress(
          activityProgressService: activityProgressService,
          gameId: finalGameId,
          gameTitle: gameTitle,
          operator: operatorKey,
          difficulty: difficulty,
          score: score,
          totalItems: totalItems,
          elapsedSeconds: elapsed,
          classroomId: finalClassroomId,
        );
      }
    } catch (e) {
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to start game: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          _GameCard(
            title: 'Crossword Math',
            icon: Icons.grid_on,
            onSelect: (difficulty) =>
                _startGame(context, 'Crossword Math', difficulty),
          ),
          const SizedBox(height: 24),
          _GameCard(
            title: 'Ninja Math',
            icon: Icons.sports_martial_arts,
            onSelect: (difficulty) =>
                _startGame(context, 'Ninja Math', difficulty),
          ),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final void Function(String difficulty) onSelect;

  const _GameCard({
    required this.title,
    required this.icon,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.deepPurple[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 36, color: Colors.deepPurple),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Choose difficulty:'),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _DifficultyButton(
                  label: 'Easy',
                  onTap: () => onSelect('Easy'),
                ),
                _DifficultyButton(
                  label: 'Medium',
                  onTap: () => onSelect('Medium'),
                ),
                _DifficultyButton(
                  label: 'Hard',
                  onTap: () => onSelect('Hard'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DifficultyButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DifficultyButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(label),
    );
  }
}