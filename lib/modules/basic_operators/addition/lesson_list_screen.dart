import 'package:flutter/material.dart';
import 'package:pracpro/models/lesson.dart';
import 'package:pracpro/services/lesson_service.dart';
import 'lesson_view_screen.dart';

class LessonListScreen extends StatelessWidget {
  const LessonListScreen({
    super.key,
    required this.classroomId,
    this.operatorFilter,
    this.difficulty,
    this.useRealtime = false
  });

  final String classroomId;
  final String? operatorFilter;
  final int? difficulty;
  final bool useRealtime;

  @override
  Widget build(BuildContext context) {
    final service = LessonService();

    Widget listBuilder(List<Lesson> lessons) {
      if (lessons.isEmpty) {
        return const Center(child: Text('No lessons yet.'));
      }
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: lessons.length,
        itemBuilder: (_, i) {
          final l = lessons[i];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.lightBlue,
                child: const Icon(Icons.add_circle_outline, color: Colors.white),
              ),
              title: Text(l.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                l.description ?? 'No description',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LessonViewScreen(lesson: l),
                  ),
                );
              },
            ),
          );
        },
      );
    }

    if (useRealtime) {
      return Scaffold(
        appBar: AppBar(title: const Text('Addition Lessons'), backgroundColor: Colors.lightBlue),
        body: StreamBuilder<List<Lesson>>(
          stream: service.streamLessons(
            classroomId,
            operatorFilter: operatorFilter,
            difficulty: difficulty,
          ),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(child: Text('Error: ${snap.error}'));
            }
            return listBuilder(snap.data ?? const []);
          },
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(title: const Text('Addition Lessons'), backgroundColor: Colors.lightBlue),
        body: FutureBuilder<List<Lesson>>(
          future: service.getLessons(
            classroomId,
            operatorFilter: operatorFilter,
            difficulty: difficulty,
          ),
          builder: (context, snap) {
            if (!snap.hasData) {
              if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
              return const Center(child: CircularProgressIndicator());
            }
            return listBuilder(snap.data!);
          },
        ),
      );
    }
  }
}
