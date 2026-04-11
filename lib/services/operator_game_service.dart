import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/operator_game.dart';

class OperatorGameService {
  final SupabaseClient _sp = Supabase.instance.client;

  Future<List<OperatorGame>> getGamesForOperator(String operatorKey) async {
    final res = await _sp
        .from('operator_games')
        .select('''
    id,
    operator,
    game_key,
    title,
    description,
    is_active,
    operator_game_variants_game_id_fkey (
      id,
      difficulty,
      config
    )
  ''')
        .eq('operator', operatorKey)
        .eq('is_active', true)
        .order('title');

    if (res is! List) return [];
    return res
        .whereType<Map<String, dynamic>>()
        .map((g) {
      final variants = g['operator_game_variants_game_id_fkey'] as List?;
      if (variants != null) {
        for (final v in variants) {
          if (v is Map && v['config'] is String) {
            try {
              v['config'] = jsonDecode(v['config']);
            } catch (_) {
              v['config'] = {};
            }
          }
        }
      }
      return OperatorGame.fromJson(g);
    })
        .toList();
  }

  Future<String> createGame({
    required String operatorKey,
    required String gameKey,
    required String title,
    String? description,
    Map<String, Map<String, dynamic>> variantsByDifficulty = const {},
    String? createdBy,
    String? classroomId,
  }) async {
    try {
      // One game row per operator + game_key + title (no difficulty here)
      final existing = await _sp
          .from('operator_games')
          .select('id')
          .eq('operator', operatorKey)
          .eq('game_key', gameKey)
          .eq('title', title)
          .maybeSingle();

      String gameId;

      if (existing != null) {
        gameId = existing['id'];

        // Update description in case it changed
        await _sp
            .from('operator_games')
            .update({'description': description})
            .eq('id', gameId);
      } else {
        final insert = await _sp
            .from('operator_games')
            .insert({
          'operator': operatorKey,
          'game_key': gameKey,
          'title': title,
          'description': description,
          if (createdBy != null) 'created_by': createdBy,
          if (classroomId != null && classroomId.isNotEmpty)
            'classroom_id': classroomId,
        })
            .select('id')
            .single();

        gameId = insert['id'] as String;
      }

      // Upsert only the selected difficulty's variant config
      if (variantsByDifficulty.isNotEmpty) {
        final rows = variantsByDifficulty.entries.map((e) {
          return {
            'game_id': gameId,
            'difficulty': e.key.toLowerCase(),
            'config': e.value,
          };
        }).toList();

        await _sp.from('operator_game_variants').upsert(
          rows,
          onConflict: 'game_id,difficulty',
        );
      }

      return gameId;
    } catch (e) {
      throw Exception('Failed to create game: $e');
    }
  }

  /// Deletes only the rounds for a specific difficulty under a game,
  /// then inserts the new ones. This allows re-creating Easy without
  /// touching Medium or Hard rounds.
  Future<void> replaceRoundsForDifficulty({
    required String gameId,
    required String difficulty,
    required List<Map<String, dynamic>> rounds,
  }) async {
    final diff = difficulty.toLowerCase();

    // Delete only this difficulty's old rounds
    await _sp
        .from('ninja_math_rounds')
        .delete()
        .eq('game_id', gameId)
        .eq('difficulty', diff);

    if (rounds.isEmpty) return;

    final rows = rounds.asMap().entries.map((e) => {
      'game_id': gameId,
      'difficulty': diff,
      'round_no': e.key + 1,
      'numbers': e.value['numbers'],
      'correct_answer': e.value['target'],
    }).toList();

    await _sp.from('ninja_math_rounds').insert(rows);
  }

  /// Prefer a classroom-scoped game if available, otherwise fall back to a global game.
  /// Returns null if no game exists for the operator+gameKey.
  Future<
      ({
      OperatorGame game,
      OperatorGameVariant variant,
      bool isClassroomScoped
      })?> getPreferredGame({
    required String operatorKey,
    required String gameKey,
    required String difficulty,
    String? classroomId,
  }) async {
    Future<OperatorGame?> fetchOne({
      required bool classroomScoped,
    }) async {
      var q = _sp.from('operator_games').select('''
            id,
            operator,
            game_key,
            title,
            description,
            is_active,
            operator_game_variants_game_id_fkey (
              id,
              difficulty,
              config
            )
          ''')
          .eq('operator', operatorKey)
          .eq('game_key', gameKey)
          .eq('is_active', true);

      if (classroomScoped && classroomId != null) {
        q = q.eq('classroom_id', classroomId);
      } else {
        q = q.isFilter('classroom_id', null);
      }

      final res =
      await q.order('created_at', ascending: false).limit(1).maybeSingle();
      if (res == null || res is! Map<String, dynamic>) return null;

      final variants = res['operator_game_variants_game_id_fkey'] as List?;
      if (variants != null) {
        for (final v in variants) {
          if (v is Map && v['config'] is String) {
            try {
              v['config'] = jsonDecode(v['config']);
            } catch (_) {
              v['config'] = {};
            }
          }
        }
      }
      return OperatorGame.fromJson(res);
    }

    OperatorGame? game;
    bool isClassroomScoped = false;

    if (classroomId != null && classroomId.trim().isNotEmpty) {
      game = await fetchOne(classroomScoped: true);
      isClassroomScoped = game != null;
    }

    game ??= await fetchOne(classroomScoped: false);
    if (game == null) return null;

    final variant = game.variants.firstWhere(
          (v) => v.difficulty.toLowerCase() == difficulty.toLowerCase(),
      orElse: () => game!.variants.first,
    );

    return (game: game, variant: variant, isClassroomScoped: isClassroomScoped);
  }

  Future<List<Map<String, dynamic>>> getNinjaMathRounds(
      String gameId, {
        String? difficulty,
      }) async {
    var q = _sp
        .from('ninja_math_rounds')
        .select('round_no, numbers, correct_answer')
        .eq('game_id', gameId);

    // Filter by difficulty if provided so each difficulty gets its own rounds
    if (difficulty != null) {
      q = q.eq('difficulty', difficulty.toLowerCase());
    }

    final res = await q.order('round_no', ascending: true);

    if (res is! List) return [];

    return res.whereType<Map<String, dynamic>>().map((r) {
      final numsRaw = r['numbers'];
      final numbers = (numsRaw is List)
          ? numsRaw.map((e) => int.tryParse(e.toString()) ?? 0).toList()
          : <int>[];
      final target =
          int.tryParse(r['correct_answer']?.toString() ?? '') ?? 0;
      return {
        'numbers': numbers,
        'target': target,
      };
    }).toList();
  }
}