import 'dart:math';
import 'crossword_cell.dart';

class CrosswordGridGenerator {
  static final _rng = Random();

  static const _cfg = {
    'easy': {'min': 1, 'max': 10, 'bankDecoys': 5, 'timeSec': 120},
    'medium': {'min': 1, 'max': 20, 'bankDecoys': 6, 'timeSec': 120},
    'hard': {'min': 1, 'max': 50, 'bankDecoys': 7, 'timeSec': 900},
  };

  // Hardcoded equations: {operand1, operand2, result}
  // Operands are interchangeable for commutative operations (+, ×)
  static const _hardcodedEquations = {
    'addition': {
      'easy': [
        {'op1': 1, 'op2': 1, 'result': 2},
        {'op1': 2, 'op2': 2, 'result': 4},
        {'op1': 3, 'op2': 1, 'result': 4},
        {'op1': 4, 'op2': 0, 'result': 4},
        {'op1': 2, 'op2': 3, 'result': 5},
        {'op1': 5, 'op2': 1, 'result': 6},
        {'op1': 0, 'op2': 6, 'result': 6},
        {'op1': 3, 'op2': 2, 'result': 5},
        {'op1': 4, 'op2': 3, 'result': 7},
        {'op1': 5, 'op2': 4, 'result': 9},
        {'op1': 1, 'op2': 2, 'result': 3},
        {'op1': 3, 'op2': 3, 'result': 6},
        {'op1': 2, 'op2': 4, 'result': 6},
        {'op1': 1, 'op2': 5, 'result': 6},
        {'op1': 4, 'op2': 4, 'result': 8},
        {'op1': 2, 'op2': 5, 'result': 7},
        {'op1': 3, 'op2': 4, 'result': 7},
        {'op1': 1, 'op2': 6, 'result': 7},
        {'op1': 5, 'op2': 3, 'result': 8},
        {'op1': 4, 'op2': 5, 'result': 9},
      ],
      'medium': [
        {'op1': 27, 'op2': 18, 'result': 45},
        {'op1': 46, 'op2': 29, 'result': 75},
        {'op1': 58, 'op2': 17, 'result': 75},
        {'op1': 64, 'op2': 28, 'result': 92},
        {'op1': 39, 'op2': 47, 'result': 86},
        {'op1': 72, 'op2': 19, 'result': 91},
        {'op1': 85, 'op2': 16, 'result': 101},
        {'op1': 93, 'op2': 27, 'result': 120},
        {'op1': 48, 'op2': 54, 'result': 102},
        {'op1': 67, 'op2': 33, 'result': 100},
        {'op1': 125, 'op2': 75, 'result': 200},
        {'op1': 94, 'op2': 26, 'result': 120},
        {'op1': 108, 'op2': 42, 'result': 150},
        {'op1': 136, 'op2': 24, 'result': 160},
        {'op1': 59, 'op2': 61, 'result': 120},
        {'op1': 77, 'op2': 48, 'result': 125},
        {'op1': 82, 'op2': 38, 'result': 120},
        {'op1': 95, 'op2': 15, 'result': 110},
        {'op1': 143, 'op2': 57, 'result': 200},
        {'op1': 168, 'op2': 32, 'result': 200},
      ],
      'hard': [
        {'op1': 150, 'op2': 250, 'result': 400},
        {'op1': 275, 'op2': 125, 'result': 400},
        {'op1': 320, 'op2': 180, 'result': 500},
        {'op1': 450, 'op2': 150, 'result': 600},
        {'op1': 380, 'op2': 220, 'result': 600},
        {'op1': 500, 'op2': 200, 'result': 700},
        {'op1': 350, 'op2': 350, 'result': 700},
        {'op1': 600, 'op2': 200, 'result': 800},
        {'op1': 450, 'op2': 350, 'result': 800},
        {'op1': 750, 'op2': 150, 'result': 900},
        {'op1': 500, 'op2': 400, 'result': 900},
        {'op1': 800, 'op2': 200, 'result': 1000},
        {'op1': 600, 'op2': 400, 'result': 1000},
        {'op1': 550, 'op2': 450, 'result': 1000},
        {'op1': 900, 'op2': 100, 'result': 1000},
        {'op1': 420, 'op2': 280, 'result': 700},
        {'op1': 360, 'op2': 340, 'result': 700},
        {'op1': 650, 'op2': 250, 'result': 900},
        {'op1': 480, 'op2': 420, 'result': 900},
        {'op1': 700, 'op2': 300, 'result': 1000},
      ],
    },
    'subtraction': {
      'easy': [
        {'op1': 5, 'op2': 2, 'result': 3},
        {'op1': 7, 'op2': 3, 'result': 4},
        {'op1': 9, 'op2': 4, 'result': 5},
        {'op1': 8, 'op2': 2, 'result': 6},
        {'op1': 10, 'op2': 5, 'result': 5},
        {'op1': 6, 'op2': 1, 'result': 5},
        {'op1': 8, 'op2': 3, 'result': 5},
        {'op1': 9, 'op2': 2, 'result': 7},
        {'op1': 10, 'op2': 3, 'result': 7},
        {'op1': 7, 'op2': 0, 'result': 7},
        {'op1': 9, 'op2': 1, 'result': 8},
        {'op1': 10, 'op2': 2, 'result': 8},
        {'op1': 8, 'op2': 0, 'result': 8},
        {'op1': 10, 'op2': 1, 'result': 9},
        {'op1': 9, 'op2': 0, 'result': 9},
        {'op1': 6, 'op2': 2, 'result': 4},
        {'op1': 7, 'op2': 1, 'result': 6},
        {'op1': 8, 'op2': 1, 'result': 7},
        {'op1': 5, 'op2': 1, 'result': 4},
        {'op1': 4, 'op2': 2, 'result': 2},
      ],
      'medium': [
        {'op1': 85, 'op2': 27, 'result': 58},
        {'op1': 120, 'op2': 48, 'result': 72},
        {'op1': 94, 'op2': 36, 'result': 58},
        {'op1': 150, 'op2': 75, 'result': 75},
        {'op1': 200, 'op2': 86, 'result': 114},
        {'op1': 99, 'op2': 47, 'result': 52},
        {'op1': 130, 'op2': 65, 'result': 65},
        {'op1': 180, 'op2': 92, 'result': 88},
        {'op1': 145, 'op2': 29, 'result': 116},
        {'op1': 170, 'op2': 84, 'result': 86},
        {'op1': 210, 'op2': 95, 'result': 115},
        {'op1': 160, 'op2': 73, 'result': 87},
        {'op1': 100, 'op2': 38, 'result': 62},
        {'op1': 134, 'op2': 59, 'result': 75},
        {'op1': 190, 'op2': 107, 'result': 83},
        {'op1': 225, 'op2': 128, 'result': 97},
        {'op1': 140, 'op2': 66, 'result': 74},
        {'op1': 175, 'op2': 89, 'result': 86},
        {'op1': 260, 'op2': 135, 'result': 125},
        {'op1': 300, 'op2': 178, 'result': 122},
      ],
      'hard': [
        {'op1': 500, 'op2': 250, 'result': 250},
        {'op1': 750, 'op2': 350, 'result': 400},
        {'op1': 900, 'op2': 450, 'result': 450},
        {'op1': 1000, 'op2': 300, 'result': 700},
        {'op1': 850, 'op2': 200, 'result': 650},
        {'op1': 1200, 'op2': 500, 'result': 700},
        {'op1': 1500, 'op2': 750, 'result': 750},
        {'op1': 1800, 'op2': 900, 'result': 900},
        {'op1': 2000, 'op2': 800, 'result': 1200},
        {'op1': 1600, 'op2': 600, 'result': 1000},
        {'op1': 1400, 'op2': 550, 'result': 850},
        {'op1': 1700, 'op2': 650, 'result': 1050},
        {'op1': 1900, 'op2': 700, 'result': 1200},
        {'op1': 2200, 'op2': 900, 'result': 1300},
        {'op1': 2500, 'op2': 1000, 'result': 1500},
        {'op1': 1100, 'op2': 400, 'result': 700},
        {'op1': 1300, 'op2': 500, 'result': 800},
        {'op1': 2100, 'op2': 800, 'result': 1300},
        {'op1': 2400, 'op2': 950, 'result': 1450},
        {'op1': 2800, 'op2': 1200, 'result': 1600},
      ],
    },
    'multiplication': {
      'easy': [
        {'op1': 1, 'op2': 1, 'result': 1},
        {'op1': 2, 'op2': 2, 'result': 4},
        {'op1': 3, 'op2': 1, 'result': 3},
        {'op1': 4, 'op2': 0, 'result': 0},
        {'op1': 2, 'op2': 3, 'result': 6},
        {'op1': 5, 'op2': 1, 'result': 5},
        {'op1': 0, 'op2': 6, 'result': 0},
        {'op1': 3, 'op2': 2, 'result': 6},
        {'op1': 4, 'op2': 2, 'result': 8},
        {'op1': 3, 'op2': 3, 'result': 9},
        {'op1': 2, 'op2': 4, 'result': 8},
        {'op1': 5, 'op2': 2, 'result': 10},
        {'op1': 4, 'op2': 3, 'result': 12},
        {'op1': 3, 'op2': 4, 'result': 12},
        {'op1': 2, 'op2': 5, 'result': 10},
        {'op1': 5, 'op2': 3, 'result': 15},
        {'op1': 4, 'op2': 4, 'result': 16},
        {'op1': 3, 'op2': 5, 'result': 15},
        {'op1': 5, 'op2': 4, 'result': 20},
        {'op1': 2, 'op2': 6, 'result': 12},
      ],
      'medium': [
        {'op1': 12, 'op2': 8, 'result': 96},
        {'op1': 14, 'op2': 7, 'result': 98},
        {'op1': 9, 'op2': 13, 'result': 117},
        {'op1': 15, 'op2': 6, 'result': 90},
        {'op1': 11, 'op2': 12, 'result': 132},
        {'op1': 16, 'op2': 5, 'result': 80},
        {'op1': 18, 'op2': 7, 'result': 126},
        {'op1': 14, 'op2': 9, 'result': 126},
        {'op1': 25, 'op2': 4, 'result': 100},
        {'op1': 21, 'op2': 6, 'result': 126},
        {'op1': 17, 'op2': 8, 'result': 136},
        {'op1': 24, 'op2': 5, 'result': 120},
        {'op1': 19, 'op2': 6, 'result': 114},
        {'op1': 22, 'op2': 7, 'result': 154},
        {'op1': 13, 'op2': 9, 'result': 117},
        {'op1': 28, 'op2': 4, 'result': 112},
        {'op1': 16, 'op2': 9, 'result': 144},
        {'op1': 27, 'op2': 6, 'result': 162},
        {'op1': 32, 'op2': 5, 'result': 160},
        {'op1': 18, 'op2': 11, 'result': 198},
      ],
      'hard': [
        {'op1': 25, 'op2': 20, 'result': 500},
        {'op1': 30, 'op2': 15, 'result': 450},
        {'op1': 40, 'op2': 12, 'result': 480},
        {'op1': 35, 'op2': 14, 'result': 490},
        {'op1': 50, 'op2': 10, 'result': 500},
        {'op1': 45, 'op2': 11, 'result': 495},
        {'op1': 60, 'op2': 8, 'result': 480},
        {'op1': 55, 'op2': 9, 'result': 495},
        {'op1': 70, 'op2': 7, 'result': 490},
        {'op1': 65, 'op2': 8, 'result': 520},
        {'op1': 80, 'op2': 6, 'result': 480},
        {'op1': 75, 'op2': 7, 'result': 525},
        {'op1': 90, 'op2': 5, 'result': 450},
        {'op1': 85, 'op2': 6, 'result': 510},
        {'op1': 100, 'op2': 5, 'result': 500},
        {'op1': 95, 'op2': 5, 'result': 475},
        {'op1': 110, 'op2': 4, 'result': 440},
        {'op1': 105, 'op2': 5, 'result': 525},
        {'op1': 120, 'op2': 4, 'result': 480},
        {'op1': 115, 'op2': 4, 'result': 460},
      ],
    },
    'division': {
      'easy': [
        {'op1': 4, 'op2': 2, 'result': 2},
        {'op1': 6, 'op2': 3, 'result': 2},
        {'op1': 8, 'op2': 2, 'result': 4},
        {'op1': 9, 'op2': 3, 'result': 3},
        {'op1': 10, 'op2': 5, 'result': 2},
        {'op1': 12, 'op2': 3, 'result': 4},
        {'op1': 12, 'op2': 4, 'result': 3},
        {'op1': 15, 'op2': 5, 'result': 3},
        {'op1': 16, 'op2': 4, 'result': 4},
        {'op1': 18, 'op2': 3, 'result': 6},
        {'op1': 18, 'op2': 6, 'result': 3},
        {'op1': 20, 'op2': 4, 'result': 5},
        {'op1': 20, 'op2': 5, 'result': 4},
        {'op1': 21, 'op2': 7, 'result': 3},
        {'op1': 24, 'op2': 6, 'result': 4},
        {'op1': 25, 'op2': 5, 'result': 5},
        {'op1': 27, 'op2': 9, 'result': 3},
        {'op1': 28, 'op2': 7, 'result': 4},
        {'op1': 30, 'op2': 6, 'result': 5},
        {'op1': 32, 'op2': 8, 'result': 4},
      ],
      'medium': [
        {'op1': 96, 'op2': 8, 'result': 12},
        {'op1': 126, 'op2': 7, 'result': 18},
        {'op1': 144, 'op2': 12, 'result': 12},
        {'op1': 135, 'op2': 9, 'result': 15},
        {'op1': 168, 'op2': 6, 'result': 28},
        {'op1': 180, 'op2': 12, 'result': 15},
        {'op1': 154, 'op2': 7, 'result': 22},
        {'op1': 210, 'op2': 10, 'result': 21},
        {'op1': 192, 'op2': 8, 'result': 24},
        {'op1': 225, 'op2': 9, 'result': 25},
        {'op1': 198, 'op2': 6, 'result': 33},
        {'op1': 240, 'op2': 12, 'result': 20},
        {'op1': 216, 'op2': 18, 'result': 12},
        {'op1': 275, 'op2': 11, 'result': 25},
        {'op1': 264, 'op2': 12, 'result': 22},
        {'op1': 300, 'op2': 15, 'result': 20},
        {'op1': 224, 'op2': 7, 'result': 32},
        {'op1': 360, 'op2': 12, 'result': 30},
        {'op1': 242, 'op2': 11, 'result': 22},
        {'op1': 420, 'op2': 14, 'result': 30},
      ],
      'hard': [
        {'op1': 500, 'op2': 10, 'result': 50},
        {'op1': 600, 'op2': 12, 'result': 50},
        {'op1': 750, 'op2': 15, 'result': 50},
        {'op1': 800, 'op2': 16, 'result': 50},
        {'op1': 900, 'op2': 18, 'result': 50},
        {'op1': 1000, 'op2': 20, 'result': 50},
        {'op1': 1200, 'op2': 24, 'result': 50},
        {'op1': 1500, 'op2': 30, 'result': 50},
        {'op1': 1800, 'op2': 36, 'result': 50},
        {'op1': 2000, 'op2': 40, 'result': 50},
        {'op1': 550, 'op2': 11, 'result': 50},
        {'op1': 650, 'op2': 13, 'result': 50},
        {'op1': 850, 'op2': 17, 'result': 50},
        {'op1': 950, 'op2': 19, 'result': 50},
        {'op1': 1050, 'op2': 21, 'result': 50},
        {'op1': 1150, 'op2': 23, 'result': 50},
        {'op1': 1250, 'op2': 25, 'result': 50},
        {'op1': 1350, 'op2': 27, 'result': 50},
        {'op1': 1450, 'op2': 29, 'result': 50},
        {'op1': 1600, 'op2': 32, 'result': 50},
      ],
    },
  };

