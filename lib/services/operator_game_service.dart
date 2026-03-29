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
            if (v is Map && v['config'] is String) {
              try {
                v['config'] = jsonDecode(v['config']);
              } catch (_) {
                v['config'] = {};
              }
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
      final gameId = insert['id'] as String;
      if (variantsByDifficulty.isNotEmpty) {
        final rows = variantsByDifficulty.entries.map((e) {
          final diff = e.key.toLowerCase();
          return {
            'game_id': gameId,
            'difficulty': diff,
            'config': e.value,
          };
        }).toList();

        await _sp.from('operator_game_variants').insert(rows);
      }

      return gameId;
    } catch (e) {
      throw Exception('Failed to create game: $e');
    }
  }

  /// Prefer a classroom-scoped game if available, otherwise fall back to a global game.
  /// Returns null if no game exists for the operator+gameKey.
  Future<({OperatorGame game, OperatorGameVariant variant, bool isClassroomScoped})?>
      getPreferredGame({
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

      final res = await q.order('created_at', ascending: false).limit(1).maybeSingle();
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

  Future<List<Map<String, dynamic>>> getNinjaMathRounds(String gameId) async {
    final res = await _sp
        .from('ninja_math_rounds')
        .select('round_no, numbers, correct_answer')
        .eq('game_id', gameId)
        .order('round_no', ascending: true);

    if (res is! List) return [];

    return res.whereType<Map<String, dynamic>>().map((r) {
      final numsRaw = r['numbers'];
      final numbers = (numsRaw is List)
          ? numsRaw.map((e) => int.tryParse(e.toString()) ?? 0).toList()
          : <int>[];
      final target = int.tryParse(r['correct_answer']?.toString() ?? '') ?? 0;
      return {
        'numbers': numbers,
        'target': target,
      };
    }).toList();
  }
}
