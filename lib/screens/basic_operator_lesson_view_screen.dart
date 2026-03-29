import 'package:flutter/material.dart';
import 'package:pracpro/models/basic_operator_lesson.dart';
import 'package:pracpro/models/basic_operator_quiz.dart';
import 'package:pracpro/screens/basic_operator_quiz_screen.dart';
import 'package:pracpro/screens/basic_operator_quiz_view_screen.dart';
import 'package:pracpro/services/basic_operator_quiz_service.dart';
import 'package:pracpro/utils/pdf_viewer.dart';
import 'package:pracpro/widgets/cached_video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BasicOperatorLessonViewScreen extends StatefulWidget {
  final BasicOperatorLesson lesson;
  const BasicOperatorLessonViewScreen({super.key, required this.lesson});

  @override
  State<BasicOperatorLessonViewScreen> createState() =>
      _BasicOperatorLessonViewScreenState();
}

class _BasicOperatorLessonViewScreenState
    extends State<BasicOperatorLessonViewScreen> {
  final _quizService = BasicOperatorQuizService();
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  bool _isTeacher = false;
  bool _isLoadingUserRole = true;
  List<BasicOperatorQuiz> _quizzes = [];

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _loadRelatedQuizzes();
  }

  Future<void> _checkUserRole() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() {
        _isTeacher = false;
        _isLoadingUserRole = false;
      });
      return;
    }

    try {
      final res = await supabase
          .from('users')
          .select('user_type')
          .eq('id', user.id)
          .maybeSingle();

      setState(() {
        _isTeacher = res?['user_type'] == 'teacher';
        _isLoadingUserRole = false;
      });
    } catch (e) {
      setState(() {
        _isTeacher = false;
        _isLoadingUserRole = false;
      });
    }
  }

  Future<void> _loadRelatedQuizzes() async {
    try {
      // Load quizzes filtered by this lesson's ID
      _quizzes = await _quizService.getQuizzes(
        widget.lesson.operator,
        classroomId: widget.lesson.classroomId,
        lessonId: widget.lesson.id,
      );
    } catch (_) {
      _quizzes = [];
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;

    return Scaffold(
      appBar: AppBar(
        title: Text(lesson.title),
        backgroundColor: Colors.lightBlue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (lesson.youtubeUrl != null && lesson.youtubeUrl!.isNotEmpty)
              _buildYoutubePreview(context),
            if (lesson.fileUrl != null && lesson.fileUrl!.isNotEmpty)
              _buildFileSection(context),
            const SizedBox(height: 16),
            Text(
              lesson.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              lesson.description ?? 'No description provided.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            _buildMetadata(context),
            const Divider(height: 32),
            _buildRelatedQuizzes(context),
          ],
        ),
      ),
    );
  }

  Widget _buildYoutubePreview(BuildContext context) {
    return CachedVideoPlayer(
      youtubeUrl: widget.lesson.youtubeUrl!,
      autoPlay: false,
      showControls: true,
    );
  }

  Widget _buildFileSection(BuildContext context) => ElevatedButton.icon(
    icon: const Icon(Icons.picture_as_pdf),
    label: const Text('Open Lesson File'),
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfViewerScreen(
            fileUrl: widget.lesson.fileUrl!,
            title: widget.lesson.title,
          ),
        ),
      );
    },
  );

  Widget _buildMetadata(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Operator: ${widget.lesson.operator}',
          style: const TextStyle(color: Colors.grey, fontSize: 14)),
      if (widget.lesson.createdAt != null)
        Text(
          'Created: ${widget.lesson.createdAt!.toLocal()}',
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
    ],
  );

  Widget _buildRelatedQuizzes(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_quizzes.isEmpty) {
      return const Text('No quizzes for this lesson yet.',
          style: TextStyle(color: Colors.grey));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Related Quizzes',
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue),
        ),
        const SizedBox(height: 12),
        ..._quizzes.map((quiz) {
          final user = Supabase.instance.client.auth.currentUser;
          return Card(
            color: Colors.blue[50],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(Icons.quiz, color: Colors.deepPurple),
              title: Text(quiz.title),
              subtitle:
              Text('${quiz.questions.length} question(s) available'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded),
              onTap: () {
                if (user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Login required to take quizzes')),
                  );
                  return;
                }
                // Teachers can only view quizzes, not take them
                if (_isTeacher) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BasicOperatorQuizViewScreen(
                        quiz: quiz,
                      ),
                    ),
                  );
                } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BasicOperatorQuizScreen(
                      quiz: quiz,
                      userId: user.id,
                      lessonId: widget.lesson.id, // Pass lesson ID when quiz is taken from a lesson
                    ),
                  ),
                );
                }
              },
            ),
          );
        }),
      ],
    );
  }
}