  static Map<String, int> timers(String difficulty) {
    final d = difficulty.toLowerCase();
    final c = _cfg[d] ?? _cfg['easy']!;
    return {'timeSec': c['timeSec'] as int};
  }

  static ({
  List<List<CrosswordCell>> grid,
  List<BankNumber> bank,
  }) generate({
    required String operator,
    required String difficulty,
    int? minVal,
    int? maxVal,
  }) {
    switch (operator.toLowerCase()) {
      case 'addition':
        return additionGrid(difficulty, minVal: minVal, maxVal: maxVal);
      case 'subtraction':
        return subtractionGrid(difficulty, minVal: minVal, maxVal: maxVal);
      case 'multiplication':
        return multiplicationGrid(difficulty, minVal: minVal, maxVal: maxVal);
      case 'division':
        return divisionGrid(difficulty, minVal: minVal, maxVal: maxVal);
      default:
        return additionGrid(difficulty, minVal: minVal, maxVal: maxVal);
    }
  }

 static ({
  List<List<CrosswordCell>> grid,
  List<BankNumber> bank,
  }) additionGrid(
      String difficulty, {
        int? minVal,
        int? maxVal,
      }) {
    final cfg = _cfg[difficulty.toLowerCase()] ?? _cfg['easy']!;
    final minV = minVal ?? cfg['min'] as int;
    final maxV = maxVal ?? cfg['max'] as int;
    final decoys = cfg['bankDecoys'] as int;
    final diff = difficulty.toLowerCase();

    final g = List.generate(
      5,
          (r) => List.generate(
        5,
            (c) => CrosswordCell(row: r, col: c, type: CellType.empty, value: ''),
      ),
    );

    // Get 2-3 random equations from hardcoded pool for medium/hard, 2 for easy
    // For addition, we'll generate random operands for the same results
    final numEquations = (diff == 'medium' || diff == 'hard') ? (_rng.nextInt(2) + 2) : 2; // 2-3 for medium/hard, 2 for easy
    final equations = <Map<String, int>>[];
    
    // Get unique equations (different results, or same result with different operands)
    while (equations.length < numEquations) {
      final eq = _getEquationWithRandomOperands('addition', difficulty, minV, maxV);
      if (eq == null) break;
      
      bool isDuplicate = false;
      for (final existing in equations) {
        // Check if same result AND same operands (in any order for commutative ops)
        if (_areEquationsEqual(eq, existing)) {
          isDuplicate = true;
          break;
        }
      }
      if (!isDuplicate) {
        equations.add(eq);
      }
      // Safety check to prevent infinite loop
      if (equations.length < numEquations && equations.length >= 20) break;
    }

    // Use advanced placement for medium and hard, simple for easy
    if (diff == 'medium' || diff == 'hard') {
      _placeEquationsAdvanced(g, equations, 'addition');
    } else {
      // Simple horizontal placement for easy (always 2 equations)
      final eq1 = equations[0];
      final eq2 = equations.length > 1 ? equations[1] : equations[0];
      
      final a = eq1['op1']!;
      final b = eq1['op2']!;
      final s1 = eq1['result']!;
      
      final c1 = eq2['op1']!;
      final d1 = eq2['op2']!;
      final s2 = eq2['result']!;

      g[0] = [_blank(0, 0, a), _op(0, 1, '+'), _blank(0, 2, b), _eq(0, 3), _ans(0, 4, s1)];
      g[2] = [_blank(2, 0, c1), _op(2, 1, '+'), _blank(2, 2, d1), _eq(2, 3), _ans(2, 4, s2)];
    }

    // Collect all answers from the grid
    final answers = <int>{};
    for (final row in g) {
      for (final cell in row) {
        if (cell.type == CellType.blank && cell.answer != null) {
          answers.add(cell.answer!);
        } else if (cell.type == CellType.answer || cell.type == CellType.number) {
          final val = int.tryParse(cell.value ?? '');
          if (val != null) answers.add(val);
        }
      }
    }
    
    final bank = _buildBank(answers.toList(), decoys, minV, maxV);
    return (grid: g, bank: bank);
  }

