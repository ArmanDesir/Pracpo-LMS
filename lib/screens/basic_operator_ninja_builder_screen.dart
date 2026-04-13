import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:pracpro/modules/basic_operators/addition/game_theme.dart';
import 'package:pracpro/modules/basic_operators/addition/widgets/game_button.dart';

class BasicOperatorNinjaBuilderScreen extends StatefulWidget {
  final String operator;
  final Map<String, dynamic> config;
  final String difficulty;
  final String title;
  final String? description;

  const BasicOperatorNinjaBuilderScreen({
    super.key,
    required this.operator,
    required this.config,
    required this.difficulty,
    required this.title,
    this.description,
  });

  @override
  State<BasicOperatorNinjaBuilderScreen> createState() =>
      _BasicOperatorNinjaBuilderScreenState();
}

class _BasicOperatorNinjaBuilderScreenState
    extends State<BasicOperatorNinjaBuilderScreen> {
  late int _totalRounds;
  late int _min;
  late int _max;
  late List<_PreviewRound> _rounds;
  final Random _random = Random();

  late List<TextEditingController> _controllers;
  late List<ValidationState> _validationStates;

  @override
  void initState() {
    super.initState();
    _applyConfig();
    _rounds = _generateValidRounds();
    _controllers = List.generate(
        _rounds.length,
            (i) => TextEditingController(text: _rounds[i].target.toString()));
    _validationStates =
        List.generate(_rounds.length, (_) => ValidationState.unchecked);
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _applyConfig() {
    _totalRounds = widget.config['rounds'] ?? 10;
    _min = widget.config['min'] ?? 1;
    _max = widget.config['max'] ?? 10;
  }

  List<_PreviewRound> _generateValidRounds() {
    List<_PreviewRound> list = [];
    for (int i = 0; i < _totalRounds; i++) {
      _PreviewRound? round;
      for (int attempt = 0; attempt < 50; attempt++) {
        final candidate = _generateCandidateRound();
        if (_hasAtLeastOneSolution(candidate.numbers, candidate.target)) {
          round = candidate;
          break;
        }
      }
      list.add(round ?? _fallbackRound());
    }
    return list;
  }

<<<<<<< HEAD
  _PreviewRound _generateRoundWithTarget(int target) {
    int numCount = 4 + _random.nextInt(2);
    List<int> numbers = [];
    int finalTarget = target;
=======
  _PreviewRound _generateCandidateRound() {
    int numCount = 4 + _random.nextInt(2);
    List<int> numbers;
    int target;
>>>>>>> Fixes-test

    switch (widget.operator.toLowerCase()) {
      case 'addition':
      case 'add':
<<<<<<< HEAD
        {
          int solutionCount = 2 + _random.nextInt(numCount - 1);
          int remaining = target;

          // generate exact solution numbers
          for (int i = 0; i < solutionCount - 1; i++) {
            int remainingSlots = solutionCount - i - 1;

            int maxAllowed = remaining - (_min * remainingSlots);

            int upperBound = maxAllowed > _max ? _max : maxAllowed;

            int num = _min + _random.nextInt(
              (upperBound - _min + 1).clamp(1, 999),
            );

            numbers.add(num);
            remaining -= num;
          }

          // final number guarantees exact target
          numbers.add(remaining);

          // add distractors
          while (numbers.length < numCount) {
            numbers.add(
              _min + _random.nextInt(_max - _min + 1),
            );
          }

          numbers.shuffle();
          break;
        }

      case 'subtraction':
      case 'subtract':
        {
          int firstNum = target + (_min + _random.nextInt(_max));
          int subtractor = firstNum - target;

          numbers = [firstNum, subtractor];

          while (numbers.length < numCount) {
            numbers.add(
              _min + _random.nextInt(_max - _min + 1),
            );
          }

          numbers.shuffle();
          break;
        }

      case 'multiplication':
      case 'multiply':
        {
          numbers = [];
          int factor1 = 1;
          int factor2 = target;

          for (int i = 2; i <= target; i++) {
            if (target % i == 0) {
              factor1 = i;
              factor2 = target ~/ i;
              break;
            }
          }

          numbers.add(factor1);
          numbers.add(factor2);

          while (numbers.length < numCount) {
            numbers.add(
              _min + _random.nextInt(_max - _min + 1),
            );
          }

          numbers.shuffle();
          break;
        }

      case 'division':
      case 'divide':
        {
          int divisor = _min + _random.nextInt(_max);
          int dividend = target * divisor;

          numbers = [dividend, divisor];

          while (numbers.length < numCount) {
            numbers.add(
              _min + _random.nextInt(_max - _min + 1),
            );
          }

          numbers.shuffle();
          break;
        }

      default:
        {
          numbers = [target];

          while (numbers.length < numCount) {
            numbers.add(
              _min + _random.nextInt(_max - _min + 1),
            );
          }

          numbers.shuffle();
        }
    }

    return _PreviewRound(
      target: finalTarget,
      numbers: numbers,
    );
=======
        numbers =
            List.generate(numCount, (_) => _min + _random.nextInt(_max - _min + 1));
        numbers.shuffle();
        int solutionCount = 2 + _random.nextInt(numCount - 1);
        List<int> solution = numbers.sublist(0, solutionCount);
        target = solution.fold(0, (a, b) => a + b);
        break;

      case 'subtraction':
      case 'subtract':
        numbers = List.generate(
            numCount, (_) => _min + _random.nextInt(_max - _min + 1));
        numbers.shuffle();
        int solutionCount = 2 + _random.nextInt(numCount - 1);
        List<int> solution = List<int>.from(numbers.sublist(0, solutionCount))
          ..sort((a, b) => b.compareTo(a));
        target = solution[0] - solution.sublist(1).fold(0, (a, b) => a + b);
        if (target < 0) target = 0;
        break;

      case 'multiplication':
      case 'multiply':
        numbers =
            List.generate(numCount, (_) => _min + _random.nextInt(_max - _min + 1));
        numbers.shuffle();
        int solutionCount = 2 + _random.nextInt(numCount - 1);
        List<int> solution = numbers.sublist(0, solutionCount);
        target = solution.fold(1, (a, b) => a * b);
        break;

      case 'division':
      case 'divide':
        final divisorCount = 1 + _random.nextInt(2);
        final divisors = List.generate(
          divisorCount,
          (_) => (_min + _random.nextInt(_max - _min + 1)).clamp(1, _max),
        );
        final quotient = (_min + _random.nextInt((_max ~/ 2).clamp(2, _max))).clamp(1, _max);
        final dividend = divisors.fold<int>(quotient, (a, b) => a * b);

        numbers = [dividend, ...divisors];
        while (numbers.length < numCount) {
          numbers.add(_min + _random.nextInt(_max - _min + 1));
        }
        numbers.shuffle();
        target = quotient;
        break;

      default:
        numbers =
            List.generate(numCount, (_) => _min + _random.nextInt(_max - _min + 1));
        numbers.shuffle();
        int solutionCount = 2 + _random.nextInt(numCount - 1);
        List<int> solution = numbers.sublist(0, solutionCount);
        target = solution.fold(0, (a, b) => a + b);
    }

    return _PreviewRound(target: target, numbers: numbers);
  }

  _PreviewRound _fallbackRound() {
    final numbers = [
      _min,
      (_min + 1).clamp(_min, _max),
      (_min + 2).clamp(_min, _max),
      (_min + 3).clamp(_min, _max),
      (_min + 4).clamp(_min, _max),
    ];
    switch (widget.operator.toLowerCase()) {
      case 'subtraction':
      case 'subtract':
        final sorted = List<int>.from(numbers)..sort((a, b) => b.compareTo(a));
        return _PreviewRound(
          numbers: numbers,
          target: sorted[0] - sorted.sublist(1).fold(0, (a, b) => a + b),
        );
      case 'multiplication':
      case 'multiply':
        return _PreviewRound(numbers: numbers, target: numbers[0] * numbers[1]);
      case 'division':
      case 'divide':
        return _PreviewRound(numbers: [12, 3, 2, numbers[3], numbers[4]], target: 2);
      case 'addition':
      case 'add':
      default:
        return _PreviewRound(numbers: numbers, target: numbers[0] + numbers[1]);
    }
  }

  _PreviewRound _generateRoundWithTarget(int target) {
    for (int attempt = 0; attempt < 500; attempt++) {
      final numCount = 4 + _random.nextInt(2);
      final numbers = _generateRandomNumbers(numCount);
      if (_hasAtLeastOneSolution(numbers, target)) {
        return _PreviewRound(target: target, numbers: numbers);
      }
    }
    // Keep requested target, but caller must verify solvability.
    return _PreviewRound(target: target, numbers: _generateRandomNumbers(5));
  }

  List<int> _generateRandomNumbers(int count) {
    return List.generate(count, (_) => _min + _random.nextInt(_max - _min + 1));
  }

  bool _hasAtLeastOneSolution(List<int> numbers, int target) {
    final count = numbers.length;
    if (count == 0) return false;

    final op = widget.operator.toLowerCase();
    for (int mask = 1; mask < (1 << count); mask++) {
      final selected = <int>[];
      for (int i = 0; i < count; i++) {
        if ((mask & (1 << i)) != 0) {
          selected.add(numbers[i]);
        }
      }
      if (selected.length < 2) continue;
      if (_subsetMatchesTarget(selected, target, op)) {
        return true;
      }
    }
    return false;
  }

  bool _subsetMatchesTarget(List<int> selected, int target, String op) {
    switch (op) {
      case 'addition':
      case 'add':
        return selected.fold<int>(0, (a, b) => a + b) == target;
      case 'multiplication':
      case 'multiply':
        return selected.fold<int>(1, (a, b) => a * b) == target;
      case 'subtraction':
      case 'subtract':
        return _hasPermutationMatch(selected, target, (perm) {
          if (perm.isEmpty) return false;
          final result = perm[0] - perm.sublist(1).fold<int>(0, (a, b) => a + b);
          return result == target;
        });
      case 'division':
      case 'divide':
        return _hasPermutationMatch(selected, target, (perm) {
          if (perm.isEmpty) return false;
          final divisor = perm.sublist(1).fold<int>(1, (a, b) => a * b);
          if (divisor == 0) return false;
          if (perm[0] % divisor != 0) return false;
          return (perm[0] ~/ divisor) == target;
        });
      default:
        return selected.fold<int>(0, (a, b) => a + b) == target;
    }
  }

  bool _hasPermutationMatch(List<int> values, int target, bool Function(List<int>) tester) {
    final used = List<bool>.filled(values.length, false);
    final current = <int>[];
    bool found = false;

    void backtrack() {
      if (found) return;
      if (current.length == values.length) {
        if (tester(current)) found = true;
        return;
      }
      for (int i = 0; i < values.length; i++) {
        if (used[i]) continue;
        used[i] = true;
        current.add(values[i]);
        backtrack();
        current.removeLast();
        used[i] = false;
        if (found) return;
      }
    }

    backtrack();
    return found;
>>>>>>> Fixes-test
  }

  String _getValidRangeText() {
    switch (widget.operator.toLowerCase()) {
      case 'addition':
      case 'add':
        return 'Valid range: ${_min * 2}–${_max * 5}';
      case 'subtraction':
      case 'subtract':
        return 'Valid range: 0–$_max';
      case 'multiplication':
      case 'multiply':
        return 'Valid range: ${_min * _min}–${_max * _max * 2}';
      case 'division':
      case 'divide':
        return 'Valid range: 1–${_max * 2}';
      default:
        return 'Valid range: ${_min * 2}–${_max * 5}';
    }
  }

  bool _isTargetValid(int value) {
    // Operator-specific validation ranges (rough estimates)
    switch (widget.operator.toLowerCase()) {
      case 'addition':
      case 'add':
        return value >= _min * 2 && value <= _max * 5;
      case 'subtraction':
      case 'subtract':
        // For subtraction, target can be from 0 to max
        return value >= 0 && value <= _max;
      case 'multiplication':
      case 'multiply':
        // For multiplication, target can be from min*min to max*max
        return value >= _min * _min && value <= _max * _max * 2;
      case 'division':
      case 'divide':
        // For division, target is typically from 1 to max
        return value >= 1 && value <= _max * 2;
      default:
        return value >= _min * 2 && value <= _max * 5;
    }
  }

  void _applyNewTarget(int index) {
    final value = _controllers[index].text.trim();
    final newTarget = int.tryParse(value);
    if (newTarget == null) {
      _showSnack('⚠️ Please enter a valid number.');
      setState(() => _validationStates[index] = ValidationState.invalid);
      return;
    }

    if (!_isTargetValid(newTarget)) {
      String rangeText;
      switch (widget.operator.toLowerCase()) {
        case 'addition':
        case 'add':
          rangeText = '${_min * 2} and ${_max * 5}';
          break;
        case 'subtraction':
        case 'subtract':
          rangeText = '0 and $_max';
          break;
        case 'multiplication':
        case 'multiply':
          rangeText = '${_min * _min} and ${_max * _max * 2}';
          break;
        case 'division':
        case 'divide':
          rangeText = '1 and ${_max * 2}';
          break;
        default:
          rangeText = '${_min * 2} and ${_max * 5}';
      }
      _showSnack('⚠️ Target must be between $rangeText (range $_min–$_max).');
      setState(() => _validationStates[index] = ValidationState.invalid);
      return;
    }

    final generated = _generateRoundWithTarget(newTarget);
    final isSolvableForTarget =
        generated.target == newTarget &&
            _hasAtLeastOneSolution(generated.numbers, newTarget);

    if (!isSolvableForTarget) {
      _showSnack(
        '⚠️ Could not build a solvable round for target $newTarget with current range ($_min-$_max).',
      );
      setState(() => _validationStates[index] = ValidationState.invalid);
      return;
    }

    setState(() {
      _rounds[index] = generated;
      _controllers[index].text = newTarget.toString();
      _validationStates[index] = ValidationState.valid;
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _randomizeRounds() {
    setState(() {
      _rounds = _generateValidRounds();
      for (int i = 0; i < _rounds.length; i++) {
        _controllers[i].text = _rounds[i].target.toString();
        _validationStates[i] = ValidationState.unchecked;
      }
    });
  }

  void _validateAllRounds() {
    int validCount = 0;
    setState(() {
      for (int i = 0; i < _rounds.length; i++) {
        final target = int.tryParse(_controllers[i].text.trim());
        if (target == null || !_isTargetValid(target)) {
          _validationStates[i] = ValidationState.invalid;
          continue;
        }
        final isValid = _hasAtLeastOneSolution(_rounds[i].numbers, target);
        _validationStates[i] =
            isValid ? ValidationState.valid : ValidationState.invalid;
        if (isValid) validCount++;
      }
    });

    final invalidCount = _rounds.length - validCount;
    if (invalidCount == 0) {
      _showSnack('✅ All rounds are solvable.');
    } else {
      _showSnack('⚠️ $invalidCount round(s) are not solvable. Please edit and re-validate.');
    }
  }

  bool get _allValid =>
      _validationStates.every((state) => state == ValidationState.valid);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameTheme.background,
      appBar: AppBar(
        backgroundColor: GameTheme.primary,
        title: Text('Preview: ${widget.title} (${widget.difficulty})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shuffle),
            onPressed: _randomizeRounds,
            tooltip: 'Randomize All Rounds',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _rounds.length,
                itemBuilder: (context, index) =>
                    _buildRoundCard(index, _rounds[index]),
              ),
            ),
            const SizedBox(height: 24),
            GameButton(
              text: 'Validate All Rounds',
              color: Colors.blueAccent,
              onTap: _validateAllRounds,
            ),
            const SizedBox(height: 12),
            GameButton(
              text: 'Looks Good!',
              color: _allValid ? GameTheme.primary : Colors.grey,
              onTap: _allValid
                  ? () {
                Navigator.pop(
                  context,
                  _rounds
                      .map((r) => {
                    'numbers': r.numbers,
                    'target': r.target,
                  })
                      .toList(),
                );
              }
                  : () => _showSnack(
                  '⚠️ Please validate all totals (turn all buttons green).'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      color: GameTheme.accent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title,
                style: GameTheme.tileText.copyWith(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (widget.description != null)
              Text(widget.description!,
                  style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Text('Difficulty: ${widget.difficulty}',
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 4),
            Text('Rounds: $_totalRounds | Range: $_min - $_max',
                style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundCard(int index, _PreviewRound round) {
    bool isApplying = false;

    return StatefulBuilder(
      builder: (context, setInner) {
        Color iconColor;
        switch (_validationStates[index]) {
          case ValidationState.valid:
            iconColor = Colors.green;
            break;
          case ValidationState.invalid:
            iconColor = Colors.red;
            break;
          default:
            iconColor = Colors.blue;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Round ${index + 1}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple)),
                    Row(
                      children: [
                        SizedBox(
                          width: 80,
                          height: 36,
                          child: TextField(
                            controller: _controllers[index],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            onTap: () => setState(() =>
                            _validationStates[index] =
                                ValidationState.unchecked),
                            decoration: const InputDecoration(
                              labelText: 'Total',
                              labelStyle: TextStyle(fontSize: 12),
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: isApplying
                              ? const SizedBox(
                            height: 16,
                            width: 16,
                            child:
                            CircularProgressIndicator(strokeWidth: 2),
                          )
                              : Icon(Icons.check_circle, color: iconColor),
                          tooltip: 'Apply',
                          onPressed: isApplying
                              ? null
                              : () async {
                            setInner(() => isApplying = true);
                            await Future.delayed(
                                const Duration(milliseconds: 250));
                            _applyNewTarget(index);
                            setInner(() => isApplying = false);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _getValidRangeText(),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: round.numbers
                      .map(
                        (n) => Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$n',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  )
                      .toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

enum ValidationState { unchecked, valid, invalid }

class _PreviewRound {
  final int target;
  final List<int> numbers;
  _PreviewRound({required this.target, required this.numbers});
}
