import 'package:flutter/material.dart';
import 'package:pracpro/models/classroom.dart';
import 'package:pracpro/models/content.dart';
import 'package:pracpro/models/user.dart' as app_model;
import 'package:pracpro/providers/classroom_provider.dart';
import 'package:pracpro/screens/create_lesson_screen.dart';
import 'package:pracpro/screens/lesson_detail_screen.dart';
import 'package:pracpro/screens/basic_operator_module_page.dart';
import 'package:pracpro/screens/operator_action_selection_screen.dart';
import 'package:pracpro/screens/student_detail_screen.dart';
import 'package:pracpro/services/content_service.dart';
import 'package:pracpro/services/exercise_service.dart';
import 'package:pracpro/services/basic_operator_lesson_service.dart';
import 'package:pracpro/services/basic_operator_quiz_service.dart';
import 'package:pracpro/models/basic_operator_lesson.dart';
import 'package:pracpro/models/basic_operator_quiz.dart';
import 'package:pracpro/screens/basic_operator_lesson_view_screen.dart';
import 'package:pracpro/screens/basic_operator_quiz_view_screen.dart';
import 'package:pracpro/widgets/operator_button.dart';
import 'package:pracpro/widgets/content_card.dart';
import 'package:pracpro/widgets/loading_wrapper.dart';
import 'package:pracpro/widgets/empty_state.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClassroomDetailsScreen extends StatefulWidget {
  final Classroom classroom;
  const ClassroomDetailsScreen({super.key, required this.classroom});

  @override
  State<ClassroomDetailsScreen> createState() => _ClassroomDetailsScreenState();
}