  static ({
  List<List<CrosswordCell>> grid,
  List<BankNumber> bank,
  }) subtractionGrid(
      String difficulty, {
        int? minVal,
        int? maxVal,
      }) {
    final cfg = _cfg[difficulty.toLowerCase()] ?? _cfg['easy']!;
    final minV = minVal ?? cfg['min'] as int;
    final maxV = maxVal ?? cfg['max'] as int;
    final decoys = cfg['bankDecoys'] as int;
    final diff = difficulty.toLowerCase();

    final g = List.generate(
      5,
          (r) => List.generate(
        5,
            (c) => CrosswordCell(row: r, col: c, type: CellType.empty, value: ''),
      ),
    );

    // Get 2-3 random equations from hardcoded pool for medium/hard, 2 for easy
    // For subtraction, we'll generate random operands for the same results
    final numEquations = (diff == 'medium' || diff == 'hard') ? (_rng.nextInt(2) + 2) : 2; // 2-3 for medium/hard, 2 for easy
    final equations = <Map<String, int>>[];
    
    // Get unique equations (different results, or same result with different operands)
    while (equations.length < numEquations) {
      final eq = _getEquationWithRandomOperands('subtraction', difficulty, minV, maxV);
      if (eq == null) break;
      
      bool isDuplicate = false;
      for (final existing in equations) {
        // Check if same result AND same operands
        if (_areEquationsEqual(eq, existing)) {
          isDuplicate = true;
          break;
        }
      }
      if (!isDuplicate) {
        equations.add(eq);
      }
      // Safety check to prevent infinite loop
      if (equations.length < numEquations && equations.length >= 20) break;
    }

    // Use advanced placement for medium and hard, simple for easy
    if (diff == 'medium' || diff == 'hard') {
      _placeEquationsAdvanced(g, equations, 'subtraction');
    } else {
      // Simple horizontal placement for easy (always 2 equations)
      final eq1 = equations[0];
      final eq2 = equations.length > 1 ? equations[1] : equations[0];
      
      final a = eq1['op1']!;
      final b = eq1['op2']!;
      final s1 = eq1['result']!;
      
      final c1 = eq2['op1']!;
      final d1 = eq2['op2']!;
      final s2 = eq2['result']!;

      g[0] = [_blank(0, 0, a), _op(0, 1, '-'), _blank(0, 2, b), _eq(0, 3), _ans(0, 4, s1)];
      g[2] = [_blank(2, 0, c1), _op(2, 1, '-'), _blank(2, 2, d1), _eq(2, 3), _ans(2, 4, s2)];
    }

    // Collect all answers from the grid
    final answers = <int>{};
    for (final row in g) {
      for (final cell in row) {
        if (cell.type == CellType.blank && cell.answer != null) {
          answers.add(cell.answer!);
        } else if (cell.type == CellType.answer || cell.type == CellType.number) {
          final val = int.tryParse(cell.value ?? '');
          if (val != null) answers.add(val);
        }
      }
    }
    
    final bank = _buildBank(answers.toList(), decoys, minV, maxV);
    return (grid: g, bank: bank);
  }

