import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/quiz_provider.dart';

class CreateQuizScreen extends StatefulWidget {
  final String classroomId;
  final String lessonId;

  const CreateQuizScreen({
    Key? key,
    required this.classroomId,
    required this.lessonId,
  }) : super(key: key);

  @override
  State<CreateQuizScreen> createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends State<CreateQuizScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();

  final List<Map<String, dynamic>> _questions = [];

  @override
  void initState() {
    super.initState();
    _addQuestion();
  }

  void _addQuestion() {
    setState(() {
      _questions.add({
        "q": TextEditingController(),
        "a": TextEditingController(),
        "b": TextEditingController(),
        "c": TextEditingController(),
        "correct": "A",
      });
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final quizProvider = Provider.of<QuizProvider>(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text("Create Quiz")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Quiz Title"),
                validator: (val) => val == null || val.isEmpty ? "Enter a title" : null,
              ),
              const SizedBox(height: 16),
              ..._questions.asMap().entries.map((entry) {
                final idx = entry.key;
                final q = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Question ${idx + 1}",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (_questions.length > 1)
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeQuestion(idx),
                              ),
                          ],
                        ),
                        TextFormField(
                          controller: q["q"],
                          decoration: const InputDecoration(labelText: "Question"),
                          validator: (val) => val == null || val.isEmpty ? "Enter question" : null,
                        ),
                        TextFormField(controller: q["a"], decoration: const InputDecoration(labelText: "Choice A")),
                        TextFormField(controller: q["b"], decoration: const InputDecoration(labelText: "Choice B")),
                        TextFormField(controller: q["c"], decoration: const InputDecoration(labelText: "Choice C")),
                        DropdownButtonFormField<String>(
                          value: q["correct"],
                          items: const [
                            DropdownMenuItem(value: "A", child: Text("Correct = A")),
                            DropdownMenuItem(value: "B", child: Text("Correct = B")),
                            DropdownMenuItem(value: "C", child: Text("Correct = C")),
                          ],
                          onChanged: (val) => q["correct"] = val!,
                        ),
                      ],
                    ),
                  ),
                );
              }),
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text("Add Question"),
                    onPressed: _addQuestion,
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    child: const Text("Save Quiz"),
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final questions = _questions
                            .where((q) => q["q"].text.trim().isNotEmpty)
                            .map((q) => {
                          "q": q["q"].text,
                          "options": [q["a"].text, q["b"].text, q["c"].text],
                          "a": q["correct"],
                        })
                            .toList();

                        final teacherId = Supabase.instance.client.auth.currentUser?.id;
                        if (teacherId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Error: teacher not logged in")),
                          );
                          return;
                        }

                        await quizProvider.createQuiz(
                          classroomId: widget.classroomId,
                          lessonId: widget.lessonId,
                          title: _titleController.text,
                          questions: questions,
                          teacherId: teacherId,
                        );

                        if (mounted) Navigator.pop(context, true);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
