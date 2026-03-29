import 'package:flutter/material.dart';
import 'package:pracpro/modules/basic_operators/subtraction/widgets/subtraction_view_screen.dart';
import 'subtraction_mock_data.dart';

class SubtractionLessonsScreen extends StatelessWidget {
  const SubtractionLessonsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subtraction Lessons'),
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
                  children: const [
                    Text(
                      'Subtraction Lessons',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Learn the fundamental of subtraction through interactive lessons!',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: subtractionLessons.length,
                itemBuilder: (context, index) {
                  final lesson = subtractionLessons[index];
                  return _buildLessonCard(
                    lesson['title'],
                    lesson['explanation'],
                    Icons.remove_circle_outline,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => SubtractionLessonViewScreen(
                                lessonTitle: lesson['title'],
                                explanation: lesson['explanation'],
                                videoUrl: lesson['videoUrl'],
                                quiz: lesson['quiz'],
                              ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonCard(
    String title,
    String description,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.redAccent,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