  static ({
  List<List<CrosswordCell>> grid,
  List<BankNumber> bank,
  }) multiplicationGrid(
      String difficulty, {
        int? minVal,
        int? maxVal,
      }) {
    final cfg = _cfg[difficulty.toLowerCase()] ?? _cfg['easy']!;
    final minV = minVal ?? cfg['min'] as int;
    final maxV = maxVal ?? cfg['max'] as int;
    final decoys = cfg['bankDecoys'] as int;
    final diff = difficulty.toLowerCase();

    final g = List.generate(
      5,
          (r) => List.generate(
        5,
            (c) => CrosswordCell(row: r, col: c, type: CellType.empty, value: ''),
      ),
    );

    // Get 2-3 random equations from hardcoded pool for medium/hard, 2 for easy
    // For multiplication, we'll generate random operands for the same results
    final numEquations = (diff == 'medium' || diff == 'hard') ? (_rng.nextInt(2) + 2) : 2; // 2-3 for medium/hard, 2 for easy
    final equations = <Map<String, int>>[];
    
    // Get unique equations (different results, or same result with different operands)
    while (equations.length < numEquations) {
      final eq = _getEquationWithRandomOperands('multiplication', difficulty, minV, maxV);
      if (eq == null) break;
      
      bool isDuplicate = false;
      for (final existing in equations) {
        // Check if same result AND same operands (in any order for commutative ops)
        if (_areEquationsEqual(eq, existing)) {
          isDuplicate = true;
          break;
        }
      }
      if (!isDuplicate) {
        equations.add(eq);
      }
      // Safety check to prevent infinite loop
      if (equations.length < numEquations && equations.length >= 20) break;
    }

    // Use advanced placement for medium and hard, simple for easy
    if (diff == 'medium' || diff == 'hard') {
      _placeEquationsAdvanced(g, equations, 'multiplication');
    } else {
      // Simple horizontal placement for easy (always 2 equations)
      final eq1 = equations[0];
      final eq2 = equations.length > 1 ? equations[1] : equations[0];
      
      final a = eq1['op1']!;
      final b = eq1['op2']!;
      final s1 = eq1['result']!;
      
      final c1 = eq2['op1']!;
      final d1 = eq2['op2']!;
      final s2 = eq2['result']!;

      g[0] = [_blank(0, 0, a), _op(0, 1, '×'), _blank(0, 2, b), _eq(0, 3), _ans(0, 4, s1)];
      g[2] = [_blank(2, 0, c1), _op(2, 1, '×'), _blank(2, 2, d1), _eq(2, 3), _ans(2, 4, s2)];
    }

    // Collect all answers from the grid
    final answers = <int>{};
    for (final row in g) {
      for (final cell in row) {
        if (cell.type == CellType.blank && cell.answer != null) {
          answers.add(cell.answer!);
        } else if (cell.type == CellType.answer || cell.type == CellType.number) {
          final val = int.tryParse(cell.value ?? '');
          if (val != null) answers.add(val);
        }
      }
    }
    
    final bank = _buildBank(answers.toList(), decoys, minV, maxV);
    return (grid: g, bank: bank);
  }

