import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/basic_operator_quiz.dart';
import '../services/unlock_service.dart';
import '../services/activity_progress_service.dart';
import 'student_dashboard.dart';

class BasicOperatorQuizScreen extends StatefulWidget {
  final BasicOperatorQuiz quiz;
  final String userId;
  final String? lessonId; // Optional lesson ID if quiz is taken from a lesson

  const BasicOperatorQuizScreen({
    super.key,
    required this.quiz,
    required this.userId,
    this.lessonId,
  });

  @override
  State<BasicOperatorQuizScreen> createState() =>
      _BasicOperatorQuizScreenState();
}

class _BasicOperatorQuizScreenState extends State<BasicOperatorQuizScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  int _selected = -1;
  int _score = 0;
  int _current = 0;
  bool _quizFinished = false;
  bool _locked = false;
  bool _answered = false;
  bool _showReview = false;

  final Map<int, String> _allSelectedAnswers = {};
  late Timer _timer;
  late int _remainingSeconds;
  late int _initialSeconds; // Track initial time for elapsed time calculation
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  final supabase = Supabase.instance.client;
  final _unlockService = UnlockService();
  final _activityProgressService = ActivityProgressService();

  @override
  void initState() {
    super.initState();
    final questionCount = widget.quiz.questions.length;
    _initialSeconds = ((questionCount / 5).ceil() * 60);
    _remainingSeconds = _initialSeconds;
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
      // Check attempts from unified activity_progress table
      final attemptsCount = await _activityProgressService.getAttemptCount(
        userId: widget.userId,
        entityType: 'quiz',
        entityId: widget.quiz.id!,
      );

      // Lock after 3 attempts (or remove this limit if you want unlimited attempts)
      if (attemptsCount >= 3) {
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
      final total = widget.quiz.questions.length;
      final score = _score; // Raw score (number of correct answers)
      
      // Calculate elapsed time (initial time - remaining time)
      final elapsedSeconds = _initialSeconds - _remainingSeconds;

      // Save to unified activity_progress table
      // The service automatically handles attempt numbering and prevents duplicates
      await _activityProgressService.saveQuizProgress(
        userId: widget.userId,
        quizId: widget.quiz.id!,
        quizTitle: widget.quiz.title,
        operator: widget.quiz.operator,
        score: score, // Raw score (e.g., 5 for 5/5)
        totalQuestions: total,
        classroomId: widget.quiz.classroomId,
        lessonId: widget.lessonId, // Pass lesson ID if available
        elapsedTime: elapsedSeconds > 0 ? elapsedSeconds : null,
      );

      // Get attempt count for unlock logic
      final attemptsCount = await _activityProgressService.getAttemptCount(
        userId: widget.userId,
        entityType: 'quiz',
        entityId: widget.quiz.id!,
      );

      // Unlock next lessons after quiz completion (quizzes are always accessible)
      // Pass actual score (not percentage) - RPC function calculates percentage internally
      final unlockResult = await _unlockService.checkAndUnlockAfterQuiz(
        userId: widget.userId,
        quizId: widget.quiz.id!,
        score: score, // Pass actual score (e.g., 5 for 5/5), not percentage
        totalQuestions: total,
        attemptsCount: attemptsCount,
        lessonId: widget.lessonId, // Pass lesson ID if quiz was taken from a lesson
      );
      
      // Show feedback if unlock was successful or failed
      if (unlockResult != null && mounted) {
        if (unlockResult['unlocked'] == true) {
          final items = unlockResult['items'] as List?;
          final method = unlockResult['_method'] as String?;
          final message = items != null && items.isNotEmpty
              ? '🎉 ${items.length} item(s) unlocked!'
              : '🎉 Unlocked!';
          
          // Show which method was used (for debugging cache status)
          final methodNote = method == 'rpc'
              ? ' (using server-side RPC)'
              : method == 'client-side'
                  ? ' (using client-side fallback - cache not refreshed yet)'
                  : '';
          
          final durationSeconds = method == 'rpc' ? 2 : 3;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$message$methodNote'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: durationSeconds),
            ),
          );
        } else if (unlockResult['error'] != null) {
          // Only show non-schema-cache errors (schema cache errors are handled by fallback)
          final error = unlockResult['error'] as String;
          final errorLower = error.toLowerCase();
          
          // Don't show schema cache or UUID errors - they're handled by client-side fallback
          final isSchemaCacheError = errorLower.contains('schema cache') ||
              errorLower.contains('pgrst202') ||
              errorLower.contains('could not find the function') ||
              errorLower.contains('postgresterror');
          
          final isUuidError = errorLower.contains('invalid input syntax for type uuid') ||
              errorLower.contains('22p02');
          
          if (!isSchemaCacheError && !isUuidError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Unlock error: $error'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e, stackTrace) {
      // Error saving progress - silently fail
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
    final currentQ = widget.quiz.questions[_current];
    final correctLetter = currentQ.correctChoice;
    final selectedLetter = _selected >= 0 ? ['A', 'B', 'C'][_selected] : null;
    final isCorrect = selectedLetter == correctLetter;

    if (selectedLetter != null) {
      _allSelectedAnswers[_current] = selectedLetter;
    }

    setState(() {
      _answered = true;
      if (isCorrect) _score++;
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (_current < widget.quiz.questions.length - 1) {
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
    setState(() => _quizFinished = true);
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
        title: Text(widget.quiz.title),
        backgroundColor: Colors.lightBlue,
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
                    'Score: $_score / ${widget.quiz.questions.length}',
                    style: const TextStyle(fontSize: 18),
                  ),
                  Text(
                    'Percentage: ${(_score / widget.quiz.questions.length * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...widget.quiz.questions.asMap().entries.map((entry) {
            final index = entry.key;
            final currentQ = entry.value;
            final options = [currentQ.choiceA, currentQ.choiceB, currentQ.choiceC];
            final correctLetter = currentQ.correctChoice;
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
                      currentQ.questionText,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(options.length, (i) {
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
                          title: Text('$letter. ${options[i]}'),
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
              backgroundColor: Colors.lightBlue,
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

    if (_quizFinished) return const SizedBox.shrink();

    final currentQ = widget.quiz.questions[_current];
    final options = [currentQ.choiceA, currentQ.choiceB, currentQ.choiceC];
    final correctLetter = currentQ.correctChoice;
    final selectedLetter = _allSelectedAnswers[_current];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quiz.title),
        backgroundColor: Colors.lightBlue,
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
                    color: Colors.white),
              ),
            ]),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child:
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Question ${_current + 1} of ${widget.quiz.questions.length}',
              style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 16),
          Text(currentQ.questionText,
              style:
              const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          ...List.generate(options.length, (i) {
            final letter = ['A', 'B', 'C'][i];
            Color cardColor = Colors.white;

            if (_answered) {
              if (letter == correctLetter) cardColor = Colors.greenAccent;
              else if (_selected == i) cardColor = Colors.redAccent;
            } else if (_selected == i) cardColor = Colors.orangeAccent;

            return Card(
              color: cardColor,
              child: ListTile(
                title: Text('$letter. ${options[i]}'),
                onTap: _answered
                    ? null
                    : () => setState(() {
                  _selected = i;
                }),
              ),
            );
          }),
          const Spacer(),
          ElevatedButton(
            onPressed: (_selected == -1 || _answered) ? null : _next,
            style:
            ElevatedButton.styleFrom(backgroundColor: Colors.lightBlue),
            child: Text(_current == widget.quiz.questions.length - 1
                ? 'Finish'
                : 'Next'),
          ),
        ]),
      ),
    );
  }
}
