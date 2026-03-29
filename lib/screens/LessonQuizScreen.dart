import 'package:flutter/material.dart';
import 'package:pracpro/modules/basic_operators/addition/quiz_screen.dart';
import 'package:pracpro/providers/quiz_provider.dart';
import 'package:provider/provider.dart';

class LessonQuizzesScreen extends StatefulWidget {
  final String lessonId;
  final String classroomId;
  final String userId;

  const LessonQuizzesScreen({
    super.key,
    required this.lessonId,
    required this.classroomId,
    required this.userId,
  });

  @override
  State<LessonQuizzesScreen> createState() => _LessonQuizzesScreenState();
}

class _LessonQuizzesScreenState extends State<LessonQuizzesScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    try {
      await quizProvider.loadQuizzesForLesson(widget.lessonId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load quizzes")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizProvider = Provider.of<QuizProvider>(context);
    final quizzes = quizProvider.lessonQuizzes;

    return Scaffold(
      appBar: AppBar(title: const Text("Quizzes")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : quizzes.isEmpty
          ? const Center(child: Text("No quizzes available for this lesson"))
          : ListView.builder(
        itemCount: quizzes.length,
        itemBuilder: (context, index) {
          final quiz = quizzes[index];
          return Card(
            child: ListTile(
              title: Text(quiz['title'] ?? 'Untitled Quiz'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QuizScreen(
                      quizId: quiz['id'],
                      questions: List<Map<String, dynamic>>.from(quiz['questions'] ?? []),
                      userId: widget.userId,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