  static ({
  List<List<CrosswordCell>> grid,
  List<BankNumber> bank,
  }) divisionGrid(
      String difficulty, {
        int? minVal,
        int? maxVal,
      }) {
    final cfg = _cfg[difficulty.toLowerCase()] ?? _cfg['easy']!;
    final minV = minVal ?? cfg['min'] as int;
    final maxV = maxVal ?? cfg['max'] as int;
    final decoys = cfg['bankDecoys'] as int;
    final diff = difficulty.toLowerCase();

    final g = List.generate(
      5,
          (r) => List.generate(
        5,
            (c) => CrosswordCell(row: r, col: c, type: CellType.empty, value: ''),
      ),
    );

    // Get 2-3 random equations from hardcoded pool for medium/hard, 2 for easy
    // For division: op1 = dividend, op2 = divisor, result = quotient
    // Use hardcoded operands as-is (order matters)
    final numEquations = (diff == 'medium' || diff == 'hard') ? (_rng.nextInt(2) + 2) : 2; // 2-3 for medium/hard, 2 for easy
    final equations = <Map<String, int>>[];
    
    // Get unique equations
    while (equations.length < numEquations) {
      final eq = _getRandomEquation('division', difficulty)!;
      bool isDuplicate = false;
      for (final existing in equations) {
        if (_areEquationsEqual(eq, existing)) {
          isDuplicate = true;
          break;
        }
      }
      if (!isDuplicate) {
        equations.add(eq);
      }
      // Safety check to prevent infinite loop
      if (equations.length < numEquations && equations.length >= 20) break;
    }

    // Use advanced placement for medium and hard, simple for easy
    if (diff == 'medium' || diff == 'hard') {
      _placeEquationsAdvanced(g, equations, 'division');
    } else {
      // Simple horizontal placement for easy (always 2 equations)
      final eq1 = equations[0];
      final eq2 = equations.length > 1 ? equations[1] : equations[0];
      
      final a = eq1['op1']!;
      final b = eq1['op2']!;
      final s1 = eq1['result']!;
      
      final c1 = eq2['op1']!;
      final d1 = eq2['op2']!;
      final s2 = eq2['result']!;

      g[0] = [_blank(0, 0, a), _op(0, 1, '÷'), _blank(0, 2, b), _eq(0, 3), _ans(0, 4, s1)];
      g[2] = [_blank(2, 0, c1), _op(2, 1, '÷'), _blank(2, 2, d1), _eq(2, 3), _ans(2, 4, s2)];
    }

    // Collect all answers from the grid
    final answers = <int>{};
    for (final row in g) {
      for (final cell in row) {
        if (cell.type == CellType.blank && cell.answer != null) {
          answers.add(cell.answer!);
        } else if (cell.type == CellType.answer || cell.type == CellType.number) {
          final val = int.tryParse(cell.value ?? '');
          if (val != null) answers.add(val);
        }
      }
    }
    
    final bank = _buildBank(answers.toList(), decoys, minV, maxV);
    return (grid: g, bank: bank);
  }

  static List<BankNumber> _buildBank(
      List<int> answers, int decoys, int minV, int maxV) {
    final bank = <BankNumber>[
      ...answers.map(
              (v) => BankNumber(id: _rng.nextInt(1 << 31), value: v, used: false)),
    ];
    for (int i = 0; i < decoys; i++) {
      bank.add(
          BankNumber(id: _rng.nextInt(1 << 31), value: _rnd(minV, maxV), used: false));
    }
    bank.shuffle(_rng);
    return bank;
  }

  static int _rnd(int min, int max) => min + _rng.nextInt(max - min + 1);

  // Get a random equation from the hardcoded pool
  static Map<String, int>? _getRandomEquation(String operator, String difficulty) {
    final op = operator.toLowerCase();
    final diff = difficulty.toLowerCase();
    
    final equations = _hardcodedEquations[op]?[diff];
    if (equations == null || equations.isEmpty) return null;
    
    return Map<String, int>.from(equations[_rng.nextInt(equations.length)]);
  }

  // Generate random operands for a given result (for commutative operations: addition, multiplication)
  // Also supports subtraction (order matters, but can have different operand combinations)
  // Returns a map with op1, op2, and result, where op1 and op2 are randomly generated
  static Map<String, int>? _generateRandomOperandsForResult(
    String operator,
    int result,
    int minVal,
    int maxVal,
  ) {
    final op = operator.toLowerCase();
    
    if (op == 'addition') {
      // For addition: op1 + op2 = result
      // Choose a random op1 within bounds, then op2 = result - op1
      // Ensure both operands are within min-max range
      int attempts = 0;
      while (attempts < 100) {
        final op1 = _rnd(minVal, maxVal);
        final op2 = result - op1;
        
        // Check if op2 is within bounds and valid
        if (op2 >= minVal && op2 <= maxVal && op2 >= 0) {
          return {'op1': op1, 'op2': op2, 'result': result};
        }
        attempts++;
      }
      // Fallback: use simple split if random generation fails
      final op1 = (result / 2).floor();
      final op2 = result - op1;
      if (op1 >= minVal && op2 >= minVal && op1 <= maxVal && op2 <= maxVal) {
        return {'op1': op1, 'op2': op2, 'result': result};
      }
    } else if (op == 'subtraction') {
      // For subtraction: op1 - op2 = result
      // So op1 = result + op2
      // Choose op2 randomly from a reasonable range (1 to roughly result*0.6)
      // This ensures op1 is reasonable and we get variety like 1001-1, 1002-2, 1600-600, etc.
      // Note: For subtraction, we use result-based range rather than config maxVal,
      // since hard subtraction has large operands that exceed config bounds
      // 
      // We also cap op1 to prevent unrealistic large numbers (e.g., 100600-99000=1600)
      // Based on hardcoded patterns: max op1 ≈ result * 2 (e.g., result=1600 → max op1=2800)
      final maxOp1 = (result * 2).floor();
      final maxOp2 = (result * 0.6).floor().clamp(1, result - 1);
      // op2 must be <= min(maxOp2, maxOp1 - result) to ensure op1 = result + op2 <= maxOp1
      final effectiveMaxOp2 = [maxOp2, maxOp1 - result].reduce((a, b) => a < b ? a : b);
      
      int attempts = 0;
      while (attempts < 100) {
        // Choose op2 from 1 to effectiveMaxOp2 (respects both op2 and op1 bounds)
        final op2 = _rnd(1, effectiveMaxOp2);
        final op1 = result + op2;
        
        // Ensure op1 is positive, op2 is less than op1, and op1 doesn't exceed maxOp1
        if (op1 > 0 && op2 > 0 && op2 < op1 && op1 <= maxOp1) {
          return {'op1': op1, 'op2': op2, 'result': result};
        }
        attempts++;
      }
      // Fallback: use a simple calculation (ensure it respects both maxOp1 and maxOp2)
      // effectiveMaxOp2 is already calculated above, so just use it
      final op2 = (result / 2).floor().clamp(1, effectiveMaxOp2);
      final op1 = result + op2;
      if (op1 > 0 && op2 > 0 && op2 < op1 && op1 <= maxOp1) {
        return {'op1': op1, 'op2': op2, 'result': result};
      }
    } else if (op == 'multiplication') {
      // For multiplication: op1 × op2 = result
      // Find all factor pairs of result within bounds
      final factors = <List<int>>[];
      for (int i = minVal; i <= maxVal && i <= result; i++) {
        if (result % i == 0) {
          final factor = result ~/ i;
          if (factor >= minVal && factor <= maxVal) {
            factors.add([i, factor]);
          }
        }
      }
      
      if (factors.isNotEmpty) {
        final pair = factors[_rng.nextInt(factors.length)];
        return {'op1': pair[0], 'op2': pair[1], 'result': result};
      }
    }
    
    // Return null if generation fails
    return null;
  }

