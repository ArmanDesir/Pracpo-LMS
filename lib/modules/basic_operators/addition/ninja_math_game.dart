import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'widgets/game_button.dart';
import 'game_theme.dart';

class NinjaMathGameScreen extends StatefulWidget {
  final String difficulty;
  final Map<String, dynamic>? config;
  final String operator;
  final String? classroomId; // Optional classroom ID
  final List<Map<String, dynamic>>? presetRounds; // Optional teacher-assigned rounds
  final bool isAssigned; // For UI hint only

  const NinjaMathGameScreen({
    super.key,
    required this.difficulty,
    required this.operator,
    this.config,
    this.classroomId,
    this.presetRounds,
    this.isAssigned = false,
  });

  @override
  State<NinjaMathGameScreen> createState() => _NinjaMathGameScreenState();
}

class _NinjaMathGameScreenState extends State<NinjaMathGameScreen> {
  late int _remainingSeconds;
  late Timer _timer;
  bool _gameFinished = false;
  bool _showReview = false;
  int _score = 0;
  int _current = 0;
  late List<_TargetRound> _rounds;
  List<int> _selectedIndices = [];
  final Map<int, List<int>> _userAnswers = {}; 
  List<int> _incorrectIndices = [];
  bool _answerSubmitted = false;
  late int _totalRounds;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _applyConfig();
    if (widget.presetRounds != null && widget.presetRounds!.isNotEmpty) {
      _rounds = widget.presetRounds!
          .map((r) => _TargetRound(
                target: int.tryParse(r['target']?.toString() ?? '') ?? 0,
                numbers: (r['numbers'] is List)
                    ? (r['numbers'] as List)
                        .map((e) => int.tryParse(e.toString()) ?? 0)
                        .toList()
                    : <int>[],
                // Teacher-assigned rounds currently store only numbers+target.
                // We intentionally leave solutionIndices empty (game still validates by total == target).
                solutionIndices: const <int>[],
              ))
          .toList();
      _totalRounds = _rounds.length;
    } else {
      _rounds = _generateRounds();
    }
    _startTimer();
  }

  void _applyConfig() {
    final cfg = widget.config ?? {};
    _remainingSeconds = cfg['timeSec'] ?? 300;
    _totalRounds = cfg['rounds'] ?? 10;

    final active = cfg['activeRounds'];
    if (active != null && active is List) {
      _rounds = _generateRounds()
          .asMap()
          .entries
          .where((entry) => active.contains(entry.key))
          .map((e) => e.value)
          .toList();
    } else {
      _rounds = _generateRounds();
    }
  }

  List<_TargetRound> _generateRounds({List<bool>? enabledFlags}) {
    final cfg = widget.config ?? {};
    final min = cfg['min'] ?? 1;
    final max = cfg['max'] ?? 10;

    List<_TargetRound> list = [];
    for (int i = 0; i < _totalRounds; i++) {
      if (enabledFlags != null && i < enabledFlags.length && !enabledFlags[i]) {
        continue;
      }

      int numCount = 4 + _random.nextInt(2);
      List<int> numbers;
      List<int> solution;
      int target;
      List<int> solutionIndices = [];

      switch (widget.operator.toLowerCase()) {
        case 'addition':
        case 'add':
          // Generate solution first
          int solutionCount = 2 + _random.nextInt(numCount - 1);
          solution = List.generate(solutionCount, (_) => min + _random.nextInt(max - min + 1));
          target = solution.fold(0, (a, b) => a + b);
          
          // Add distractors
          numbers = List.from(solution);
          while (numbers.length < numCount) {
            numbers.add(min + _random.nextInt(max - min + 1));
          }
          
          // Find solution indices before shuffling and store values
          List<int> numbersCopy = List.from(numbers);
          List<int> solutionValues = [];
          for (int solNum in solution) {
            int index = numbersCopy.indexOf(solNum);
            if (index != -1) {
              solutionIndices.add(index);
              solutionValues.add(numbers[index]);
              numbersCopy[index] = -1; // Mark as used
            }
          }
          
          // Shuffle and find solution values in new positions
          numbers.shuffle();
          List<int> newSolutionIndices = [];
          List<int> numbersCopy2 = List.from(numbers);
          for (int value in solutionValues) {
            int index = numbersCopy2.indexOf(value);
            if (index != -1) {
              newSolutionIndices.add(index);
              numbersCopy2[index] = -1; // Mark as used
            }
          }
          solutionIndices = newSolutionIndices;
          break;

        case 'subtraction':
        case 'subtract':
          // Generate solution: start with larger number, subtract smaller ones
          int solutionCount = 2 + _random.nextInt(numCount - 1);
          int firstNum = max;
          solution = [firstNum];
          int subtractSum = 0;
          for (int j = 1; j < solutionCount; j++) {
            int subNum = min + _random.nextInt(((firstNum ~/ 2).clamp(1, max - min + 1)).toInt());
            solution.add(subNum);
            subtractSum += subNum;
          }
          target = firstNum - subtractSum;
          if (target < 0) {
            // Recalculate with sorted solution (largest first)
            solution.sort((a, b) => b.compareTo(a));
            subtractSum = solution.sublist(1).fold(0, (a, b) => a + b);
            target = solution[0] - subtractSum;
          }
          
          // Add distractors
          numbers = List.from(solution);
          while (numbers.length < numCount) {
            numbers.add(min + _random.nextInt(((max).clamp(1, max - min + 1)).toInt()));
          }
          
          // Find solution indices before shuffling and store values
          List<int> numbersCopy = List.from(numbers);
          solutionIndices = [];
          List<int> solutionValues = [];
          for (int solNum in solution) {
            int index = numbersCopy.indexOf(solNum);
            if (index != -1) {
              solutionIndices.add(index);
              solutionValues.add(numbers[index]);
              numbersCopy[index] = -1;
            }
          }
          
          // Shuffle and find solution values in new positions
          numbers.shuffle();
          List<int> newSolutionIndices = [];
          List<int> numbersCopy2 = List.from(numbers);
          for (int value in solutionValues) {
            int index = numbersCopy2.indexOf(value);
            if (index != -1) {
              newSolutionIndices.add(index);
              numbersCopy2[index] = -1;
            }
          }
          solutionIndices = newSolutionIndices;
          break;

        case 'multiplication':
        case 'multiply':
          // Generate solution first
          int solutionCount = 2 + _random.nextInt(numCount - 1);
          solution = List.generate(solutionCount, (_) => min + _random.nextInt(max - min + 1));
          target = solution.fold(1, (a, b) => a * b);
          
          // Add distractors
          numbers = List.from(solution);
          while (numbers.length < numCount) {
            numbers.add(min + _random.nextInt(max - min + 1));
          }
          
          // Find solution indices before shuffling and store values
          List<int> numbersCopy = List.from(numbers);
          solutionIndices = [];
          List<int> solutionValues = [];
          for (int solNum in solution) {
            int index = numbersCopy.indexOf(solNum);
            if (index != -1) {
              solutionIndices.add(index);
              solutionValues.add(numbers[index]);
              numbersCopy[index] = -1;
            }
          }
          
          // Shuffle and find solution values in new positions
          numbers.shuffle();
          List<int> newSolutionIndices = [];
          List<int> numbersCopy2 = List.from(numbers);
          for (int value in solutionValues) {
            int index = numbersCopy2.indexOf(value);
            if (index != -1) {
              newSolutionIndices.add(index);
              numbersCopy2[index] = -1;
            }
          }
          solutionIndices = newSolutionIndices;
          break;

        case 'division':
        case 'divide':
          // Generate solution first: ensure valid division
          int solutionCount = 2 + _random.nextInt(numCount - 1);
          if (solutionCount < 2) solutionCount = 2;
          
          // Generate divisor first (product of divisors)
          int divisor = min;
          List<int> divisorParts = [];
          for (int j = 0; j < solutionCount - 1; j++) {
            int part = min + _random.nextInt((max - min + 1));
            if (part < 1) part = 1;
            divisorParts.add(part);
          }
          divisor = divisorParts.fold(1, (a, b) => a * b);
          if (divisor < 1) divisor = 1;
          
          // Generate dividend that is divisible by divisor
          int quotient = min + _random.nextInt((max - min + 1).clamp(1, 10));
          int dividend = divisor * quotient;
          
          // Ensure dividend is within reasonable range
          while (dividend > max * 3) {
            quotient = min + _random.nextInt(5);
            dividend = divisor * quotient;
          }
          
          solution = [dividend, ...divisorParts];
          target = quotient;
          
          // Add distractors
          numbers = List.from(solution);
          while (numbers.length < numCount) {
            numbers.add(min + _random.nextInt(max - min + 1));
          }
          
          // Find solution indices before shuffling and store values
          List<int> numbersCopy = List.from(numbers);
          solutionIndices = [];
          List<int> solutionValues = [];
          for (int solNum in solution) {
            int index = numbersCopy.indexOf(solNum);
            if (index != -1) {
              solutionIndices.add(index);
              solutionValues.add(numbers[index]);
              numbersCopy[index] = -1;
            }
          }
          
          // Shuffle and find solution values in new positions
          numbers.shuffle();
          List<int> newSolutionIndices = [];
          List<int> numbersCopy2 = List.from(numbers);
          for (int value in solutionValues) {
            int index = numbersCopy2.indexOf(value);
            if (index != -1) {
              newSolutionIndices.add(index);
              numbersCopy2[index] = -1;
            }
          }
          solutionIndices = newSolutionIndices;
          break;

        default:
          // Default to addition logic
          int solutionCount = 2 + _random.nextInt(numCount - 1);
          solution = List.generate(solutionCount, (_) => min + _random.nextInt(max - min + 1));
          target = solution.fold(0, (a, b) => a + b);
          
          numbers = List.from(solution);
          while (numbers.length < numCount) {
            numbers.add(min + _random.nextInt(max - min + 1));
          }
          
          List<int> numbersCopy = List.from(numbers);
          solutionIndices = [];
          List<int> solutionValues = [];
          for (int solNum in solution) {
            int index = numbersCopy.indexOf(solNum);
            if (index != -1) {
              solutionIndices.add(index);
              solutionValues.add(numbers[index]);
              numbersCopy[index] = -1;
            }
          }
          
          // Shuffle and find solution values in new positions
          numbers.shuffle();
          List<int> newSolutionIndices = [];
          List<int> numbersCopy2 = List.from(numbers);
          for (int value in solutionValues) {
            int index = numbersCopy2.indexOf(value);
            if (index != -1) {
              newSolutionIndices.add(index);
              numbersCopy2[index] = -1;
            }
          }
          solutionIndices = newSolutionIndices;
      }
      
      // Ensure we have valid solution indices
      if (solutionIndices.isEmpty) {
        // Fallback: use first numbers as solution
        solutionIndices = List.generate(solution.length.clamp(0, numbers.length), (i) => i);
      }
      
      list.add(_TargetRound(target: target, numbers: numbers, solutionIndices: solutionIndices));
    }
    return list;
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _finishGame();
      }
    });
  }

  void _finishGame() {
    if (_timer.isActive) _timer.cancel();
        if (!_answerSubmitted && _current < _rounds.length) {
      final round = _rounds[_current];
      int result = _calculateCurrentResult();
      final isCorrect = result == round.target;
      
      _userAnswers[_current] = List.from(_selectedIndices);
      if (isCorrect) _score++;
    }
    
    setState(() {
      _gameFinished = true;
    });

    final elapsed = (widget.config?['timeSec'] ?? 300) - _remainingSeconds;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _score == _totalRounds ? Icons.celebration : Icons.emoji_events,
              color: _score == _totalRounds ? Colors.amber : Colors.blue,
              size: 32,
            ),
            const SizedBox(width: 8),
            const Text('Game Over!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your score: $_score / $_totalRounds',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Percentage: ${(_score / _totalRounds * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Time left: ${_formatTime(_remainingSeconds)}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _showReview = true;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: GameTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: GameTheme.primary),
              ),
              child: const Text(
                'Review Answers',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, {
                'score': _score,
                'elapsed': elapsed,
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: GameTheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Done',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
      ),
    );
  }

  String _formatTime(int seconds) {
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    if (_timer.isActive) _timer.cancel();
    super.dispose();
  }

  void _toggleSelect(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  String _getOperatorSymbol() {
    switch (widget.operator.toLowerCase()) {
      case 'addition':
      case 'add':
        return '+';
      case 'subtraction':
      case 'subtract':
        return '-';
      case 'multiplication':
      case 'multiply':
        return '×';
      case 'division':
      case 'divide':
        return '÷';
      default:
        return '+';
    }
  }

  String _buildCurrentEquation() {
    if (_selectedIndices.isEmpty) {
      return 'No numbers selected';
    }

    final round = _rounds[_current];
    final selectedNumbers = _selectedIndices.map((i) => round.numbers[i]).toList();
    final operator = _getOperatorSymbol();

    return selectedNumbers.join(' $operator ');
  }

  int _calculateCurrentResult() {
    if (_selectedIndices.isEmpty) return 0;

    final round = _rounds[_current];
    final selectedNumbers = _selectedIndices.map((i) => round.numbers[i]).toList();

    switch (widget.operator.toLowerCase()) {
      case 'addition':
      case 'add':
        return selectedNumbers.fold(0, (a, b) => a + b);
      case 'subtraction':
      case 'subtract':
        return selectedNumbers.length > 1
            ? selectedNumbers[0] - selectedNumbers.sublist(1).fold(0, (a, b) => a + b)
            : selectedNumbers[0];
      case 'multiplication':
      case 'multiply':
        return selectedNumbers.fold(1, (a, b) => a * b);
      case 'division':
      case 'divide':
        return selectedNumbers.length > 1
            ? (selectedNumbers[0] / selectedNumbers.sublist(1).fold(1, (a, b) => a * b)).round()
            : selectedNumbers[0];
      default:
        return selectedNumbers.fold(0, (a, b) => a + b);
    }
  }

  void _submit() {
    if (_answerSubmitted) return;
    
    final round = _rounds[_current];
    int result = _calculateCurrentResult();
    final isCorrect = result == round.target;
    _userAnswers[_current] = List.from(_selectedIndices);
        setState(() {
      _answerSubmitted = true;
      _incorrectIndices.clear();
      // Only compute incorrect index highlighting if we have a known solution.
      if (!isCorrect && round.solutionIndices.isNotEmpty) {
        for (int index in _selectedIndices) {
          if (!round.solutionIndices.contains(index)) {
            _incorrectIndices.add(index);
          }
        }
        for (int index in round.solutionIndices) {
          if (!_selectedIndices.contains(index)) {
            _incorrectIndices.add(index);
          }
        }
      }
    });
    
    if (isCorrect) _score++;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: isCorrect ? GameTheme.correct : GameTheme.wrong,
        title: Icon(
          isCorrect ? Icons.check_circle : Icons.cancel,
          color: Colors.white,
          size: 64,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isCorrect 
                  ? 'Correct! 🎉\n$result = ${round.target}' 
                  : 'Wrong! ❌\n$result ≠ ${round.target}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (!isCorrect) ...[
              const SizedBox(height: 12),
              Text(
                round.solutionIndices.isEmpty
                    ? 'Correct total: ${round.target}'
                    : 'Correct answer: ${round.solutionIndices.map((i) => round.numbers[i]).join(_getOperatorSymbol() + ' ')} = ${round.target}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _moveToNextRound();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _current < _rounds.length - 1 ? 'Continue' : 'Finish',
                style: TextStyle(
                  color: isCorrect ? GameTheme.correct : GameTheme.wrong,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
      ),
    );
  }

  void _moveToNextRound() {
    if (_current < _rounds.length - 1) {
      setState(() {
        _current++;
        _selectedIndices.clear();
        _incorrectIndices.clear();
        _answerSubmitted = false;
      });
    } else {
      _finishGame();
    }
  }

  int _calculateResultForIndices(List<int> indices, List<int> numbers) {
    if (indices.isEmpty) return 0;
    final selectedNumbers = indices.map((i) => numbers[i]).toList();
    
    switch (widget.operator.toLowerCase()) {
      case 'addition':
      case 'add':
        return selectedNumbers.fold(0, (a, b) => a + b);
      case 'subtraction':
      case 'subtract':
        return selectedNumbers.length > 1
            ? selectedNumbers[0] - selectedNumbers.sublist(1).fold(0, (a, b) => a + b)
            : selectedNumbers[0];
      case 'multiplication':
      case 'multiply':
        return selectedNumbers.fold(1, (a, b) => a * b);
      case 'division':
      case 'divide':
        return selectedNumbers.length > 1
            ? (selectedNumbers[0] / selectedNumbers.sublist(1).fold(1, (a, b) => a * b)).round()
            : selectedNumbers[0];
      default:
        return selectedNumbers.fold(0, (a, b) => a + b);
    }
  }

  Widget _buildReviewScreen() {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ninja Math Review (${widget.difficulty})'),
        backgroundColor: GameTheme.primary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: GameTheme.primary.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Game Results',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Score: $_score / $_totalRounds',
                    style: const TextStyle(fontSize: 18),
                  ),
                  Text(
                    'Percentage: ${(_score / _totalRounds * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ..._rounds.asMap().entries.map((entry) {
            final index = entry.key;
            final round = entry.value;
            final userAnswer = _userAnswers[index] ?? [];
            final isCorrect = round.solutionIndices.length == userAnswer.length &&
                round.solutionIndices.every((i) => userAnswer.contains(i));
            final userResult = _calculateResultForIndices(userAnswer, round.numbers);
            final correctResult = _calculateResultForIndices(round.solutionIndices, round.numbers);

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isCorrect ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Round ${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isCorrect ? Icons.check_circle : Icons.cancel,
                          color: isCorrect ? Colors.green : Colors.red,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: GameTheme.accent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Target: ${round.target}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Available Numbers:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: round.numbers.asMap().entries.map((entry) {
                        final numIndex = entry.key;
                        final number = entry.value;
                        final isCorrectNumber = round.solutionIndices.contains(numIndex);
                        final isUserSelected = userAnswer.contains(numIndex);
                        final isWrongSelection = isUserSelected && !isCorrectNumber;

                        Color backgroundColor = GameTheme.tileBank;
                        Color borderColor = Colors.grey;
                        double borderWidth = 1;

                        if (isCorrectNumber) {
                          backgroundColor = Colors.green[100]!;
                          borderColor = Colors.green;
                          borderWidth = 2;
                        }
                        if (isWrongSelection) {
                          backgroundColor = Colors.red[100]!;
                          borderColor = Colors.red;
                          borderWidth = 2;
                        }

                        return Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: borderColor, width: borderWidth),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$number',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    if (!isCorrect) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.info_outline, color: Colors.red),
                                const SizedBox(width: 8),
                                Text(
                                  'Your Answer: ${userAnswer.isEmpty ? "Not answered" : userResult}',
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Correct Answer: ${round.solutionIndices.map((i) => round.numbers[i]).join(_getOperatorSymbol() + ' ')} = $correctResult',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, {
                'score': _score,
                'elapsed': (widget.config?['timeSec'] ?? 300) - _remainingSeconds,
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: GameTheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text(
              'Done',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showReview) {
      return _buildReviewScreen();
    }
    if (_gameFinished) return const SizedBox.shrink();
    final round = _rounds[_current];
    final currentEquation = _buildCurrentEquation();
    final currentResult = _calculateCurrentResult();

    return WillPopScope(
      onWillPop: () async {
        final elapsed = (widget.config?['timeSec'] ?? 300) - _remainingSeconds;
        Navigator.pop(context, {
          'score': _score,
          'elapsed': elapsed,
        });
        return false;
      },
      child: Scaffold(
        backgroundColor: GameTheme.background,
        appBar: AppBar(
          title: Text(
            'Ninja Math (${widget.difficulty})${widget.isAssigned ? ' • Assigned' : ''}',
            style: GameTheme.tileText,
          ),
          backgroundColor: GameTheme.primary,
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  const Icon(Icons.timer, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(_remainingSeconds),
                    style: GameTheme.tileText.copyWith(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildMascot(),
              const SizedBox(height: 12),
              _buildTarget(round.target),
              const SizedBox(height: 16),
              Text(
                _selectedIndices.isNotEmpty
                    ? '$currentEquation = $currentResult'
                    : 'No numbers selected',
                style: GameTheme.tileText,
              ),
              const SizedBox(height: 32),
              _buildNumberBank(round.numbers),
              const SizedBox(height: 32),
              GameButton(
                text: _answerSubmitted ? 'Submitted' : 'Submit',
                onTap: (!_answerSubmitted && _selectedIndices.isNotEmpty) ? _submit : () {},
                color: (!_answerSubmitted && _selectedIndices.isNotEmpty)
                    ? GameTheme.primary
                    : GameTheme.tile,
              ),
              if (_answerSubmitted) ...[
                const SizedBox(height: 8),
                Text(
                  'Tap "Continue" in the dialog to proceed',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMascot() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          backgroundColor: GameTheme.mascot,
          radius: 28,
          child:
          const Icon(Icons.sports_martial_arts, color: Colors.white, size: 36),
        ),
        const SizedBox(width: 12),
        Text('Be a Math Ninja!', style: GameTheme.mascotText),
      ],
    );
  }

  Widget _buildTarget(int target) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        color: GameTheme.accent,
        borderRadius: BorderRadius.circular(GameTheme.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        'Target: $target',
        style: GameTheme.bigNumber.copyWith(color: Colors.white),
      ),
    );
  }

  Widget _buildNumberBank(List<int> numbers) {
    final round = _rounds[_current];
    
    return Wrap(
      spacing: 16,
      children: List.generate(numbers.length, (index) {
        final n = numbers[index];
        final isSelected = _selectedIndices.contains(index);
        final isCorrectNumber = round.solutionIndices.contains(index);
        final isIncorrect = _incorrectIndices.contains(index);
        
        Color backgroundColor;
        Color borderColor;
        double borderWidth = 2;
        
        if (isIncorrect) {
          backgroundColor = Colors.red[100]!;
          borderColor = Colors.red;
        } else if (isSelected && isCorrectNumber) {
          backgroundColor = _incorrectIndices.isEmpty ? GameTheme.correct : Colors.green[100]!;
          borderColor = Colors.green;
        } else if (isSelected) {
          backgroundColor = GameTheme.correct;
          borderColor = GameTheme.primary;
        } else if (_incorrectIndices.isNotEmpty && isCorrectNumber) {
          backgroundColor = Colors.green[50]!;
          borderColor = Colors.green;
          borderWidth = 2;
        } else {
          backgroundColor = GameTheme.tileBank;
          borderColor = GameTheme.primary;
        }

        return GestureDetector(
          onTap: () {
            if (!_answerSubmitted) {
              _toggleSelect(index);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 70,
            height: 70,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(GameTheme.borderRadius),
              border: Border.all(color: borderColor, width: borderWidth),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  '$n',
                  style: GameTheme.tileText.copyWith(color: Colors.black),
                ),
                if (isIncorrect && isSelected)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                if (_incorrectIndices.isNotEmpty && isCorrectNumber && !isSelected)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _TargetRound {
  final int target;
  final List<int> numbers;
  final List<int> solutionIndices;
  _TargetRound({
    required this.target,
    required this.numbers,
    required this.solutionIndices,
  });
}
