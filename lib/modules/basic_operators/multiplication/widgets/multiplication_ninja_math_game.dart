import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

import 'package:pracpro/modules/basic_operators/addition/game_theme.dart';
import 'package:pracpro/modules/basic_operators/addition/widgets/game_button.dart';

class MultiplicationNinjaMathGameScreen extends StatefulWidget {
  final String difficulty;
  const MultiplicationNinjaMathGameScreen({
    super.key,
    required this.difficulty,
  });

  @override
  State<MultiplicationNinjaMathGameScreen> createState() =>
      _MultiplicationNinjaMathGameScreenState();
}

class _MultiplicationNinjaMathGameScreenState
    extends State<MultiplicationNinjaMathGameScreen> {
  late int _remainingSeconds;
  late Timer _timer;
  bool _gameFinished = false;
  int _score = 0;
  int _current = 0;
  late List<_MultiplicationTargetRound> _rounds;
  List<int> _selected = [];
  final int _totalRounds = 10;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _setTimer();
    _rounds = _generateRounds();
    _startTimer();
  }

  void _setTimer() {
    if (widget.difficulty == 'Easy') {
      _remainingSeconds = 300;
    } else if (widget.difficulty == 'Medium') {
      _remainingSeconds = 420;
    } else {
      _remainingSeconds = 600;
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _finishGame();
      }
    });
  }

  List<_MultiplicationTargetRound> _generateRounds() {
    int max = 5;
    if (widget.difficulty == 'Medium') max = 8;
    if (widget.difficulty == 'Hard') max = 12;

    List<_MultiplicationTargetRound> list = [];
    for (int i = 0; i < _totalRounds; i++) {
      int factor1 = 2 + _random.nextInt(max - 1);
      int factor2 = 2 + _random.nextInt(max - 1);
      int target = factor1 * factor2;

      List<int> numbers = [factor1, factor2];
      while (numbers.length < 5) {
        int distractor = 1 + _random.nextInt(max + 2);
        if (!numbers.contains(distractor)) {
          numbers.add(distractor);
        }
      }
      numbers.shuffle();

      list.add(
        _MultiplicationTargetRound(
          target: target,
          numbers: numbers,
          correctFactors: [factor1, factor2],
        ),
      );
    }
    return list;
  }

  void _finishGame() {
    _timer.cancel();
    setState(() {
      _gameFinished = true;
    });
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            title: const Text('Game Over!'),
            content: Text(
              'Your score: $_score/$_totalRounds\nTime left: ${_formatTime(_remainingSeconds)}',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
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
    _timer.cancel();
    super.dispose();
  }

  void _toggleSelect(int n) {
    setState(() {
      if (_selected.contains(n)) {
        _selected.remove(n);
      } else if (_selected.length < 2) {
        _selected.add(n);
      }
    });
  }

  void _submit() {
    final round = _rounds[_current];
    int result = 0;
    bool isCorrect = false;
    
    if (_selected.length == 2) {
      result = _selected[0] * _selected[1];
      isCorrect = result == round.target;
      if (isCorrect) _score++;
    }

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
        content: Text(
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
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (_current < _totalRounds - 1) {
                setState(() {
                  _current++;
                  _selected.clear();
                });
              } else {
                _finishGame();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Continue',
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

  @override
  Widget build(BuildContext context) {
    if (_gameFinished) return const SizedBox.shrink();
    final round = _rounds[_current];
    return Scaffold(
      backgroundColor: GameTheme.background,
      appBar: AppBar(
        title: Text(
          'Multiplication Ninja (${widget.difficulty})',
          style: GameTheme.tileText,
        ),
        backgroundColor: Colors.green,
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
              'Selected: ${_selected.join(' × ')}${_selected.length == 2 ? ' = ${_selected[0] * _selected[1]}' : ''}',
              style: GameTheme.tileText,
            ),
            const SizedBox(height: 8),
            Text('Select 2 numbers to multiply', style: GameTheme.hintText),
            const SizedBox(height: 32),
            _buildNumberBank(round.numbers),
            const SizedBox(height: 32),
            GameButton(
              text: 'Submit',
              onTap: _selected.length == 2 ? _submit : () {},
              color: _selected.length == 2 ? Colors.green : GameTheme.tile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMascot() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          backgroundColor: Colors.green,
          radius: 28,
          child: Icon(Icons.sports_martial_arts, color: Colors.white, size: 36),
        ),
        const SizedBox(width: 12),
        Text('Be a Multiplication Ninja!', style: GameTheme.mascotText),
      ],
    );
  }

  Widget _buildTarget(int target) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.green,
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
    return Wrap(
      spacing: 16,
      children:
          numbers
              .map(
                (n) => GestureDetector(
                  onTap: () => _toggleSelect(n),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 70,
                    height: 70,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color:
                          _selected.contains(n)
                              ? GameTheme.correct
                              : GameTheme.tileBank,
                      borderRadius: BorderRadius.circular(
                        GameTheme.borderRadius,
                      ),
                      border: Border.all(color: Colors.green, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$n',
                      style: GameTheme.tileText.copyWith(color: Colors.black),
                    ),
                  ),
                ),
              )
              .toList(),
    );
  }
}

class _MultiplicationTargetRound {
  final int target;
  final List<int> numbers;
  final List<int> correctFactors;
  _MultiplicationTargetRound({
    required this.target,
    required this.numbers,
    required this.correctFactors,
  });
}
