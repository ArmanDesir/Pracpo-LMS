import 'package:flutter/material.dart';
import 'package:pracpro/screens/student_dashboard.dart';
import 'package:pracpro/services/unlock_service.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuizScreen extends StatefulWidget {
  final List<Map<String, dynamic>> questions;
  final String quizId;
  final String userId;

  const QuizScreen({
    Key? key,
    required this.questions,
    required this.quizId,
    required this.userId,
  }) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  int _selected = -1;
  int _score = 0;
  int _current = 0;
  bool _quizFinished = false;
  bool _locked = false;
  bool _answered = false;
  bool _showAnswers = false;
  bool _showReview = false;

  final Map<int, String> _allSelectedAnswers = {};
  late Timer _timer;
  late int _remainingSeconds;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  final _unlockService = UnlockService();

  @override
  void initState() {
    super.initState();
    final questionCount = widget.questions.length;
    _remainingSeconds = ((questionCount / 5).ceil() * 60);
    WidgetsBinding.instance.addObserver(this);
    _checkAttempts();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
  }

  Future<void> _checkAttempts() async {
    try {
      final res = await Supabase.instance.client
          .from('quiz_progress')
          .select()
          .eq('user_id', widget.userId)
          .eq('quiz_id', widget.quizId)
          .maybeSingle();

      if (res != null && (res['attempts_count'] ?? 0) >= 3) {
        setState(() => _locked = true);
        return;
      }

      _startTimer();
    } catch (e) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _finishQuiz();
      }
    });
  }

  Future<void> _saveProgress() async {
    try {
      final client = Supabase.instance.client;
      final total = widget.questions.length;
      final percent = (_score / total * 100).round();

      final existing = await client
          .from('quiz_progress')
          .select()
          .eq('user_id', widget.userId)
          .eq('quiz_id', widget.quizId)
          .maybeSingle();

      int attemptsCount;
      if (existing == null || existing.isEmpty) {
        await client.from('quiz_progress').insert({
          'user_id': widget.userId,
          'quiz_id': widget.quizId,
          'try1_score': percent,
          'highest_score': percent,
          'attempts_count': 1,
          'updated_at': DateTime.now().toIso8601String(),
        });
        attemptsCount = 1;
      } else {
        int attempts = (existing['attempts_count'] ?? 0) + 1;
        if (attempts > 3) attempts = 3;
        attemptsCount = attempts;

        int try1 = existing['try1_score'] ?? 0;
        int try2 = existing['try2_score'] ?? 0;
        int try3 = existing['try3_score'] ?? 0;

        if (attempts == 2 && try2 == 0) try2 = percent;
        if (attempts == 3 && try3 == 0) try3 = percent;

        final highest =
        [try1, try2, try3, percent].reduce((a, b) => a > b ? a : b);

        await client
            .from('quiz_progress')
            .update({
          'try1_score': try1,
          'try2_score': try2,
          'try3_score': try3,
          'highest_score': highest,
          'attempts_count': attempts,
          'updated_at': DateTime.now().toIso8601String(),
        })
            .eq('user_id', widget.userId)
            .eq('quiz_id', widget.quizId);
      }

      // Check and unlock next content after saving progress
      // Note: This quiz uses 'quiz_progress' table, not 'basic_operator_quiz_progress'
      // The RPC function works with basic_operator_quizzes, so we skip unlock for legacy quizzes
      // Only basic_operator_quizzes support unlock feature
    } catch (e, st) {
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (!_locked) _timer.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_locked &&
        (state == AppLifecycleState.paused ||
            state == AppLifecycleState.detached)) {
      _saveProgress();
    }
  }

  void _next() {
    final currentQ = widget.questions[_current];
    final correctLetter = currentQ['correct_choice'];
    final selectedLetter = _selected >= 0 ? ['A', 'B', 'C'][_selected] : null;
    final isCorrect = selectedLetter == correctLetter;

    if (selectedLetter != null) {
      _allSelectedAnswers[_current] = selectedLetter;
    }

    setState(() {
      _answered = true;
      if (isCorrect) _score++;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (_current < widget.questions.length - 1) {
        setState(() {
          _current++;
          _selected = -1;
          _answered = false;
        });
      } else {
        _finishQuiz();
      }
    });
  }

  void _finishQuiz() async {
    if (_locked) return;

    _timer.cancel();
    await _saveProgress();
    setState(() {
      _quizFinished = true;
      _showAnswers = true;
    });
    _animationController.forward();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _showReview = true;
        });
      }
    });
  }

  String _formatTime(int seconds) {
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  Widget _buildReviewScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Review'),
        backgroundColor: Colors.green,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Quiz Results',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Score: $_score / ${widget.questions.length}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  Text(
                    'Percentage: ${(_score / widget.questions.length * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...widget.questions.asMap().entries.map((entry) {
            final index = entry.key;
            final rawQ = entry.value;
            final q = {
              'question_text': rawQ['question_text'] ?? 'Untitled question',
              'options': rawQ['options'] ??
                  [
                    rawQ['choice_a'] ?? '',
                    rawQ['choice_b'] ?? '',
                    rawQ['choice_c'] ?? '',
                  ],
              'correct_choice': rawQ['correct_choice'] ?? 'A',
            };
            final correctLetter = q['correct_choice'];
            final selectedLetter = _allSelectedAnswers[index];

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
                            color: (selectedLetter == correctLetter)
                                ? Colors.green
                                : Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Q${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          (selectedLetter == correctLetter)
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: (selectedLetter == correctLetter)
                              ? Colors.green
                              : Colors.red,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      q['question_text'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(q['options'].length, (i) {
                      final letter = ['A', 'B', 'C'][i];
                      Color? backgroundColor;
                      Color borderColor = Colors.grey.withOpacity(0.3);
                      double borderWidth = 1;

                      if (letter == correctLetter) {
                        backgroundColor = Colors.green[100];
                        borderColor = Colors.green;
                        borderWidth = 2;
                      } else if (letter == selectedLetter && selectedLetter != correctLetter) {
                        backgroundColor = Colors.red[100];
                        borderColor = Colors.red;
                        borderWidth = 2;
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: borderColor,
                            width: borderWidth,
                          ),
                        ),
                        child: ListTile(
                          title: Text('$letter. ${q['options'][i]}'),
                          trailing: letter == correctLetter
                              ? const Icon(Icons.check, color: Colors.green)
                              : (letter == selectedLetter && selectedLetter != correctLetter)
                                  ? const Icon(Icons.close, color: Colors.red)
                                  : null,
                        ),
                      );
                    }),
                    if (selectedLetter != correctLetter)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.amber[800]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Your answer: ${selectedLetter ?? "Not answered"} | Correct: $correctLetter',
                                style: TextStyle(
                                  color: Colors.amber[900],
                                  fontWeight: FontWeight.w500,
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
          }),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Done', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_locked) {
      return Scaffold(
        appBar: AppBar(title: const Text("Quiz Locked")),
        body: const Center(
          child: Text(
            "You have already used all 3 attempts.\nYour highest score is saved.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    if (_showReview) {
      return _buildReviewScreen();
    }

    if (_quizFinished) {
      return const SizedBox.shrink();
    }

    final rawQ = widget.questions[_current];
    final q = {
      'question_text': rawQ['question_text'] ?? 'Untitled question',
      'options': rawQ['options'] ??
          [
            rawQ['choice_a'] ?? '',
            rawQ['choice_b'] ?? '',
            rawQ['choice_c'] ?? '',
          ],
      'correct_choice': rawQ['correct_choice'] ?? 'A',
    };

    final correctLetter = q['correct_choice'];
    final selectedLetter = _allSelectedAnswers[_current];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz'),
        backgroundColor: Colors.green,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              const Icon(Icons.timer, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                _formatTime(_remainingSeconds),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ]),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Question ${_current + 1} of ${widget.questions.length}',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            Text(q['question_text'],
                style:
                const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ...List.generate(q['options'].length, (i) {
              final letter = ['A', 'B', 'C'][i];
              Color cardColor = Colors.white;

              if (_showAnswers) {
                if (letter == correctLetter) {
                  cardColor = Colors.greenAccent;
                } else if (letter == selectedLetter && selectedLetter != correctLetter) {
                  cardColor = Colors.redAccent.withOpacity(0.3);
                }
              } else if (_selected == i) {
                cardColor = Colors.orangeAccent;
              }

              return Card(
                color: cardColor,
                child: ListTile(
                  title: Text(q['options'][i]),
                  onTap: _showAnswers
                      ? null
                      : () => setState(() {
                    _selected = i;
                  }),
                ),
              );
            }),
            const Spacer(),
            if (!_showAnswers)
              ElevatedButton(
                onPressed: (_selected == -1 || _answered) ? null : _next,
                style:
                ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: Text(_current == widget.questions.length - 1
                    ? 'Finish'
                    : 'Next'),
              ),
          ],
        ),
      ),
    );
  }
}