  // Get a random equation, optionally generating random operands
  // For addition, multiplication, and subtraction: generates random operands for same result
  // For division: uses hardcoded operands as-is (order and specific operands matter)
  static Map<String, int>? _getEquationWithRandomOperands(
    String operator,
    String difficulty,
    int minVal,
    int maxVal,
  ) {
    // Get result from hardcoded pool
    final baseEquation = _getRandomEquation(operator, difficulty);
    if (baseEquation == null) return null;
    
    final op = operator.toLowerCase();
    final result = baseEquation['result']!;
    
    // For addition, multiplication, and subtraction: generate random operands
    // All can have different operand combinations for the same result
    if (op == 'addition' || op == 'multiplication' || op == 'subtraction') {
      final randomOperands = _generateRandomOperandsForResult(op, result, minVal, maxVal);
      if (randomOperands != null) {
        return randomOperands;
      }
      // Fallback to original if random generation fails
    }
    
    // For division: use as-is (order and specific operands matter for division)
    return baseEquation;
  }

  // Check if two equations are the same
  // This is used when checking for duplicates, so we check both exact match and swapped order
  static bool _areEquationsEqual(Map<String, int>? eq1, Map<String, int>? eq2) {
    if (eq1 == null || eq2 == null) return false;
    if (eq1['result'] != eq2['result']) return false;
    
    // Exact match
    final sameOrder = eq1['op1'] == eq2['op1'] && eq1['op2'] == eq2['op2'];
    // Swapped order (for commutative ops, this would be equivalent)
    final swappedOrder = eq1['op1'] == eq2['op2'] && eq1['op2'] == eq2['op1'];
    
    return sameOrder || swappedOrder;
  }

  // Advanced placement methods for medium and hard difficulties
  static void _clearGrid(List<List<CrosswordCell>> grid) {
    for (int r = 0; r < grid.length; r++) {
      for (int c = 0; c < grid[r].length; c++) {
        grid[r][c] = CrosswordCell(row: r, col: c, type: CellType.empty, value: '');
      }
    }
  }

  static CrosswordCell _blank(int r, int c, int ans) =>
      CrosswordCell(row: r, col: c, type: CellType.blank, answer: ans);
  static CrosswordCell _op(int r, int c, String v) =>
      CrosswordCell(row: r, col: c, type: CellType.operator, value: v);
  static CrosswordCell _eq(int r, int c) =>
      CrosswordCell(row: r, col: c, type: CellType.equals, value: '=');
  static CrosswordCell _ans(int r, int c, int v) =>
      CrosswordCell(row: r, col: c, type: CellType.answer, value: '$v');
  static CrosswordCell _num(int r, int c, int v) =>
      CrosswordCell(row: r, col: c, type: CellType.number, value: '$v');

  // Place equation horizontally
  static bool _placeHorizontal(
    List<List<CrosswordCell>> grid,
    int row,
    int startCol,
    int op1,
    int op2,
    int result,
    String operator,
  ) {
    if (startCol + 4 >= grid[row].length) return false;
    
    // Check cells and validate intersections are mathematically valid
    int? actualOp1 = op1;
    int? actualOp2 = op2;
    
    for (int i = 0; i <= 4; i++) {
      final cell = grid[row][startCol + i];
      if (cell.type != CellType.empty) {
        if (i == 0) {
          // First operand position
          if (cell.type == CellType.number || cell.type == CellType.answer || cell.type == CellType.blank) {
            final existingValue = int.tryParse(cell.value ?? '') ?? cell.answer;
            if (existingValue != null) {
              actualOp1 = existingValue;
            } else {
              return false;
            }
          } else {
            return false;
          }
        } else if (i == 1) {
          // Operator position
          if (cell.type != CellType.operator || cell.value != operator) {
            return false;
          }
        } else if (i == 2) {
          // Second operand position
          if (cell.type == CellType.number || cell.type == CellType.answer || cell.type == CellType.blank) {
            final existingValue = int.tryParse(cell.value ?? '') ?? cell.answer;
            if (existingValue != null) {
              actualOp2 = existingValue;
            } else {
              return false;
            }
          } else {
            return false;
          }
        } else if (i == 3) {
          // Equals position
          if (cell.type != CellType.equals) {
            return false;
          }
        } else if (i == 4) {
          // Result position
          if (cell.type == CellType.answer || cell.type == CellType.number) {
          if (int.tryParse(cell.value ?? '') != result) return false;
          } else {
          return false;
        }
      }
      }
    }
    
    // Validate the equation is mathematically correct
    if (actualOp1 != null && actualOp2 != null) {
      int calculatedResult;
      switch (operator) {
        case '+':
          calculatedResult = actualOp1 + actualOp2;
          break;
        case '-':
          calculatedResult = actualOp1 - actualOp2;
          break;
        case '×':
          calculatedResult = actualOp1 * actualOp2;
          break;
        case '÷':
          if (actualOp2 == 0) return false;
          calculatedResult = actualOp1 ~/ actualOp2;
          break;
        default:
          return false;
      }
      if (calculatedResult != result) return false;
    }

    grid[row][startCol] = _blank(row, startCol, actualOp1 ?? op1);
    grid[row][startCol + 1] = _op(row, startCol + 1, operator);
    grid[row][startCol + 2] = _blank(row, startCol + 2, actualOp2 ?? op2);
    grid[row][startCol + 3] = _eq(row, startCol + 3);
    grid[row][startCol + 4] = _ans(row, startCol + 4, result);
    return true;
  }

