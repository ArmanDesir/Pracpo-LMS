import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/basic_operator_lesson.dart';
import '../providers/basic_operator_exercise_provider.dart';
import '../providers/basic_operator_lesson_provider.dart';
import '../providers/basic_operator_quiz_provider.dart';

class CreateContentScreen extends StatefulWidget {
  final String operator;
  final String contentType;
  final String? classroomId;

  const CreateContentScreen({
    super.key,
    required this.operator,
    required this.contentType,
    this.classroomId,
  });

  @override
  State<CreateContentScreen> createState() => _CreateContentScreenState();
}

class _CreateContentScreenState extends State<CreateContentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lessonTitleController = TextEditingController();
  final _lessonDescController = TextEditingController();
  final _youtubeUrlController = TextEditingController();
  File? _lessonFile;
  String? _lessonFileName;
  final _quizTitleController = TextEditingController();
  final List<Map<String, dynamic>> _questions = [];
  File? _exerciseFile;
  String? _exerciseFileName;
  final _exerciseTitleController = TextEditingController();
  final _exerciseDescController = TextEditingController();
  String? _selectedLessonId;
  late Future<List<BasicOperatorLesson>> _lessonFuture;

  @override
  void initState() {
    super.initState();
    if (widget.contentType == 'quiz') {
      _addQuestion();
      final provider =
      Provider.of<BasicOperatorLessonProvider>(context, listen: false);
      _lessonFuture = provider.loadLessons(widget.operator, classroomId: widget.classroomId);
    }

    if (widget.contentType == 'exercise') {
      final provider =
      Provider.of<BasicOperatorLessonProvider>(context, listen: false);
      _lessonFuture = provider.loadLessons(widget.operator, classroomId: widget.classroomId);
    }
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
    setState(() => _questions.removeAt(index));
  }

  Future<void> _pickLessonFile() async {
    final result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _lessonFile = File(result.files.single.path!);
        _lessonFileName = result.files.single.name;
      });
    }
  }

  Future<void> _pickExerciseFile() async {
    final result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _exerciseFile = File(result.files.single.path!);
        _exerciseFileName = result.files.single.name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lessonProvider = Provider.of<BasicOperatorLessonProvider>(context);
    final quizProvider = Provider.of<BasicOperatorQuizProvider>(context);
    final exerciseProvider =
    Provider.of<BasicOperatorExerciseProvider>(context);
    final now = DateTime.now();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          "Create ${widget.contentType[0].toUpperCase()}${widget.contentType.substring(1)} - ${widget.operator}",
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.contentType == 'lesson') ...[
                Text("Create Lesson",
                    style: Theme.of(context).textTheme.titleLarge),
                TextFormField(
                    controller: _lessonTitleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator: (v) => v!.isEmpty ? 'Required' : null),
                TextFormField(
                    controller: _lessonDescController,
                    decoration:
                    const InputDecoration(labelText: 'Description')),
                TextFormField(
                    controller: _youtubeUrlController,
                    decoration:
                    const InputDecoration(labelText: 'YouTube URL')),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: Text(_lessonFileName ?? 'No file selected')),
                  ElevatedButton(
                      onPressed: _pickLessonFile,
                      child: const Text('Pick PDF')),
                ]),
              ],

              if (widget.contentType == 'quiz') ...[
                Text("Create Quiz",
                    style: Theme.of(context).textTheme.titleLarge),
                TextFormField(
                    controller: _quizTitleController,
                    decoration:
                    const InputDecoration(labelText: 'Quiz Title'),
                    validator: (v) => v!.isEmpty ? 'Required' : null),
                const SizedBox(height: 8),
                FutureBuilder<List<BasicOperatorLesson>>(
                  future: _lessonFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (snapshot.hasError) {
                      return Text(
                          "Error loading lessons: ${snapshot.error.toString()}");
                    }

                    final lessons = snapshot.data ?? [];
                    if (lessons.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Card(
                          color: Colors.orange[50],
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  "No lessons available",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "You must create a lesson first before creating a quiz. A quiz must be attached to a lesson.",
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: "Attach to Lesson *",
                        helperText: "A lesson must be selected to create a quiz",
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedLessonId,
                      items: lessons.map((lesson) {
                        return DropdownMenuItem<String>(
                          value: lesson.id,
                          child: Text(lesson.title),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedLessonId = val),
                      validator: (val) =>
                      val == null || val.isEmpty ? 'A lesson must be selected' : null,
                      isExpanded: true,
                    );
                  },
                ),
                const SizedBox(height: 8),
                ..._questions.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final q = entry.value;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Text("Q${idx + 1}"),
                          TextFormField(
                              controller: q["q"],
                              decoration:
                              const InputDecoration(labelText: 'Question')),
                          TextFormField(
                              controller: q["a"],
                              decoration:
                              const InputDecoration(labelText: 'Choice A')),
                          TextFormField(
                              controller: q["b"],
                              decoration:
                              const InputDecoration(labelText: 'Choice B')),
                          TextFormField(
                              controller: q["c"],
                              decoration:
                              const InputDecoration(labelText: 'Choice C')),
                          DropdownButtonFormField<String>(
                            value: q["correct"],
                            items: const [
                              DropdownMenuItem(
                                  value: "A", child: Text("Correct = A")),
                              DropdownMenuItem(
                                  value: "B", child: Text("Correct = B")),
                              DropdownMenuItem(
                                  value: "C", child: Text("Correct = C")),
                            ],
                            onChanged: (val) => q["correct"] = val!,
                          ),
                          if (_questions.length > 1)
                            TextButton.icon(
                                onPressed: () => _removeQuestion(idx),
                                icon: const Icon(Icons.delete),
                                label: const Text("Remove")),
                        ],
                      ),
                    ),
                  );
                }),
                ElevatedButton.icon(
                    onPressed: _addQuestion,
                    icon: const Icon(Icons.add),
                    label: const Text("Add Question")),
              ],

              if (widget.contentType == 'exercise') ...[
                Text("Upload Exercise",
                    style: Theme.of(context).textTheme.titleLarge),

                FutureBuilder<List<BasicOperatorLesson>>(
                  future: _lessonFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (snapshot.hasError) {
                      return Text(
                          "Error loading lessons: ${snapshot.error.toString()}");
                    }

                    final lessons = snapshot.data ?? [];
                    if (lessons.isEmpty) {
                      return const Text(
                          "No lessons available for this operator.");
                    }

                    return DropdownButtonFormField<String>(
                      decoration:
                      const InputDecoration(labelText: "Attach to Lesson"),
                      value: _selectedLessonId,
                      items: lessons.map((lesson) {
                        return DropdownMenuItem<String>(
                          value: lesson.id,
                          child: Text(lesson.title),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedLessonId = val),
                      validator: (val) =>
                      val == null ? 'Select a lesson' : null,
                    );
                  },
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller: _exerciseTitleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: _exerciseDescController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(_exerciseFileName ?? 'No file selected'),
                    ),
                    ElevatedButton(
                      onPressed: _pickExerciseFile,
                      child: const Text('Pick PDF'),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;
                  final teacherId =
                      Supabase.instance.client.auth.currentUser?.id;
                  if (teacherId == null) return;

                  if (widget.contentType == 'lesson' && _lessonFile != null) {
                    final lesson = BasicOperatorLesson(
                      operator: widget.operator,
                      title: _lessonTitleController.text,
                      description: _lessonDescController.text,
                      classroomId: widget.classroomId,
                      youtubeUrl: _youtubeUrlController.text,
                      fileUrl: '',
                      fileName: _lessonFileName,
                      storagePath: '',
                      createdAt: now,
                    );
                    await lessonProvider.createLessonWithFile(
                        lesson, _lessonFile!);
                  }

                  if (widget.contentType == 'quiz') {
                    // Ensure a lesson is selected
                    if (_selectedLessonId == null || _selectedLessonId!.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select a lesson to attach this quiz to'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final questions = _questions
                        .where((q) => q["q"].text.trim().isNotEmpty)
                        .map((q) => {
                      "q": q["q"].text,
                      "options": [
                        q["a"].text,
                        q["b"].text,
                        q["c"].text
                      ],
                      "a": q["correct"],
                    })
                        .toList();
                    
                    if (questions.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please add at least one question to the quiz'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    await quizProvider.createQuiz(
                      operator: widget.operator,
                      title: _quizTitleController.text,
                      questions: questions,
                      teacherId: teacherId,
                      classroomId: widget.classroomId,
                      lessonId: _selectedLessonId!,
                    );
                  }

                  if (widget.contentType == 'exercise' &&
                      _exerciseFile != null &&
                      _selectedLessonId != null) {
                    try {
                      await exerciseProvider.createExerciseWithFile(
                        operator: widget.operator,
                        title: _exerciseTitleController.text,
                        description: _exerciseDescController.text,
                        file: _exerciseFile!,
                        lessonId: _selectedLessonId!,
                        classroomId: widget.classroomId,
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to upload exercise: $e')),
                      );
                    }
                  }

                  if (mounted) {
                    // Navigate back to the operator action selection screen (teacher management view)
                    // Teachers should return to the management screen, not the student-facing module page
                    Navigator.pop(context, true);
                  }
                },
                child: const Text("Submit"),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

