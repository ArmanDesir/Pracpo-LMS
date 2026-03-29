import 'package:pracpro/models/crossword_puzzles.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CrosswordPuzzleService {
  final _sp = Supabase.instance.client;

  Future<List<CrosswordPuzzle>> getPuzzles(String operatorKey) async {
    final res = await _sp
        .from('crossword_puzzles')
        .select()
        .eq('operator', operatorKey)
        .order('created_at', ascending: false);
    if (res is! List) return [];
    return res.map((r) => CrosswordPuzzle.fromJson(r)).toList();
  }

  Future<CrosswordPuzzle?> getPuzzle(String operatorKey, String difficulty) async {
    final res = await _sp
        .from('crossword_puzzles')
        .select()
        .eq('operator', operatorKey)
        .eq('difficulty', difficulty)
        .maybeSingle();
    return res == null ? null : CrosswordPuzzle.fromJson(res);
  }

  Future<void> savePuzzle(CrosswordPuzzle puzzle) async {
    await _sp.from('crossword_puzzles').insert(puzzle.toJson());
  }
}