  // Place equation vertically
  static bool _placeVertical(
    List<List<CrosswordCell>> grid,
    int startRow,
    int col,
    int op1,
    int op2,
    int result,
    String operator,
  ) {
    if (startRow + 4 >= grid.length) return false;
    
    // Check cells and validate intersections are mathematically valid
    int? actualOp1 = op1;
    int? actualOp2 = op2;
    
    for (int i = 0; i <= 4; i++) {
      final cell = grid[startRow + i][col];
      if (cell.type != CellType.empty) {
        if (i == 0) {
          // First operand position
          if (cell.type == CellType.number || cell.type == CellType.answer || cell.type == CellType.blank) {
            final existingValue = int.tryParse(cell.value ?? '') ?? cell.answer;
            if (existingValue != null) {
              actualOp1 = existingValue;
            } else {
              return false;
            }
          } else {
            return false;
          }
        } else if (i == 1) {
          // Operator position
          if (cell.type != CellType.operator || cell.value != operator) {
            return false;
          }
        } else if (i == 2) {
          // Second operand position
          if (cell.type == CellType.number || cell.type == CellType.answer || cell.type == CellType.blank) {
            final existingValue = int.tryParse(cell.value ?? '') ?? cell.answer;
            if (existingValue != null) {
              actualOp2 = existingValue;
            } else {
              return false;
            }
          } else {
            return false;
          }
        } else if (i == 3) {
          // Equals position
          if (cell.type != CellType.equals) {
            return false;
          }
        } else if (i == 4) {
          // Result position
          if (cell.type == CellType.answer || cell.type == CellType.number) {
          if (int.tryParse(cell.value ?? '') != result) return false;
          } else {
          return false;
        }
      }
      }
    }
    
    // Validate the equation is mathematically correct
    if (actualOp1 != null && actualOp2 != null) {
      int calculatedResult;
      switch (operator) {
        case '+':
          calculatedResult = actualOp1 + actualOp2;
          break;
        case '-':
          calculatedResult = actualOp1 - actualOp2;
          break;
        case '×':
          calculatedResult = actualOp1 * actualOp2;
          break;
        case '÷':
          if (actualOp2 == 0) return false;
          calculatedResult = actualOp1 ~/ actualOp2;
          break;
        default:
          return false;
      }
      if (calculatedResult != result) return false;
    }

    grid[startRow][col] = _blank(startRow, col, actualOp1 ?? op1);
    grid[startRow + 1][col] = _op(startRow + 1, col, operator);
    grid[startRow + 2][col] = _blank(startRow + 2, col, actualOp2 ?? op2);
    grid[startRow + 3][col] = _eq(startRow + 3, col);
    grid[startRow + 4][col] = _ans(startRow + 4, col, result);
    return true;
  }

  // Place equation diagonally (slant ↘)
  static bool _placeSlant(
    List<List<CrosswordCell>> grid,
    int startRow,
    int startCol,
    int op1,
    int op2,
    int result,
    String operator,
  ) {
    if (startRow + 4 >= grid.length || startCol + 4 >= grid[startRow].length) return false;
    
    // Check cells and validate intersections are mathematically valid
    int? actualOp1 = op1;
    int? actualOp2 = op2;
    
    for (int i = 0; i <= 4; i++) {
      final cell = grid[startRow + i][startCol + i];
      if (cell.type != CellType.empty) {
        if (i == 0) {
          // First operand position - check if existing value is compatible
          if (cell.type == CellType.number || cell.type == CellType.answer || cell.type == CellType.blank) {
            final existingValue = int.tryParse(cell.value ?? '') ?? cell.answer;
            if (existingValue != null) {
              actualOp1 = existingValue;
            } else {
              return false; // Can't determine value
            }
          } else {
            return false; // Incompatible cell type
          }
        } else if (i == 1) {
          // Operator position - must match
          if (cell.type != CellType.operator || cell.value != operator) {
            return false;
          }
        } else if (i == 2) {
          // Second operand position - check if existing value is compatible
          if (cell.type == CellType.number || cell.type == CellType.answer || cell.type == CellType.blank) {
            final existingValue = int.tryParse(cell.value ?? '') ?? cell.answer;
            if (existingValue != null) {
              actualOp2 = existingValue;
            } else {
              return false; // Can't determine value
            }
          } else {
            return false; // Incompatible cell type
          }
        } else if (i == 3) {
          // Equals position - must be equals
          if (cell.type != CellType.equals) {
            return false;
          }
        } else if (i == 4) {
          // Result position - must match result value
          if (cell.type == CellType.answer || cell.type == CellType.number) {
          if (int.tryParse(cell.value ?? '') != result) return false;
          } else {
          return false;
        }
      }
      }
    }
    
    // Validate the equation is mathematically correct with actual values
    if (actualOp1 != null && actualOp2 != null) {
      int calculatedResult;
      switch (operator) {
        case '+':
          calculatedResult = actualOp1 + actualOp2;
          break;
        case '-':
          calculatedResult = actualOp1 - actualOp2;
          break;
        case '×':
          calculatedResult = actualOp1 * actualOp2;
          break;
        case '÷':
          if (actualOp2 == 0) return false;
          calculatedResult = actualOp1 ~/ actualOp2;
          break;
        default:
          return false;
      }
      if (calculatedResult != result) return false;
    }

    grid[startRow][startCol] = _blank(startRow, startCol, actualOp1 ?? op1);
    grid[startRow + 1][startCol + 1] = _op(startRow + 1, startCol + 1, operator);
    grid[startRow + 2][startCol + 2] = _blank(startRow + 2, startCol + 2, actualOp2 ?? op2);
    grid[startRow + 3][startCol + 3] = _eq(startRow + 3, startCol + 3);
    grid[startRow + 4][startCol + 4] = _ans(startRow + 4, startCol + 4, result);
    return true;
  }

