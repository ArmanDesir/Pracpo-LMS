import 'package:flutter/material.dart';

class MultiplicationLessonsScreen extends StatelessWidget {
  const MultiplicationLessonsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Multiplication Lessons'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.green[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Multiplication Lessons',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Master multiplication through step-by-step lessons!',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: [
                  _buildLessonCard(
                    'Lesson 1: Introduction to Multiplication',
                    'Learn what multiplication means and how it relates to addition',
                    Icons.close,
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Lesson 1 - Coming Soon!'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildLessonCard(
                    'Lesson 2: Times Tables',
                    'Learn and memorize multiplication tables from 1 to 12',
                    Icons.table_chart,
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Lesson 2 - Coming Soon!'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildLessonCard(
                    'Lesson 3: Multi-digit Multiplication',
                    'Learn to multiply larger numbers using different methods',
                    Icons.calculate,
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Lesson 3 - Coming Soon!'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildLessonCard(
                    'Lesson 4: Word Problems',
                    'Apply multiplication skills to solve real-world problems',
                    Icons.description,
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Lesson 4 - Coming Soon!'),
                        ),
                      );
                    },
                  ),
                ],
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
          backgroundColor: Colors.green,
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
