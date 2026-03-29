import 'package:flutter/material.dart';

class QuizDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> quiz;
  const QuizDetailsScreen({super.key, required this.quiz});

  @override
  Widget build(BuildContext context) {
    final questions = quiz['questions'] as List<dynamic>;

    return Scaffold(
      appBar: AppBar(title: Text(quiz['title'] ?? 'Quiz Details')),
      body: ListView.builder(
        itemCount: questions.length,
        itemBuilder: (context, index) {
          final q = questions[index];
          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              title: Text(q['question_text']),
              subtitle: Text(
                "A: ${q['choice_a']}\nB: ${q['choice_b']}\nC: ${q['choice_c']}",
              ),
              trailing: Text("Answer: ${q['correct_choice']}"),
            ),
          );
        },
      ),
    );
  }
}