  // Place equation diagonally reverse (slant ↙)
  static bool _placeSlantReverse(
    List<List<CrosswordCell>> grid,
    int startRow,
    int startCol,
    int op1,
    int op2,
    int result,
    String operator,
  ) {
    if (startRow + 4 >= grid.length || startCol < 4) return false;
    
    // Check cells and validate intersections are mathematically valid
    int? actualOp1 = op1;
    int? actualOp2 = op2;
    
    for (int i = 0; i <= 4; i++) {
      final cell = grid[startRow + i][startCol - i];
      if (cell.type != CellType.empty) {
        if (i == 0) {
          // First operand position
          if (cell.type == CellType.number || cell.type == CellType.answer || cell.type == CellType.blank) {
            final existingValue = int.tryParse(cell.value ?? '') ?? cell.answer;
            if (existingValue != null) {
              actualOp1 = existingValue;
            } else {
              return false;
            }
          } else {
            return false;
          }
        } else if (i == 1) {
          // Operator position
          if (cell.type != CellType.operator || cell.value != operator) {
            return false;
          }
        } else if (i == 2) {
          // Second operand position
          if (cell.type == CellType.number || cell.type == CellType.answer || cell.type == CellType.blank) {
            final existingValue = int.tryParse(cell.value ?? '') ?? cell.answer;
            if (existingValue != null) {
              actualOp2 = existingValue;
            } else {
              return false;
            }
          } else {
            return false;
          }
        } else if (i == 3) {
          // Equals position
          if (cell.type != CellType.equals) {
            return false;
          }
        } else if (i == 4) {
          // Result position
          if (cell.type == CellType.answer || cell.type == CellType.number) {
          if (int.tryParse(cell.value ?? '') != result) return false;
          } else {
          return false;
        }
      }
      }
    }
    
    // Validate the equation is mathematically correct
    if (actualOp1 != null && actualOp2 != null) {
      int calculatedResult;
      switch (operator) {
        case '+':
          calculatedResult = actualOp1 + actualOp2;
          break;
        case '-':
          calculatedResult = actualOp1 - actualOp2;
          break;
        case '×':
          calculatedResult = actualOp1 * actualOp2;
          break;
        case '÷':
          if (actualOp2 == 0) return false;
          calculatedResult = actualOp1 ~/ actualOp2;
          break;
        default:
          return false;
      }
      if (calculatedResult != result) return false;
    }

    grid[startRow][startCol] = _blank(startRow, startCol, actualOp1 ?? op1);
    grid[startRow + 1][startCol - 1] = _op(startRow + 1, startCol - 1, operator);
    grid[startRow + 2][startCol - 2] = _blank(startRow + 2, startCol - 2, actualOp2 ?? op2);
    grid[startRow + 3][startCol - 3] = _eq(startRow + 3, startCol - 3);
    grid[startRow + 4][startCol - 4] = _ans(startRow + 4, startCol - 4, result);
    return true;
  }

  // Place equations with advanced patterns (for medium and hard)
  // Places 2-3 equations randomly
  static void _placeEquationsAdvanced(
    List<List<CrosswordCell>> grid,
    List<Map<String, int>> equations,
    String operator,
  ) {
    _clearGrid(grid);
    
    if (equations.isEmpty) return;
    
    final patterns = ['horizontal', 'vertical', 'slant', 'slantReverse'];
    final placedEquations = <Map<String, int>>[];
    
    // Randomly choose to place 2 or 3 equations, but ensure at least 2
    final targetCount = equations.length >= 3 ? (_rng.nextInt(2) + 2) : equations.length; // 2 or 3 if available
    
    // Try to place equations with advanced patterns
    for (final eq in equations) {
      if (placedEquations.length >= targetCount) break;
      
      final op1 = eq['op1']!;
      final op2 = eq['op2']!;
      final result = eq['result']!;
      final opSymbol = _getOperatorSymbol(operator);
      
      bool placed = false;
      final shuffledPatterns = List<String>.from(patterns)..shuffle(_rng);
      
      for (final pattern in shuffledPatterns) {
        if (placed) break;
        
        // Try multiple positions (increase attempts for better placement)
        for (int attempt = 0; attempt < 50; attempt++) {
          if (pattern == 'horizontal') {
            final row = _rng.nextInt(grid.length);
            final col = _rng.nextInt(grid[0].length - 4);
            if (_placeHorizontal(grid, row, col, op1, op2, result, opSymbol)) {
              placed = true;
              placedEquations.add(eq);
              break;
            }
          } else if (pattern == 'vertical') {
            final row = _rng.nextInt(grid.length - 4);
            final col = _rng.nextInt(grid[0].length);
            if (_placeVertical(grid, row, col, op1, op2, result, opSymbol)) {
              placed = true;
              placedEquations.add(eq);
              break;
            }
          } else if (pattern == 'slant') {
            final row = _rng.nextInt(grid.length - 4);
            final col = _rng.nextInt(grid[0].length - 4);
            if (_placeSlant(grid, row, col, op1, op2, result, opSymbol)) {
              placed = true;
              placedEquations.add(eq);
              break;
            }
          } else if (pattern == 'slantReverse') {
            final row = _rng.nextInt(grid.length - 4);
            final col = _rng.nextInt(grid[0].length - 4) + 4;
            if (_placeSlantReverse(grid, row, col, op1, op2, result, opSymbol)) {
              placed = true;
              placedEquations.add(eq);
              break;
            }
          }
        }
      }
      
      // Fallback: force place horizontally if nothing worked
      if (!placed && placedEquations.length < targetCount) {
        for (int row = 0; row < grid.length; row++) {
          for (int col = 0; col <= grid[0].length - 5; col++) {
            if (_placeHorizontal(grid, row, col, op1, op2, result, opSymbol)) {
              placedEquations.add(eq);
              placed = true;
              break;
            }
          }
          if (placed) break;
        }
      }
    }
    
    // Final fallback: if we didn't place enough, use simple horizontal placement
    if (placedEquations.length < 2 && equations.length >= 2) {
      _clearGrid(grid);
      // Place first 2 equations horizontally
      for (int i = 0; i < 2 && i < equations.length; i++) {
        final eq = equations[i];
        final op1 = eq['op1']!;
        final op2 = eq['op2']!;
        final result = eq['result']!;
        final opSymbol = _getOperatorSymbol(operator);
        final row = i * 2; // Place on rows 0 and 2
        if (row < grid.length) {
          _placeHorizontal(grid, row, 0, op1, op2, result, opSymbol);
        }
      }
    }
  }

  static String _getOperatorSymbol(String operator) {
    switch (operator.toLowerCase()) {
      case 'addition':
        return '+';
      case 'subtraction':
        return '-';
      case 'multiplication':
        return '×';
      case 'division':
        return '÷';
      default:
        return '+';
    }
  }
}
