import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:pracpro/modules/basic_operators/subtraction/widgets/subtraction_quiz_screen.dart';
import 'package:pracpro/utils/youtube_utils.dart';

class SubtractionLessonViewScreen extends StatefulWidget {
  final String lessonTitle;
  final String explanation;
  final String videoUrl;
  final List<dynamic> quiz;
  const SubtractionLessonViewScreen({
    super.key,
    required this.lessonTitle,
    required this.explanation,
    required this.videoUrl,
    required this.quiz,
  });

  @override
  State<SubtractionLessonViewScreen> createState() =>
      _SubtractionLessonViewScreenState();
}

class _SubtractionLessonViewScreenState
    extends State<SubtractionLessonViewScreen> {
  YoutubePlayerController? _controller;

  @override
  void initState() {
    super.initState();
    final videoId = YouTubeUtils.extractVideoId(widget.videoUrl);
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lessonTitle),
        backgroundColor: Colors.redAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.red[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.lessonTitle,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.explanation,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    if (_controller != null)
                    YoutubePlayer(
                        controller: _controller!,
                      showVideoProgressIndicator: true,
                      progressIndicatorColor: Colors.redAccent,
                      progressColors: const ProgressBarColors(
                        playedColor: Colors.red,
                        handleColor: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.quiz),
                      label: const Text("Take Quiz"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => SubtractionQuizScreen(
                                  questions:
                                      widget.quiz.cast<Map<String, dynamic>>(),
                                ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