class _ClassroomDetailsScreenState extends State<ClassroomDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ContentService _contentService = ContentService();
  List<Content> _contentList = [];
  bool _isLoadingContent = false;
  final ExerciseService _exerciseService = ExerciseService();
  
  // For lessons and quizzes view
  final BasicOperatorLessonService _lessonService = BasicOperatorLessonService();
  final BasicOperatorQuizService _quizService = BasicOperatorQuizService();
  bool _isLoadingLessonsQuizzes = false;
  Map<String, List<BasicOperatorLesson>> _lessonsByOperator = {};
  Map<String, List<BasicOperatorQuiz>> _quizzesByOperator = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verifyClassroomOwnership();
      Provider.of<ClassroomProvider>(
        context,
        listen: false,
      ).loadClassroomDetails(widget.classroom.id);

      _loadContent();
      _loadLessonsAndQuizzes();
    });
  }

  Future<void> _verifyClassroomOwnership() async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in to access this page')),
          );
        }
        return;
      }

      // Verify that the current user is the owner of this classroom
      if (widget.classroom.teacherId != currentUser.id) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You do not have permission to access this classroom'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error verifying access: $e')),
        );
      }
    }
  }

  Future<void> _loadContent() async {
    setState(() => _isLoadingContent = true);
    try {
      _contentList = await _contentService.getContentByClassroom(
        widget.classroom.id,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load content: $e')));
    } finally {
      if (mounted) setState(() => _isLoadingContent = false);
    }
  }

  Future<void> _loadLessonsAndQuizzes() async {
    // Verify ownership before loading data
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null || widget.classroom.teacherId != currentUser.id) {
      return; // Silently return if user doesn't own the classroom
    }

    setState(() => _isLoadingLessonsQuizzes = true);
    try {
      final operators = ['addition', 'subtraction', 'multiplication', 'division'];
      final lessonsMap = <String, List<BasicOperatorLesson>>{};
      final quizzesMap = <String, List<BasicOperatorQuiz>>{};

      for (final operator in operators) {
        try {
          // Only load lessons and quizzes for this specific classroom
          final lessons = await _lessonService.getLessons(
            operator,
            classroomId: widget.classroom.id,
          );
          final quizzes = await _quizService.getQuizzes(
            operator,
            classroomId: widget.classroom.id,
          );
          
          if (lessons.isNotEmpty) {
            lessonsMap[operator] = lessons;
          }
          if (quizzes.isNotEmpty) {
            quizzesMap[operator] = quizzes;
          }
        } catch (e) {
          // Continue with other operators if one fails
        }
      }

      if (mounted) {
        setState(() {
          _lessonsByOperator = lessonsMap;
          _quizzesByOperator = quizzesMap;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load lessons and quizzes: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoadingLessonsQuizzes = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ClassroomProvider>(
      builder: (context, provider, _) {
        final classroom = provider.currentClassroom ?? widget.classroom;
        return Scaffold(
          appBar: AppBar(
            title: Text(classroom.name),
            backgroundColor: Colors.grey[100],
            elevation: 0,
            foregroundColor: Colors.black,
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.black,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: 'Student List'),
                Tab(text: 'Basic Operator'),
                Tab(text: 'Lessons & Quizzes'),
              ],
            ),
          ),
          body: LoadingWrapper(
            isLoading: provider.isLoading,
            child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildStudentsTab(classroom, provider),
                      _buildBasicOperatorTab(classroom),
                      _buildLessonsQuizzesTab(classroom),
                    ],
            ),
                  ),
        );
      },
    );
  }

  Widget _buildStudentsTab(Classroom classroom, ClassroomProvider provider) {
    final acceptedStudents = provider.acceptedStudents
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    final pendingStudents = provider.pendingStudents
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                'Accepted Students (${acceptedStudents.length})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          acceptedStudents.isEmpty
              ? const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No students have joined yet.'),
            ),
          )
              : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: acceptedStudents.length,
            itemBuilder: (context, idx) {
              final student = acceptedStudents[idx];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color.alphaBlend(
                      Colors.green.withAlpha((0.1 * 255).toInt()),
                      Colors.white,
                    ),
                    child: Text(
                      student.name[0].toUpperCase(),
                      style: TextStyle(color: Colors.green[700]),
                    ),
                  ),
                  title: Text(student.name),
                  subtitle: Text(student.email ?? 'No email'),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                    onPressed: () => _showRemoveStudentDialog(classroom.id, student),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudentDetailScreen(
                          student: student,
                          classroomId: classroom.id,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),

          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(Icons.pending, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                'Pending Requests (${pendingStudents.length})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          pendingStudents.isEmpty
              ? const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No pending requests.'),
            ),
          )
              : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pendingStudents.length,
            itemBuilder: (context, idx) {
              final student = pendingStudents[idx];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color.alphaBlend(
                      Colors.orange.withAlpha((0.1 * 255).toInt()),
                      Colors.white,
                    ),
                    child: Text(
                      student.name[0].toUpperCase(),
                      style: TextStyle(color: Colors.orange[700]),
                    ),
                  ),
                  title: Text(student.name),
                  subtitle: Text(student.email ?? 'No email'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        onPressed: () async {
                          await provider.acceptStudent(
                            classroomId: classroom.id,
                            studentId: student.id,
                          );
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${student.name} accepted!')),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () async {
                          await provider.rejectStudent(classroom.id, student.id);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${student.name} rejected.')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBasicOperatorTab(Classroom classroom) {
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OperatorButton(
            label: 'ADDITION',
            symbol: '+',
            color: Colors.red,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OperatorActionSelectionScreen(
                    operator: 'addition',
                    classroomId: classroom.id,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          OperatorButton(
            label: 'SUBTRACTION',
            symbol: '−',
            color: Colors.red,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OperatorActionSelectionScreen(
                    operator: 'subtraction',
                    classroomId: classroom.id,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          OperatorButton(
            label: 'MULTIPLICATION',
            symbol: '×',
            color: Colors.red,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OperatorActionSelectionScreen(
                    operator: 'multiplication',
                    classroomId: classroom.id,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          OperatorButton(
            label: 'DIVISION',
            symbol: '÷',
            color: Colors.red,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OperatorActionSelectionScreen(
                    operator: 'division',
                    classroomId: classroom.id,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLessonsQuizzesTab(Classroom classroom) {
    if (_isLoadingLessonsQuizzes) {
      return const Center(child: CircularProgressIndicator());
    }

    final hasContent = _lessonsByOperator.isNotEmpty || _quizzesByOperator.isNotEmpty;
    
    if (!hasContent) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.book_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No lessons or quizzes yet',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                'Create lessons and quizzes for this classroom',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final allOperators = <String>{};
    allOperators.addAll(_lessonsByOperator.keys);
    allOperators.addAll(_quizzesByOperator.keys);
    final sortedOperators = allOperators.toList()..sort();

    return RefreshIndicator(
      onRefresh: _loadLessonsAndQuizzes,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: sortedOperators.map((operator) {
            final lessons = _lessonsByOperator[operator] ?? [];
            final quizzes = _quizzesByOperator[operator] ?? [];
            
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      operator.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (lessons.isNotEmpty) ...[
                      const Text(
                        'Lessons',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...lessons.map((lesson) => Card(
                        color: Colors.blue[50],
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.book, color: Colors.blue),
                          title: Text(lesson.title),
                          subtitle: Text(
                            lesson.description ?? 'No description',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BasicOperatorLessonViewScreen(
                                  lesson: lesson,
                                ),
                              ),
                            );
                          },
                        ),
                      )),
                      const SizedBox(height: 16),
                    ],
                    if (quizzes.isNotEmpty) ...[
                      const Text(
                        'Quizzes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...quizzes.map((quiz) => Card(
                        color: Colors.purple[50],
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.quiz, color: Colors.purple),
                          title: Text(quiz.title),
                          subtitle: Text(
                            '${quiz.questions.length} question(s)',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            // Navigate to quiz view screen for teachers (view-only mode)
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BasicOperatorQuizViewScreen(
                                  quiz: quiz,
                                ),
                              ),
                            );
                          },
                        ),
                      )),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildContentTab(Classroom classroom) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Classroom Content',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          ContentCard(
            title: 'Lessons',
            subtitle: 'Create and manage lessons',
            icon: Icons.book,
            color: Colors.blue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateLessonScreen(
                    classroomId: classroom.id,
                  ),
                ),
              ).then((created) {
                if (created == true) {
                  _loadContent();
                }
              });
            },
          ),
          const SizedBox(height: 12),
          ContentCard(
            title: 'Exercises',
            subtitle: 'Upload practice exercises and worksheets',
            icon: Icons.fitness_center,
            color: Colors.orange,
            onTap: () => _showUploadDialog('exercise', ContentType.exercise),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text(
                'Recent Content',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              if (_isLoadingContent)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 12),
          LoadingWrapper(
            isLoading: _isLoadingContent,
            child: _contentList.isEmpty
                ? const EmptyState(
                    icon: Icons.folder_outlined,
                    message: 'No content uploaded yet.',
              )
              : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _contentList.length,
            itemBuilder: (context, index) {
              final content = _contentList[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color.alphaBlend(
                      _getContentColor(content.type).withAlpha((0.1 * 255).toInt()),
                      Colors.white,
                    ),
                    child: Icon(
                      _getContentIcon(content.type),
                      color: _getContentColor(content.type),
                    ),
                  ),
                  title: Text(content.title),
                  subtitle: Text(
                    '${content.description ?? ''}\n'
                        '${_formatFileSize(content.fileSize ?? 0)} • ${_formatDate(content.createdAt)}',
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _showDeleteContentDialog(content),
                  ),
                  onTap: () {
                    if (content.type == ContentType.lesson) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LessonDetailScreen(content: content),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Opening for ${content.type} not yet implemented")),
                      );
                    }
                  },
                ),
              );
            },
                  ),
          ),
        ],
      ),
    );
  }

  void _showRemoveStudentDialog(String classroomId, app_model.User student) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Remove Student'),
            content: Text(
              'Are you sure you want to remove ${student.name} from this classroom?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final provider = Provider.of<ClassroomProvider>(
                    context,
                    listen: false,
                  );
                  await provider.removeStudent(classroomId, student.id);
                  if (!mounted) return;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${student.name} removed from classroom.')),
                      );
                    }
                  });
                },
                child: const Text(
                  'Remove',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  void _showUploadDialog(String contentType, ContentType type) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Add ${contentType[0].toUpperCase() + contentType.substring(1)}',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text("Upload New File"),
              onPressed: () {
                Navigator.pop(context);
                _showUploadForm(type, contentType, titleController, descController);
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.content_copy),
              label: const Text("Use Existing Content"),
              onPressed: () {
                Navigator.pop(context);
                _showSelectExistingContent(type);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showConfirmDialog(ContentType type, String title, String description, File file,) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Upload'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Title: $title'),
            const SizedBox(height: 8),
            Text('Description: $description'),
            const SizedBox(height: 8),
            Text('File: ${file.path.split('/').last}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _uploadPDFFile(type, title, description, file);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadPDFFile(ContentType type, String title, String description, File file,) async {
    try {
      if (type == ContentType.exercise) {
        await _exerciseService.createExercise(
          classroomId: widget.classroom.id,
          userId: Supabase.instance.client.auth.currentUser!.id,
          title: title,
          description: description,
          pdfFile: file,
        );
      } else {
        await _contentService.createContent(
          classroomId: widget.classroom.id,
          title: title,
          description: description,
          type: type,
          pdfFile: file,
        );
      }

      await _loadContent();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$title uploaded successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSelectExistingContent(ContentType type) async {
    try {
      final allContents = await _contentService.getAllContents(type: type);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Select Existing Content"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: allContents.length,
              itemBuilder: (context, index) {
                final content = allContents[index];
                return ListTile(
                  leading: Icon(_getContentIcon(content.type)),
                  title: Text(content.title),
                  subtitle: Text(content.description ?? ''),
                  onTap: () async {
                    Navigator.pop(context);
                    await _contentService.attachExistingContent(
                      classroomId: widget.classroom.id,
                      contentId: content.id,
                    );
                    await _loadContent();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${content.title} added to this classroom!')),
                    );
                  },
                );
              },
            ),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch existing content: $e')),
      );
    }
  }

  void _showUploadForm(ContentType type, String contentType, TextEditingController titleController, TextEditingController descController,) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Upload ${contentType[0].toUpperCase() + contentType.substring(1)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title *',
                hintText: 'Enter content title',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description *',
                hintText: 'Enter content description',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                if (titleController.text.trim().isEmpty ||
                    descController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Title and description are required.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final result = await _contentService.pickPDFFile();
                if (result != null && result.files.isNotEmpty) {
                  final file = File(result.files.first.path!);
                  Navigator.pop(context);
                  _showConfirmDialog(
                    type,
                    titleController.text.trim(),
                    descController.text.trim(),
                    file,
                  );
                }
              },
              icon: const Icon(Icons.upload_file),
              label: const Text('Choose PDF File'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showDeleteContentDialog(Content content) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final messenger = ScaffoldMessenger.of(context);

        return AlertDialog(
          title: const Text('Delete Content'),
          content: Text('Are you sure you want to delete "${content.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await _contentService.deleteContent(
                    contentId: content.id,
                    type: content.type,
                  );
                  await _loadContent();
                  Navigator.pop(dialogContext);

                  messenger.showSnackBar(
                    SnackBar(content: Text('${content.title} deleted.')),
                  );
                } catch (e) {
                  Navigator.pop(dialogContext);

                  messenger.showSnackBar(
                    SnackBar(content: Text('Failed to delete: $e')),
                  );
                }
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getContentColor(ContentType type) {
    switch (type) {
      case ContentType.lesson:
        return Colors.blue;
      case ContentType.quiz:
        return Colors.purple;
      case ContentType.exercise:
        return Colors.orange;
    }
  }

  IconData _getContentIcon(ContentType type) {
    switch (type) {
      case ContentType.lesson:
        return Icons.book;
      case ContentType.quiz:
        return Icons.quiz;
      case ContentType.exercise:
        return Icons.fitness_center;
    }
  }

  String _formatFileSize(int size) {
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(2)} KB';
    } else {
      return '${(size / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showBasicOperatorDialog(Classroom classroom) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Basic Operators'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add, color: Colors.lightBlue),
              title: const Text('Addition'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BasicOperatorModulePage(
                      operatorName: 'addition',
                      classroomId: classroom.id,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.remove, color: Colors.redAccent),
              title: const Text('Subtraction'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BasicOperatorModulePage(
                      operatorName: 'subtraction',
                      classroomId: classroom.id,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.close, color: Colors.green),
              title: const Text('Multiplication'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BasicOperatorModulePage(
                      operatorName: 'multiplication',
                      classroomId: classroom.id,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.percent, color: Colors.purple),
              title: const Text('Division'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BasicOperatorModulePage(
                      operatorName: 'division',
                      classroomId: classroom.id,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
