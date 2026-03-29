import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pracpro/modules/basic_operators/addition/crossword_cell.dart';
import 'package:pracpro/modules/basic_operators/addition/crossword_grid_generator.dart';
import 'package:pracpro/modules/basic_operators/addition/game_theme.dart';
import 'package:pracpro/services/activity_progress_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class CrosswordMathGameScreen extends StatefulWidget {
  final String operator;
  final String difficulty;
  final Map<String, dynamic>? config;
  final String? classroomId;

  const CrosswordMathGameScreen({
    super.key,
    required this.operator,
    required this.difficulty,
    this.config,
    this.classroomId,
  });

  @override
  State<CrosswordMathGameScreen> createState() =>
      _CrosswordMathGameScreenState();
}

class _CrosswordMathGameScreenState extends State<CrosswordMathGameScreen> {
  late int _remainingSeconds;
  Timer? _timer;

  late List<List<List<CrosswordCell>>> _rounds; // Multiple grids for multiple rounds
  int _currentRound = 0; // Current round/page index
  bool _finished = false;
  bool _answersChecked = false; 
  int _correct = 0;
  int _totalBlanks = 0;
  bool _isLoading = true;
  List<int> _correctPerRound = []; // Track correct answers per round
  List<int> _totalBlanksPerRound = []; // Track total blanks per round
  List<bool> _roundCompleted = []; // Track which rounds have been completed (answers checked)

  final Map<int, Map<String, TextEditingController>> _roundControllers = {}; // Controllers per round (key: roundIndex)
  final supabase = Supabase.instance.client;
  final _activityProgressService = ActivityProgressService();
  bool _progressSaved = false; // Track if progress has been saved
  bool _isSavingProgress = false; // Prevent concurrent saves
  
  // Store game metadata when game starts - reuse for all attempts (including Try Again)
  String? _gameId;
  String _gameTitle = 'Crossword Math';
  bool _gameMetadataLoaded = false;

  // Get number of rounds based on difficulty
  int get _numRounds {
    switch (widget.difficulty.toLowerCase()) {
      case 'easy':
        return 1;
      case 'medium':
        return 2;
      case 'hard':
        return 3;
      default:
        return 1;
    }
  }

  // Get current grid
  List<List<CrosswordCell>> get _grid => _rounds[_currentRound];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final min = widget.config?['min'] ?? 1;
    final max = widget.config?['max'] ?? 10;
    final timeSec = 120;

    // Load game metadata ONCE when game starts - reuse for all attempts
    if (!_gameMetadataLoaded) {
      await _loadGameMetadata();
    }

