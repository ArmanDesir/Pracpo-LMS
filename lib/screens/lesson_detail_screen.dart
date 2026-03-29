import 'package:flutter/material.dart';
import 'package:pracpro/screens/LessonQuizScreen.dart';
import 'package:pracpro/utils/pdf_viewer.dart';
import 'package:pracpro/utils/youtube_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/content.dart';

class LessonDetailScreen extends StatefulWidget {
  final Content content;
  const LessonDetailScreen({super.key, required this.content});

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  bool _hasQuiz = false;
  bool _isLoadingQuizCheck = true;

  @override
  void initState() {
    super.initState();
    _checkIfQuizExists();
  }

  Future<void> _checkIfQuizExists() async {
    try {
      final quiz = await Supabase.instance.client
          .from('quizzes')
          .select('id')
          .eq('lesson_id', widget.content.id)
          .maybeSingle();

      setState(() {
        _hasQuiz = quiz != null;
        _isLoadingQuizCheck = false;
      });
    } catch (e) {
      setState(() => _isLoadingQuizCheck = false);
    }
  }

  Future<void> _openFile(BuildContext context) async {
    final fileUrl = widget.content.fileUrl;

    if (fileUrl == null || fileUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No file attached.")),
      );
      return;
    }

    if (fileUrl.toLowerCase().endsWith('.pdf')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfViewerScreen(
            fileUrl: fileUrl,
            title: widget.content.title,
          ),
        ),
      );
      return;
    }

    final Uri url = Uri.parse(fileUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not open ${widget.content.fileName ?? 'file'}")),
      );
    }
  }

  String? _getYoutubeId(String? url) {
    if (url == null || url.isEmpty) return null;
    // Use YouTubeUtils.extractVideoId which has proper validation
    return YouTubeUtils.extractVideoId(url);
  }

  @override
  Widget build(BuildContext context) {
    final youtubeId = _getYoutubeId(widget.content.youtubeUrl);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.content.title),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.content.title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(widget.content.description ?? ''),
            const SizedBox(height: 16),

            if (widget.content.fileUrl != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  title: const Text("Open Attached File"),
                  subtitle: Text(widget.content.fileName ?? "Lesson document"),
                  onTap: () => _openFile(context),
                ),
              ),
            const SizedBox(height: 16),

            if (youtubeId != null && youtubeId.isNotEmpty) ...[
              Text(
                "Video Lesson",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              YoutubePlayer(
                controller: YoutubePlayerController(
                  initialVideoId: youtubeId,
                  flags: const YoutubePlayerFlags(autoPlay: false),
                ),
                showVideoProgressIndicator: true,
              ),
              const SizedBox(height: 16),
            ],

            if (!_isLoadingQuizCheck &&
                widget.content.type == ContentType.lesson &&
                _hasQuiz)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LessonQuizzesScreen(
                        lessonId: widget.content.id,
                        classroomId: widget.content.classroomId,
                        userId:
                        Supabase.instance.client.auth.currentUser!.id,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.quiz),
                label: const Text("Take Quiz"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
