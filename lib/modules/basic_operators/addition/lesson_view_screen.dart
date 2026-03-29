import 'package:flutter/material.dart';
import 'package:pracpro/models/lesson.dart';
import 'package:pracpro/providers/auth_provider.dart';
import 'package:pracpro/utils/youtube_utils.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'quiz_screen.dart';

class LessonViewScreen extends StatefulWidget {
  final Lesson lesson;
  final List<Map<String, dynamic>> quizQuestions;

  const LessonViewScreen({
    super.key,
    required this.lesson,
    this.quizQuestions = const [],
  });

  @override
  State<LessonViewScreen> createState() => _LessonViewScreenState();
}

class _LessonViewScreenState extends State<LessonViewScreen> {
  YoutubePlayerController? _controller;

  @override
  void initState() {
    super.initState();
    final videoId = YouTubeUtils.extractVideoId(widget.lesson.youtubeUrl ?? '');
    if (videoId != null && videoId.isNotEmpty) {
      // Validate video ID format before creating controller
      if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(videoId)) {
    _controller = YoutubePlayerController(
          initialVideoId: videoId,
      flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
    );
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;

    return Scaffold(
      appBar: AppBar(
        title: Text(lesson.title),
        backgroundColor: Colors.lightBlue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(lesson.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(lesson.description ?? '', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            if ((lesson.youtubeUrl ?? '').isNotEmpty && _controller != null)
              YoutubePlayer(
                controller: _controller!,
                showVideoProgressIndicator: true,
                progressIndicatorColor: Colors.blueAccent,
                progressColors: const ProgressBarColors(
                  playedColor: Colors.blue,
                  handleColor: Colors.blueAccent,
                ),
              ),
            const SizedBox(height: 24),
            if (widget.quizQuestions.isNotEmpty)
              ElevatedButton.icon(
                icon: const Icon(Icons.quiz),
                label: const Text('Take Quiz'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () {
                  final auth = context.read<AuthProvider>();
                  final userId = auth.currentUser!.id;
                  final quizId = "lesson_${lesson.id ?? lesson.title}";

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QuizScreen(
                        questions: widget.quizQuestions,
                        quizId: quizId,
                        userId: userId,
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.videogame_asset),
              label: const Text('Play Game'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              onPressed: () => Navigator.pushNamed(context, '/addition/games'),
            ),
          ],
        ),
      ),
    );
  }
}