    try {
      // Generate puzzles for all rounds based on difficulty
      // Easy: 1 board, Medium: 2 boards, Hard: 3 boards
      _rounds = [];
      _totalBlanksPerRound = [];
      _roundCompleted = [];
      for (int i = 0; i < _numRounds; i++) {
        // Always generate fresh puzzles for variety (random operand combinations)
        final gen = CrosswordGridGenerator.generate(
          operator: widget.operator,
          difficulty: widget.difficulty,
          minVal: min,
          maxVal: max,
        );
        _rounds.add(gen.grid);
        final roundBlanks = gen.grid.expand((r) => r).where((c) => c.type == CellType.blank).length;
        _totalBlanksPerRound.add(roundBlanks);
        _correctPerRound.add(0); // Initialize correct count per round
        _roundCompleted.add(false); // No rounds completed yet
      }

      // Calculate total blanks across all rounds
      _totalBlanks = _rounds.fold(0, (sum, grid) =>
          sum + grid.expand((r) => r).where((c) => c.type == CellType.blank).length);

      _currentRound = 0;
      _remainingSeconds = timeSec;
      _isLoading = false;
      _startTimer();
      setState(() {});
    } catch (e, st) {
      // Fallback: generate at least one round
      final gen = CrosswordGridGenerator.generate(
        operator: widget.operator,
        difficulty: widget.difficulty,
        minVal: min,
        maxVal: max,
      );
      _rounds = [gen.grid];
      final roundBlanks = gen.grid.expand((r) => r).where((c) => c.type == CellType.blank).length;
      _totalBlanksPerRound = [roundBlanks];
      _correctPerRound = [0];
      _roundCompleted = [false];
      _remainingSeconds = timeSec;
      _isLoading = false;
      _startTimer();
      setState(() {});
    }
  }

  /// Load game metadata once when game starts
  /// This ensures all attempts (including Try Again) use the same gameId/gameTitle
  /// IMPORTANT: Always use null gameId for Crossword Math to prevent mixing with other games
  /// This ensures Crossword Math groups by title+difficulty+operator, not by entity_id
  Future<void> _loadGameMetadata() async {
    if (_gameMetadataLoaded) return; // Don't reload
    
    // For Crossword Math, always use null gameId and rely on title-based grouping
    // This prevents mixing with other games (like "ywv") that have entity_id
    // All Crossword Math attempts will group by: "Crossword Math|easy|addition"
    _gameId = null;
    _gameTitle = 'Crossword Math';
    _gameMetadataLoaded = true;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_answersChecked || _finished) {
        _timer?.cancel();
        return;
      }
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _finish();
      }
    });
  }

  void _finish() async {
    _timer?.cancel();
    setState(() => _finished = true);
    
    // Check all rounds when timer runs out
    _correct = _countCorrect();
    
    // Mark all rounds as checked (even if incomplete)
    for (int i = 0; i < _rounds.length; i++) {
      if (!_roundCompleted[i]) {
        // Count correct for this round
        final grid = _rounds[i];
        int roundCorrect = 0;
        for (final row in grid) {
          for (final cell in row) {
            if (cell.type == CellType.blank) {
              final studentAnswer = int.tryParse(cell.value ?? '');
              if (studentAnswer != null) {
                final isCorrect = _validateEquationWithStudentInputForRound(cell, studentAnswer, i);
                cell.isCorrect = isCorrect;
                if (isCorrect) roundCorrect++;
              } else {
                cell.isCorrect = false;
              }
            }
          }
        }
        _correctPerRound[i] = roundCorrect;
        _roundCompleted[i] = true;
      }
    }
    _correct = _correctPerRound.fold(0, (sum, correct) => sum + correct);
    
    // Save progress when timer runs out
    final elapsed = 120 - _remainingSeconds;
    await _recordGameProgress(_correct, elapsed);
    
    // Always show final summary when timer runs out
    _showFinalSummaryDialog();
  }

  int _countCorrect() {
    int totalCorrect = 0;
    
    // Count correct answers across all rounds
    for (int roundIndex = 0; roundIndex < _rounds.length; roundIndex++) {
      int roundCorrect = 0;
      final grid = _rounds[roundIndex];

      for (final row in grid) {
      for (final cell in row) {
        if (cell.type == CellType.blank) {
            final studentAnswer = int.tryParse(cell.value ?? '');
          
          if (studentAnswer == null) {
              cell.isCorrect = false;
            continue;
            }

            final isEquationCorrect = _validateEquationWithStudentInputForRound(cell, studentAnswer, roundIndex);

          if (isEquationCorrect) {
                cell.isCorrect = true;
              roundCorrect++;
              totalCorrect++;
              } else {
                cell.isCorrect = false;
              }
        }
      }
    }

      _correctPerRound[roundIndex] = roundCorrect;
    }

    return totalCorrect;
  }

  bool _validateEquationWithStudentInput(CrosswordCell blankCell, int studentValue) {
    return _validateEquationWithStudentInputForRound(blankCell, studentValue, _currentRound);
  }

  bool _validateEquationWithStudentInputForRound(CrosswordCell blankCell, int studentValue, int roundIndex) {
    final grid = _rounds[roundIndex];
    final row = blankCell.row;
    final col = blankCell.col;

    if (col + 4 < grid[row].length) {
      final opCell = _getCellForRound(row, col + 1, roundIndex);
      final num2Cell = _getCellForRound(row, col + 2, roundIndex);
      final eqCell = _getCellForRound(row, col + 3, roundIndex);
      final answerCell = _getCellForRound(row, col + 4, roundIndex);

      if (opCell?.type == CellType.operator &&
          _hasNumericValue(num2Cell) &&
          eqCell?.type == CellType.equals &&
          _hasNumericValue(answerCell)) {
        final num2 = _getNumericValue(num2Cell);
        final answer = _getNumericValue(answerCell);
        final op = opCell!.value;

        if (num2 != null && answer != null && op != null) {
          final calculated = _calculateAnswer(studentValue, num2, op);
          if (calculated == answer) {
            return true;
          }
        }
      }
    }

    if (col >= 2 && col + 2 < grid[row].length) {
      final num1Cell = _getCellForRound(row, col - 2, roundIndex);
      final opCell = _getCellForRound(row, col - 1, roundIndex);
      final eqCell = _getCellForRound(row, col + 1, roundIndex);
      final answerCell = _getCellForRound(row, col + 2, roundIndex);

      if (_hasNumericValue(num1Cell) &&
          opCell?.type == CellType.operator &&
          eqCell?.type == CellType.equals &&
          _hasNumericValue(answerCell)) {
        final num1 = _getNumericValue(num1Cell);
        final answer = _getNumericValue(answerCell);
        final op = opCell!.value;

        if (num1 != null && answer != null && op != null) {
          final calculated = _calculateAnswer(num1, studentValue, op);
          if (calculated == answer) {
            return true;
          }
        }
      }
    }

    if (col >= 4) {
      final num1Cell = _getCellForRound(row, col - 4, roundIndex);
      final opCell = _getCellForRound(row, col - 3, roundIndex);
      final num2Cell = _getCellForRound(row, col - 2, roundIndex);
      final eqCell = _getCellForRound(row, col - 1, roundIndex);

      if (_hasNumericValue(num1Cell) &&
          opCell?.type == CellType.operator &&
          _hasNumericValue(num2Cell) &&
          eqCell?.type == CellType.equals) {
        final num1 = _getNumericValue(num1Cell);
        final num2 = _getNumericValue(num2Cell);
        final op = opCell!.value;

        if (num1 != null && num2 != null && op != null) {
          final calculated = _calculateAnswer(num1, num2, op);
          if (calculated == studentValue) {
            return true;
          }
        }
      }
    }

    if (row + 4 < _grid.length) {
      final opCell = _getCell(row + 1, col);
      final num2Cell = _getCell(row + 2, col);
      final eqCell = _getCell(row + 3, col);
      final answerCell = _getCell(row + 4, col);

      if (opCell?.type == CellType.operator &&
          _hasNumericValue(num2Cell) &&
          eqCell?.type == CellType.equals &&
          _hasNumericValue(answerCell)) {
        final num2 = _getNumericValue(num2Cell);
        final answer = _getNumericValue(answerCell);
        final op = opCell!.value;

        if (num2 != null && answer != null && op != null) {
          final calculated = _calculateAnswer(studentValue, num2, op);
          if (calculated == answer) {
            return true;
          }
        }
      }
    }

    if (row >= 2 && row + 2 < _grid.length) {
      final num1Cell = _getCell(row - 2, col);
      final opCell = _getCell(row - 1, col);
      final eqCell = _getCell(row + 1, col);
      final answerCell = _getCell(row + 2, col);

      if (_hasNumericValue(num1Cell) &&
          opCell?.type == CellType.operator &&
          eqCell?.type == CellType.equals &&
          _hasNumericValue(answerCell)) {
        final num1 = _getNumericValue(num1Cell);
        final answer = _getNumericValue(answerCell);
        final op = opCell!.value;

        if (num1 != null && answer != null && op != null) {
          final calculated = _calculateAnswer(num1, studentValue, op);
          if (calculated == answer) {
            return true;
          }
        }
      }
    }

    if (row >= 4) {
      final num1Cell = _getCell(row - 4, col);
      final opCell = _getCell(row - 3, col);
      final num2Cell = _getCell(row - 2, col);
      final eqCell = _getCell(row - 1, col);

      if (_hasNumericValue(num1Cell) &&
          opCell?.type == CellType.operator &&
          _hasNumericValue(num2Cell) &&
          eqCell?.type == CellType.equals) {
        final num1 = _getNumericValue(num1Cell);
        final num2 = _getNumericValue(num2Cell);
        final op = opCell!.value;

        if (num1 != null && num2 != null && op != null) {
          final calculated = _calculateAnswer(num1, num2, op);
          if (calculated == studentValue) {
            return true;
          }
        }
      }
    }

    // Slant pattern (↘) - student value is first number (position 0)
    if (row + 4 < grid.length && col + 4 < grid[row].length) {
      final opCell = _getCellForRound(row + 1, col + 1, roundIndex);
      final num2Cell = _getCellForRound(row + 2, col + 2, roundIndex);
      final eqCell = _getCellForRound(row + 3, col + 3, roundIndex);
      final answerCell = _getCellForRound(row + 4, col + 4, roundIndex);

      if (opCell?.type == CellType.operator &&
          _hasNumericValue(num2Cell) &&
          eqCell?.type == CellType.equals &&
          _hasNumericValue(answerCell)) {
        final num2 = _getNumericValue(num2Cell);
        final answer = _getNumericValue(answerCell);
        final op = opCell!.value;

        if (num2 != null && answer != null && op != null) {
          final calculated = _calculateAnswer(studentValue, num2, op);
          if (calculated == answer) {
            return true;
          }
        }
      }
    }

    // Slant pattern (↘) - student value is second number (position 2)
    if (row >= 2 && col >= 2 && row + 2 < grid.length && col + 2 < grid[row].length) {
      final num1Cell = _getCellForRound(row - 2, col - 2, roundIndex);
      final opCell = _getCellForRound(row - 1, col - 1, roundIndex);
      final eqCell = _getCellForRound(row + 1, col + 1, roundIndex);
      final answerCell = _getCellForRound(row + 2, col + 2, roundIndex);

      if (_hasNumericValue(num1Cell) &&
          opCell?.type == CellType.operator &&
          eqCell?.type == CellType.equals &&
          _hasNumericValue(answerCell)) {
        final num1 = _getNumericValue(num1Cell);
        final answer = _getNumericValue(answerCell);
        final op = opCell!.value;

        if (num1 != null && answer != null && op != null) {
          final calculated = _calculateAnswer(num1, studentValue, op);
          if (calculated == answer) {
            return true;
          }
        }
      }
    }

    // Slant pattern (↘) - student value is answer (position 4)
    if (row >= 4 && col >= 4) {
      final num1Cell = _getCellForRound(row - 4, col - 4, roundIndex);
      final opCell = _getCellForRound(row - 3, col - 3, roundIndex);
      final num2Cell = _getCellForRound(row - 2, col - 2, roundIndex);
      final eqCell = _getCellForRound(row - 1, col - 1, roundIndex);

      if (_hasNumericValue(num1Cell) &&
          opCell?.type == CellType.operator &&
          _hasNumericValue(num2Cell) &&
          eqCell?.type == CellType.equals) {
        final num1 = _getNumericValue(num1Cell);
        final num2 = _getNumericValue(num2Cell);
        final op = opCell!.value;

        if (num1 != null && num2 != null && op != null) {
          final calculated = _calculateAnswer(num1, num2, op);
          if (calculated == studentValue) {
            return true;
          }
        }
      }
    }

    // Slant reverse pattern (↙) - student value is first number (position 0)
    if (row + 4 < grid.length && col >= 4) {
      final opCell = _getCellForRound(row + 1, col - 1, roundIndex);
      final num2Cell = _getCellForRound(row + 2, col - 2, roundIndex);
      final eqCell = _getCellForRound(row + 3, col - 3, roundIndex);
      final answerCell = _getCellForRound(row + 4, col - 4, roundIndex);

      if (opCell?.type == CellType.operator &&
          _hasNumericValue(num2Cell) &&
          eqCell?.type == CellType.equals &&
          _hasNumericValue(answerCell)) {
        final num2 = _getNumericValue(num2Cell);
        final answer = _getNumericValue(answerCell);
        final op = opCell!.value;

        if (num2 != null && answer != null && op != null) {
          final calculated = _calculateAnswer(studentValue, num2, op);
          if (calculated == answer) {
            return true;
          }
        }
      }
    }

    // Slant reverse pattern (↙) - student value is second number (position 2)
    if (row >= 2 && row + 2 < grid.length && col >= 2 && col + 2 < grid[row].length) {
      final num1Cell = _getCellForRound(row - 2, col + 2, roundIndex);
      final opCell = _getCellForRound(row - 1, col + 1, roundIndex);
      final eqCell = _getCellForRound(row + 1, col - 1, roundIndex);
      final answerCell = _getCellForRound(row + 2, col - 2, roundIndex);

      if (_hasNumericValue(num1Cell) &&
          opCell?.type == CellType.operator &&
          eqCell?.type == CellType.equals &&
          _hasNumericValue(answerCell)) {
        final num1 = _getNumericValue(num1Cell);
        final answer = _getNumericValue(answerCell);
        final op = opCell!.value;

        if (num1 != null && answer != null && op != null) {
          final calculated = _calculateAnswer(num1, studentValue, op);
          if (calculated == answer) {
            return true;
          }
        }
      }
    }

    // Slant reverse pattern (↙) - student value is answer (position 4)
    if (row >= 4 && col + 4 < grid[row].length) {
      final num1Cell = _getCellForRound(row - 4, col + 4, roundIndex);
      final opCell = _getCellForRound(row - 3, col + 3, roundIndex);
      final num2Cell = _getCellForRound(row - 2, col + 2, roundIndex);
      final eqCell = _getCellForRound(row - 1, col + 1, roundIndex);

      if (_hasNumericValue(num1Cell) &&
          opCell?.type == CellType.operator &&
          _hasNumericValue(num2Cell) &&
          eqCell?.type == CellType.equals) {
        final num1 = _getNumericValue(num1Cell);
        final num2 = _getNumericValue(num2Cell);
        final op = opCell!.value;

        if (num1 != null && num2 != null && op != null) {
          final calculated = _calculateAnswer(num1, num2, op);
          if (calculated == studentValue) {
            return true;
          }
        }
      }
    }

    return false;
  }

  bool _hasNumericValue(CrosswordCell? cell) {
    if (cell == null) return false;
    if (cell.type == CellType.number || cell.type == CellType.answer) {
      return cell.value != null && cell.value!.isNotEmpty;
    }
    if (cell.type == CellType.blank) {
      return cell.value != null && cell.value!.isNotEmpty && int.tryParse(cell.value!) != null;
    }
    return false;
  }

  int? _getNumericValue(CrosswordCell? cell) {
    if (cell == null) return null;
    if (cell.type == CellType.number || cell.type == CellType.answer) {
      return int.tryParse(cell.value ?? '');
    }
    if (cell.type == CellType.blank) {
      return int.tryParse(cell.value ?? '');
    }
    return null;
  }

  int? _checkPatternForBlankCell(CrosswordCell blankCell) {
    final row = blankCell.row;
    final col = blankCell.col;

    if (col + 4 < _grid[row].length) {
      final opCell = _getCell(row, col + 1);
      final num2Cell = _getCell(row, col + 2);
      final eqCell = _getCell(row, col + 3);
      final answerCell = _getCell(row, col + 4);

      if (opCell?.type == CellType.operator &&
          _hasNumericValue(num2Cell) &&
          eqCell?.type == CellType.equals &&
          _hasNumericValue(answerCell)) {
        final num2 = _getNumericValue(num2Cell);
        final answer = _getNumericValue(answerCell);
        final op = opCell!.value;

        if (num2 != null && answer != null && op != null) {
          return _calculateReverseAnswer(answer, num2, op, isFirst: true);
        }
      }
    }

    if (col >= 2 && col + 2 < _grid[row].length) {
      final num1Cell = _getCell(row, col - 2);
      final opCell = _getCell(row, col - 1);
      final eqCell = _getCell(row, col + 1);
      final answerCell = _getCell(row, col + 2);

      if (_hasNumericValue(num1Cell) &&
          opCell?.type == CellType.operator &&
          eqCell?.type == CellType.equals &&
          _hasNumericValue(answerCell)) {
        final num1 = _getNumericValue(num1Cell);
        final answer = _getNumericValue(answerCell);
        final op = opCell!.value;

        if (num1 != null && answer != null && op != null) {
          return _calculateReverseAnswer(answer, num1, op, isFirst: false);
        }
      }
    }

    if (col >= 4) {
      final num1Cell = _getCell(row, col - 4);
      final opCell = _getCell(row, col - 3);
      final num2Cell = _getCell(row, col - 2);
      final eqCell = _getCell(row, col - 1);

      if (_hasNumericValue(num1Cell) &&
          opCell?.type == CellType.operator &&
          _hasNumericValue(num2Cell) &&
          eqCell?.type == CellType.equals) {
        final num1 = _getNumericValue(num1Cell);
        final num2 = _getNumericValue(num2Cell);
        final op = opCell!.value;

        if (num1 != null && num2 != null && op != null) {
          return _calculateAnswer(num1, num2, op);
        }
      }
    }

    if (row + 4 < _grid.length) {
      final opCell = _getCell(row + 1, col);
      final num2Cell = _getCell(row + 2, col);
      final eqCell = _getCell(row + 3, col);
      final answerCell = _getCell(row + 4, col);

      if (opCell?.type == CellType.operator &&
          _hasNumericValue(num2Cell) &&
          eqCell?.type == CellType.equals &&
          _hasNumericValue(answerCell)) {
        final num2 = _getNumericValue(num2Cell);
        final answer = _getNumericValue(answerCell);
        final op = opCell!.value;

        if (num2 != null && answer != null && op != null) {
          return _calculateReverseAnswer(answer, num2, op, isFirst: true);
        }
      }
    }

    if (row >= 2 && row + 2 < _grid.length) {
      final num1Cell = _getCell(row - 2, col);
      final opCell = _getCell(row - 1, col);
      final eqCell = _getCell(row + 1, col);
      final answerCell = _getCell(row + 2, col);

      if (_hasNumericValue(num1Cell) &&
          opCell?.type == CellType.operator &&
          eqCell?.type == CellType.equals &&
          _hasNumericValue(answerCell)) {
        final num1 = _getNumericValue(num1Cell);
        final answer = _getNumericValue(answerCell);
        final op = opCell!.value;

        if (num1 != null && answer != null && op != null) {
          return _calculateReverseAnswer(answer, num1, op, isFirst: false);
        }
      }
    }

    if (row >= 4) {
      final num1Cell = _getCell(row - 4, col);
      final opCell = _getCell(row - 3, col);
      final num2Cell = _getCell(row - 2, col);
      final eqCell = _getCell(row - 1, col);

      if (_hasNumericValue(num1Cell) &&
          opCell?.type == CellType.operator &&
          _hasNumericValue(num2Cell) &&
          eqCell?.type == CellType.equals) {
        final num1 = _getNumericValue(num1Cell);
        final num2 = _getNumericValue(num2Cell);
        final op = opCell!.value;

        if (num1 != null && num2 != null && op != null) {
          return _calculateAnswer(num1, num2, op);
        }
      }
    }

    return null;
  }

  int? _calculateReverseAnswer(int answer, int knownOperand, String op, {required bool isFirst}) {
    switch (op) {
      case '+':
        return answer - knownOperand;
      case '-':
        if (isFirst) {
          return answer + knownOperand;
        } else {
          return knownOperand - answer;
        }
      case '×':
      case '*':
        if (knownOperand != 0 && answer % knownOperand == 0) {
          return answer ~/ knownOperand;
        }
        return null;
      case '÷':
      case '/':
        if (isFirst) {
          return answer * knownOperand;
        } else {
          return knownOperand ~/ answer;
        }
      default:
        return null;
    }
  }

  CrosswordCell? _getCell(int row, int col) {
    return _getCellForRound(row, col, _currentRound);
  }

  CrosswordCell? _getCellForRound(int row, int col, int roundIndex) {
    if (roundIndex < 0 || roundIndex >= _rounds.length) return null;
    final grid = _rounds[roundIndex];
    if (row < 0 || row >= grid.length || col < 0 || col >= grid[row].length) {
      return null;
    }
    return grid[row][col];
  }

  int? _calculateAnswer(int num1, int num2, String op) {
    switch (op) {
      case '+':
        return num1 + num2;
      case '-':
        return num1 - num2;
      case '×':
      case '*':
        return num1 * num2;
      case '÷':
      case '/':
        if (num2 != 0) return num1 ~/ num2;
        return null;
      default:
        return null;
    }
  }

  Future<void> _recordGameProgress(int score, int elapsed) async {
    // Prevent duplicate saves for the same attempt
    // Only save when all rounds are completed (handled by caller)
    if (_progressSaved || _isSavingProgress) return;
    
    // Double check: Only proceed if all rounds are completed
    final allRoundsCompleted = _roundCompleted.isNotEmpty && _roundCompleted.every((completed) => completed);
    if (!allRoundsCompleted) {
      _isSavingProgress = false;
      return; // Don't save if rounds aren't all complete
    }
    
    // Prevent concurrent saves
    _isSavingProgress = true;
    
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        _isSavingProgress = false;
        return;
      }

      // Validate that game was properly initialized
      if (_totalBlanks <= 0) {
        // Game wasn't properly initialized, don't save
        _isSavingProgress = false;
        return;
      }

      // Ensure game metadata is loaded (should be loaded in _bootstrap, but double-check)
      if (!_gameMetadataLoaded) {
        await _loadGameMetadata();
      }

      // Use stored gameId and gameTitle - ensures consistency across all attempts
      // This is critical for "Try Again" - all attempts must use the same game metadata

      // Get classroom_id if not provided - try to get from user's current classroom
      String? finalClassroomId = widget.classroomId;
      if (finalClassroomId == null || finalClassroomId.isEmpty) {
        try {
          final classroomsResponse = await supabase
              .from('user_classrooms')
              .select('classroom_id')
              .eq('user_id', user.id)
              .eq('status', 'accepted')
              .order('joined_at', ascending: false)
              .limit(1);
          
          if (classroomsResponse.isNotEmpty) {
            finalClassroomId = classroomsResponse.first['classroom_id'] as String?;
          }
        } catch (e) {
          // If we can't get classroom_id, continue without it
        }
      }

      // Save to unified activity_progress table
      // IMPORTANT: Use stored _gameId and _gameTitle to ensure all attempts
      // (including Try Again) are grouped under the same game
      await _activityProgressService.saveGameProgress(
        userId: user.id,
        gameId: _gameId, // Use stored gameId from initialization
        gameTitle: _gameTitle, // Use stored gameTitle from initialization
        operator: widget.operator,
        difficulty: widget.difficulty.toLowerCase(),
        score: score,
        totalItems: _totalBlanks,
        status: score == _totalBlanks ? 'completed' : 'incomplete',
        elapsedTime: elapsed,
        classroomId: finalClassroomId,
      );
      
      _progressSaved = true; // Mark as saved to prevent duplicates
    } catch (e, stackTrace) {
      // Log error for debugging but don't block UI
      // Re-throw to ensure caller knows save failed
      print('Error saving game progress: $e');
      print('Stack trace: $stackTrace');
      // Don't mark as saved if there was an error
      _progressSaved = false;
    } finally {
      _isSavingProgress = false;
    }
  }

  void _checkAnswers() async {
    if (_answersChecked) return;
    
    HapticFeedback.lightImpact();
    
    // Check answers for current round only
    final grid = _rounds[_currentRound];
    int roundCorrect = 0;
    
    for (final row in grid) {
      for (final cell in row) {
        if (cell.type == CellType.blank) {
          final studentAnswer = int.tryParse(cell.value ?? '');
          
          if (studentAnswer == null) {
            cell.isCorrect = false;
            continue;
          }

          final isEquationCorrect = _validateEquationWithStudentInputForRound(cell, studentAnswer, _currentRound);

          if (isEquationCorrect) {
            cell.isCorrect = true;
            roundCorrect++;
          } else {
            cell.isCorrect = false;
          }
        }
      }
    }
    
    // Update current round's correct count
    _correctPerRound[_currentRound] = roundCorrect;
    _roundCompleted[_currentRound] = true;
    
    // Recalculate total correct across all rounds
    _correct = _correctPerRound.fold(0, (sum, correct) => sum + correct);
    
    setState(() {
      _answersChecked = true;
    });

    // Check if all rounds are completed
    final allRoundsCompleted = _roundCompleted.every((completed) => completed);

    final elapsed = 120 - _remainingSeconds;
    
    // Only save progress when ALL rounds are completed to ensure we capture the total score
    if (allRoundsCompleted) {
      await _recordGameProgress(_correct, elapsed);
      _showFinalSummaryDialog();
    } else {
      // Don't save progress yet - wait until all rounds are done
      _showCurrentRoundResultDialog();
  }
  }

  // Check if current round can proceed to next (all blanks filled)
  bool _canProceedToNext() {
    if (_currentRound >= _numRounds - 1) return false; // Already at last round
    if (!_roundCompleted[_currentRound]) return false; // Current round not completed
    
    // Check if all previous rounds are completed
    for (int i = 0; i <= _currentRound; i++) {
      if (!_roundCompleted[i]) return false;
    }
    return true;
  }

  void _showCurrentRoundResultDialog() {
    final grid = _rounds[_currentRound];
    final roundCorrect = _correctPerRound[_currentRound];
    final roundTotal = _totalBlanksPerRound[_currentRound];
    final roundWrong = roundTotal - roundCorrect;
    
    List<String> wrongAnswers = [];
    for (int r = 0; r < grid.length; r++) {
      for (int c = 0; c < grid[r].length; c++) {
        final cell = grid[r][c];
        if (cell.type == CellType.blank && !cell.isCorrect && cell.value != null && cell.value!.isNotEmpty) {
          wrongAnswers.add('Row ${r + 1}, Col ${c + 1}: "${cell.value}"');
        }
      }
    }
    
    final canProceed = _canProceedToNext();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              roundCorrect == roundTotal ? Icons.celebration : (roundCorrect > roundTotal / 2 ? Icons.thumb_up : Icons.sentiment_neutral),
              color: roundCorrect == roundTotal ? Colors.amber : (roundCorrect > roundTotal / 2 ? Colors.green : Colors.orange),
              size: 32,
            ),
            const SizedBox(width: 8),
            Text(roundCorrect == roundTotal ? 'Perfect!' : 'Round Complete!'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Round ${_currentRound + 1} Results:',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You got $roundCorrect / $roundTotal correct.',
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
              if (roundWrong > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Wrong Answers ($roundWrong):',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...wrongAnswers.take(5).map((answer) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• $answer',
                          style: TextStyle(fontSize: 12, color: Colors.red[700]),
                        ),
                      )),
                      if (wrongAnswers.length > 5)
                        Text(
                          '... and ${wrongAnswers.length - 5} more',
                          style: TextStyle(fontSize: 12, color: Colors.red[700], fontStyle: FontStyle.italic),
                        ),
                    ],
                  ),
                ),
              ],
              if (canProceed && _currentRound < _numRounds - 1) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Great! Proceed to Round ${_currentRound + 2}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (canProceed && _currentRound < _numRounds - 1) {
                // Auto-advance to next round
                  setState(() {
                  _currentRound++;
                  _answersChecked = false; // Next round not checked yet
                });
              }
            },
            child: Text(canProceed && _currentRound < _numRounds - 1 ? 'Continue to Next Round' : 'OK'),
          ),
        ],
      ),
    );
  }

  void _showFinalSummaryDialog() {
    final totalCorrect = _correct;
    final totalWrong = _totalBlanks - _correct;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              totalCorrect == _totalBlanks ? Icons.celebration : (totalCorrect > _totalBlanks / 2 ? Icons.thumb_up : Icons.sentiment_neutral),
              color: totalCorrect == _totalBlanks ? Colors.amber : (totalCorrect > _totalBlanks / 2 ? Colors.green : Colors.orange),
              size: 32,
            ),
            const SizedBox(width: 8),
            Text(totalCorrect == _totalBlanks ? 'Perfect Game!' : 'Game Complete!'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
              ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'All rounds completed!',
                style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[900],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Final Score: $totalCorrect / $_totalBlanks',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Show results per round
              ...List.generate(_numRounds, (index) {
                final roundCorrect = _correctPerRound[index];
                final roundTotal = _totalBlanksPerRound[index];
                final roundWrong = roundTotal - roundCorrect;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
            child: Container(
                    padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                      color: roundCorrect == roundTotal ? Colors.green[50] : Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: roundCorrect == roundTotal ? Colors.green[200]! : Colors.orange[200]!,
                      ),
              ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              roundCorrect == roundTotal ? Icons.check_circle : Icons.error_outline,
                              color: roundCorrect == roundTotal ? Colors.green[700] : Colors.orange[700],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Round ${index + 1}:',
                style: TextStyle(
                                fontSize: 14,
                  fontWeight: FontWeight.bold,
                                color: roundCorrect == roundTotal ? Colors.green[700] : Colors.orange[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Correct: $roundCorrect / $roundTotal',
                          style: const TextStyle(fontSize: 13),
              ),
                        if (roundWrong > 0)
                          Text(
                            'Wrong: $roundWrong',
                            style: TextStyle(fontSize: 13, color: Colors.red[700]),
          ),
        ],
                    ),
                  ),
                );
              }),
              if (totalWrong > 0) ...[
                const SizedBox(height: 12),
                Text(
                  'Total Errors: $totalWrong',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showResultDialog() {
    // Legacy method - redirect to appropriate dialog
    final allRoundsCompleted = _roundCompleted.every((completed) => completed);
    if (allRoundsCompleted) {
      _showFinalSummaryDialog();
    } else {
      _showCurrentRoundResultDialog();
    }
  }

  void _reset() {
    Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst || !route.willHandlePopInternally);
    
    setState(() {
      // Reset game state for "Try Again"
      // IMPORTANT: DO NOT reset _gameId, _gameTitle, or _gameMetadataLoaded
      // These must persist across attempts to ensure all attempts are grouped correctly
      // Reset all grids across all rounds
      for (final grid in _rounds) {
        for (final c in grid.expand((r) => r)) {
        if (c.type == CellType.blank) {
          c.value = null;
          c.isCorrect = false;
        }
      }
      }
      _currentRound = 0;
      _correct = 0;
      _finished = false;
      _answersChecked = false;
      _remainingSeconds = 120;
      // Reset all controllers across all rounds
      for (final roundControllers in _roundControllers.values) {
        for (final controller in roundControllers.values) {
        controller.clear();
      }
      }
      // Reset per-round correct counts and completion status
      _correctPerRound = List.generate(_numRounds, (_) => 0);
      _roundCompleted = List.generate(_numRounds, (_) => false);
      // Reset progress saved flag so the next attempt can be saved
      _progressSaved = false;
      _isSavingProgress = false;
      _startTimer();
    });
  }

  String _fmt(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  void _goToRound(int roundIndex) {
    if (roundIndex < 0 || roundIndex >= _rounds.length) return;
    
    // Can only go forward if previous rounds are completed
    if (roundIndex > _currentRound) {
      if (!_canProceedToNext()) {
        // Show message that current round must be completed first
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please complete the current round before proceeding to the next one.'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
    }
    
    setState(() {
      _currentRound = roundIndex;
      // Set answers checked state based on whether round is completed
      _answersChecked = _roundCompleted[roundIndex];
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final roundControllers in _roundControllers.values) {
      for (final c in roundControllers.values) {
      c.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final timeText = _fmt(_remainingSeconds);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
          '${widget.operator[0].toUpperCase()}${widget.operator.substring(1)} - ${widget.difficulty} CrossMath',
            ),
            if (_numRounds > 1)
              Text(
                'Round ${_currentRound + 1} / $_numRounds',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                timeText,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              // Round navigation (only show if more than 1 round)
              if (_numRounds > 1) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: 80,
                        height: 40,
                        child: ElevatedButton.icon(
                          onPressed: _currentRound > 0 ? () => _goToRound(_currentRound - 1) : null,
                          icon: const Icon(Icons.arrow_back, size: 16),
                          label: const Text('Prev', style: TextStyle(fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            minimumSize: const Size(80, 40),
                            maximumSize: const Size(80, 40),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Round ${_currentRound + 1} / $_numRounds',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (_roundCompleted[_currentRound])
                                Text(
                                  '✓ Done',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 80,
                        height: 40,
                        child: ElevatedButton.icon(
                          onPressed: _canProceedToNext()
                              ? () {
                                  setState(() {
                                    _currentRound++;
                                    _answersChecked = false;
                                  });
                                }
                              : null,
                          icon: const Icon(Icons.arrow_forward, size: 16),
                          label: const Text('Next', style: TextStyle(fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            minimumSize: const Size(80, 40),
                            maximumSize: const Size(80, 40),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // Current round's grid
              for (int r = 0; r < _grid.length; r++)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int c = 0; c < _grid[r].length; c++)
                      _buildCell(_grid[r][c]),
                  ],
                ),
              const SizedBox(height: 24),
              _buildLegend(),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    if (!_roundCompleted[_currentRound])
                      Flexible(
                        child: ElevatedButton(
                onPressed: _checkAnswers,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                          child: const Text('Check Answers', style: TextStyle(fontSize: 16)),
                        ),
                    )
                  else ...[
                      Flexible(
                        child: ElevatedButton(
                      onPressed: null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                          child: Text(
                            _canProceedToNext() && _currentRound < _numRounds - 1
                                ? 'Round Complete → Next'
                                : (_roundCompleted.every((c) => c) ? 'All Complete' : 'Round Complete'),
                            style: const TextStyle(fontSize: 14),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                    ),
                      ),
                      // Only show Try Again when all rounds are completed
                      if (_roundCompleted.every((c) => c)) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: ElevatedButton(
                      onPressed: () {
                        _reset();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                            child: const Text('Try Again', style: TextStyle(fontSize: 16)),
                          ),
                    ),
                      ],
                  ],
                ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Correct: $_correct / $_totalBlanks',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _answersChecked
                      ? (_correct == _totalBlanks ? Colors.green : Colors.orange)
                      : Colors.black,
              ),
              ),
              if (_answersChecked) ...[
                const SizedBox(height: 8),
                Text(
                  _correct == _totalBlanks
                      ? 'Perfect! All answers are correct! 🎉'
                      : 'Some answers are incorrect. Check the highlighted cells above.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Timer stopped. Click "Try Again" to restart or use "Go Back" in the dialog.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Column(
      children: [
        const Text(
          '🧭 LEGEND',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            _legendTile(Colors.purple[100]!, 'Given Number / Answer'),
            _legendTile(Colors.blue[100]!, 'Operator (+, -, ×, ÷)'),
            _legendTile(Colors.green[100]!, 'Equal (=)'),
            _legendTile(Colors.grey[100]!, 'Your Answer (type here)'),
          ],
        ),
      ],
    );
  }

  Widget _legendTile(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  Widget _buildCell(CrosswordCell cell) {
    switch (cell.type) {
      case CellType.blank:
        return _editableCell(cell);
      default:
        return _staticTile(cell);
    }
  }

  Widget _editableCell(CrosswordCell cell) {
    final key = '${cell.row}-${cell.col}';
    // Initialize controllers map for current round if needed
    if (!_roundControllers.containsKey(_currentRound)) {
      _roundControllers[_currentRound] = {};
    }
    if (!_roundControllers[_currentRound]!.containsKey(key)) {
      _roundControllers[_currentRound]![key] = TextEditingController(text: cell.value ?? '');
    }
    final controller = _roundControllers[_currentRound]![key]!;
    
    Color backgroundColor;
    Color borderColor;
    double borderWidth = 2;
    
    if (_roundCompleted[_currentRound]) {
      if (cell.isCorrect == true) {
        backgroundColor = Colors.green[100]!;
        borderColor = Colors.green;
      } else if (cell.value != null && cell.value!.isNotEmpty) {
        backgroundColor = Colors.red[100]!;
        borderColor = Colors.red;
      } else {
        backgroundColor = Colors.grey[200]!;
        borderColor = Colors.grey;
      }
    } else {
      backgroundColor = Colors.grey[100]!;
      borderColor = Colors.grey;
    }

    return Container(
      width: 60,
      height: 60,
      margin: const EdgeInsets.all(4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(GameTheme.borderRadius),
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          TextField(
        controller: controller,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(border: InputBorder.none),
        style: GameTheme.tileText.copyWith(fontSize: 22),
            enabled: !_roundCompleted[_currentRound], 
        onChanged: (val) {
              if (!_roundCompleted[_currentRound]) {
          cell.value = val;
          setState(() {});
              }
            },
          ),
          if (_roundCompleted[_currentRound] && cell.value != null && cell.value!.isNotEmpty && cell.isCorrect != true)
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
          if (_answersChecked && cell.isCorrect == true)
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _staticTile(CrosswordCell cell) {
    Color bg, fg;
    switch (cell.type) {
      case CellType.operator:
        bg = Colors.blue[100]!;
        fg = Colors.blue[800]!;
        break;
      case CellType.equals:
        bg = Colors.green[100]!;
        fg = Colors.green[800]!;
        break;
      case CellType.number:
      case CellType.answer:
        bg = Colors.purple[100]!;
        fg = Colors.purple[800]!;
        break;
      default:
        bg = Colors.white;
        fg = Colors.black;
    }
    return Container(
      width: 60,
      height: 60,
      margin: const EdgeInsets.all(4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(GameTheme.borderRadius),
      ),
      child: Text(cell.value ?? '', style: GameTheme.tileText.copyWith(color: fg)),
    );
  }
}
