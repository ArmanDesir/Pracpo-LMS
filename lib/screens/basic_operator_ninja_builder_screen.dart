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
      int numCount = 4 + _random.nextInt(2);
      List<int> numbers;
      int target;

      switch (widget.operator.toLowerCase()) {
        case 'addition':
        case 'add':
          numbers = List.generate(numCount, (_) => _min + _random.nextInt(_max - _min + 1));
          numbers.shuffle();
          int solutionCount = 2 + _random.nextInt(numCount - 1);
          List<int> solution = numbers.sublist(0, solutionCount);
          target = solution.fold(0, (a, b) => a + b);
          break;

        case 'subtraction':
        case 'subtract':
          int startNum = _max;
          numbers = [startNum];
          for (int j = 0; j < numCount - 1; j++) {
            numbers.add(_min + _random.nextInt(((startNum ~/ 2).clamp(1, _max - _min + 1)).toInt()));
          }
          numbers.shuffle();
          int solutionCount = 2 + _random.nextInt(numCount - 1);
          List<int> solution = numbers.sublist(0, solutionCount);
          if (solution.length > 1) {
            target = solution[0] - solution.sublist(1).fold(0, (a, b) => a + b);
            if (target < 0) {
              solution.sort((a, b) => b.compareTo(a));
              target = solution[0] - solution.sublist(1).fold(0, (a, b) => a + b);
            }
          } else {
            target = solution[0];
          }
          break;

        case 'multiplication':
        case 'multiply':
          numbers = List.generate(numCount, (_) => _min + _random.nextInt(_max - _min + 1));
          numbers.shuffle();
          int solutionCount = 2 + _random.nextInt(numCount - 1);
          List<int> solution = numbers.sublist(0, solutionCount);
          target = solution.fold(1, (a, b) => a * b);
          break;

        case 'division':
        case 'divide':
          int dividend = ((_min * 2 + _random.nextInt((_max * 2) - (_min * 2) + 1)).clamp(_min * 2, _max * 3)).toInt();
          numbers = [dividend];
          
          List<int> divisors = [];
          for (int j = 0; j < numCount - 1; j++) {
            if (j < 2) {
              int possibleDivisor = _min + _random.nextInt(((dividend ~/ 2).clamp(1, _max - _min + 1)).toInt());
              if (dividend % possibleDivisor == 0 && possibleDivisor > 1) {
                divisors.add(possibleDivisor);
                numbers.add(possibleDivisor);
              } else {
                numbers.add(_min + _random.nextInt(_max - _min + 1));
              }
            } else {
              numbers.add(_min + _random.nextInt(_max - _min + 1));
            }
          }
          
          numbers.shuffle();

          int solutionCount = 2 + _random.nextInt(numCount - 1);
          List<int> solution = numbers.sublist(0, solutionCount);
          if (solution.length > 1) {
            int divisor = solution.sublist(1).fold(1, (a, b) => a * b);
            if (divisor > 0 && solution[0] % divisor == 0) {
              target = solution[0] ~/ divisor;
            } else {
              solution[0] = (divisor * (_min + _random.nextInt(5))).toInt();
              target = solution[0] ~/ divisor;
            }
          } else {
            target = solution[0];
          }
          break;

        default:
          numbers = List.generate(numCount, (_) => _min + _random.nextInt(_max - _min + 1));
          numbers.shuffle();
          int solutionCount = 2 + _random.nextInt(numCount - 1);
          List<int> solution = numbers.sublist(0, solutionCount);
          target = solution.fold(0, (a, b) => a + b);
      }

      list.add(_PreviewRound(target: target, numbers: numbers));
    }
    return list;
  }

  _PreviewRound _generateRoundWithTarget(int target) {
    // For custom target editing, generate a round that can achieve the target
    // using the operator-specific logic
    int numCount = 4 + _random.nextInt(2);
    List<int> numbers;
    int finalTarget = target;

    switch (widget.operator.toLowerCase()) {
      case 'addition':
      case 'add':
        // For addition, generate numbers that can sum to target
        int solutionCount = 2 + _random.nextInt(numCount - 1);
        numbers = [];
        int remaining = target;
        for (int i = 0; i < solutionCount - 1; i++) {
          int num = _min + _random.nextInt((remaining - _min * (solutionCount - i - 1)).clamp(1, _max - _min + 1));
          numbers.add(num);
          remaining -= num;
        }
        numbers.add(remaining.clamp(_min, _max));
        while (numbers.length < numCount) {
          numbers.add(_min + _random.nextInt(_max - _min + 1));
        }
        numbers.shuffle();
        break;

      case 'subtraction':
      case 'subtract':
        // For subtraction: startNum - (sum of others) = target
        int startNum = (target + _min * 2).clamp(_max ~/ 2, _max);
        numbers = [startNum];
        int subtractSum = startNum - target;
        List<int> subtractors = [];
        int remaining = subtractSum;
        for (int i = 0; i < numCount - 2 && remaining > 0; i++) {
          int num = _min + _random.nextInt((remaining - _min).clamp(1, _max - _min + 1));
          subtractors.add(num);
          remaining -= num;
        }
        if (remaining > 0) subtractors.add(remaining);
        numbers.addAll(subtractors);
        while (numbers.length < numCount) {
          numbers.add(_min + _random.nextInt(_max - _min + 1));
        }
        numbers.shuffle();
        break;

      case 'multiplication':
      case 'multiply':
        // For multiplication, generate factors
        int solutionCount = 2 + _random.nextInt(numCount - 1);
        numbers = [];
        int remaining = target;
        for (int i = 0; i < solutionCount - 1 && remaining > 1; i++) {
          int factor = _min + _random.nextInt(((remaining / _min).round().clamp(1, _max - _min + 1)).toInt());
          if (factor > 1 && remaining % factor == 0) {
            numbers.add(factor);
            remaining ~/= factor;
          } else {
            numbers.add(_min + _random.nextInt(_max - _min + 1));
          }
        }
        if (remaining > 1) numbers.add(remaining);
        while (numbers.length < numCount) {
          numbers.add(_min + _random.nextInt(_max - _min + 1));
        }
        numbers.shuffle();
        break;

      case 'division':
      case 'divide':
        // For division: dividend / (product of divisors) = target
        int divisor = _min + _random.nextInt(_max - _min + 1);
        int dividend = target * divisor;
        numbers = [dividend, divisor];
        while (numbers.length < numCount) {
          numbers.add(_min + _random.nextInt(_max - _min + 1));
        }
        numbers.shuffle();
        break;

      default:
        numbers = List.generate(numCount, (_) => _min + _random.nextInt(_max - _min + 1));
        numbers.shuffle();
    }

    return _PreviewRound(target: finalTarget, numbers: numbers);
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

    setState(() {
      _rounds[index] = _generateRoundWithTarget(newTarget);
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
