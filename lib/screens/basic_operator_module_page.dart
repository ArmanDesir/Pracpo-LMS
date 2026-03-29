import 'package:flutter/material.dart';
import 'package:pracpro/models/basic_operator_lesson.dart';
import 'package:pracpro/models/basic_operator_quiz.dart';
import 'package:pracpro/models/basic_operator_exercise.dart';
import 'package:pracpro/modules/basic_operators/addition/game_screen.dart';
import 'package:pracpro/screens/basic_operator_lesson_view_screen.dart';
import 'package:pracpro/screens/basic_operator_quiz_screen.dart';
import 'package:pracpro/screens/basic_operator_quiz_view_screen.dart';
import 'package:pracpro/screens/create_content_screen.dart';
import 'package:pracpro/services/basic_operator_lesson_service.dart';
import 'package:pracpro/services/basic_operator_quiz_service.dart';
import 'package:pracpro/services/basic_operator_exercise_service.dart';
import 'package:pracpro/services/unlock_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BasicOperatorModulePage extends StatefulWidget {
  final String operatorName;
  final String? classroomId;

  const BasicOperatorModulePage({
    super.key,
    required this.operatorName,
    this.classroomId,
  });

  @override
  State<BasicOperatorModulePage> createState() =>
      _BasicOperatorModulePageState();
}

class _BasicOperatorModulePageState extends State<BasicOperatorModulePage>
    with SingleTickerProviderStateMixin {
  final _lessonService = BasicOperatorLessonService();
  final _quizService = BasicOperatorQuizService();
  final _exerciseService = BasicOperatorExerciseService();
  final _unlockService = UnlockService();
  late TabController _tabController;

  bool _isLoadingLessons = true;
  bool _isLoadingQuizzes = true;
  bool _isLoadingExercises = true;
  String? _lessonError;
  String? _quizError;
  String? _exerciseError;
  List<BasicOperatorLesson> _lessons = [];
  List<BasicOperatorQuiz> _quizzes = [];
  List<BasicOperatorExercise> _exercises = [];
  Set<String> _unlockedLessons = {};
  Set<String> _unlockedQuizzes = {};
  bool _isTeacher = false;
  bool _isLoadingUserRole = true;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    
    if (user == null) {
      setState(() {
        _isTeacher = false;
        _isLoadingUserRole = false;
        _tabController = TabController(length: 2, vsync: this); // Students: Lessons and Games only
      });
      _loadAllContent();
      return;
    }

    try {
      final res = await supabase
          .from('users')
          .select('user_type')
          .eq('id', user.id)
          .maybeSingle();

      final isTeacher = res?['user_type'] == 'teacher';
      
      setState(() {
        _isTeacher = isTeacher;
        _isLoadingUserRole = false;
        // Teachers: 3 tabs (Lessons, Quizzes, Games)
        // Students: 2 tabs (Lessons, Games only)
        _tabController = TabController(
          length: isTeacher ? 3 : 2,
          vsync: this,
        );
      });
      
      _loadAllContent();
    } catch (e) {
      setState(() {
        _isTeacher = false;
        _isLoadingUserRole = false;
        _tabController = TabController(length: 2, vsync: this);
      });
      _loadAllContent();
    }
  }

  Future<void> _loadAllContent() async {
    // Load content first, then unlocks (so we can initialize first unlocks if needed)
    final futures = <Future<void>>[
      _loadLessons(),
    ];
    
    // Only load quizzes for teachers
    if (_isTeacher) {
      futures.add(_loadQuizzes());
    }
    
    await Future.wait(futures);
    // Load unlocks after content is loaded
    await _loadUnlockedItems();
  }

  Future<void> _loadUnlockedItems() async {
    // Teachers don't need unlock system - they can access all content
    if (_isTeacher) {
      return;
    }
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final unlocked = await _unlockService.getUnlockedItems(
        userId: user.id,
        operator: widget.operatorName,
        classroomId: widget.classroomId,
      );

      setState(() {
        _unlockedLessons = unlocked['lessons'] ?? {};
      });

      // Initialize first unlocks if nothing is unlocked yet
      if (_unlockedLessons.isEmpty && _lessons.isNotEmpty) {
        await _unlockService.initializeFirstUnlocks(
          userId: user.id,
          operator: widget.operatorName,
          classroomId: widget.classroomId,
        );
        // Reload unlocks
        final refreshed = await _unlockService.getUnlockedItems(
          userId: user.id,
          operator: widget.operatorName,
          classroomId: widget.classroomId,
        );
        setState(() {
          _unlockedLessons = refreshed['lessons'] ?? {};
        });
      }
    } catch (e) {
      // Silently handle errors
    }
  }

  Future<void> _loadLessons() async {
    try {
      setState(() {
        _isLoadingLessons = true;
        _lessonError = null;
      });
      final lessons = await _lessonService.getLessons(
        widget.operatorName,
        classroomId: widget.classroomId,
      );
      // Sort lessons by creation date (oldest first) for proper unlock sequence
      lessons.sort((a, b) {
        final aDate = a.createdAt ?? DateTime(1970);
        final bDate = b.createdAt ?? DateTime(1970);
        return aDate.compareTo(bDate);
      });
      setState(() => _lessons = lessons);
    } catch (e) {
      setState(() => _lessonError = e.toString());
    } finally {
      setState(() => _isLoadingLessons = false);
    }
  }

  Future<void> _loadQuizzes() async {
    try {
      setState(() {
        _isLoadingQuizzes = true;
        _quizError = null;
      });
      final quizzes = await _quizService.getQuizzes(
        widget.operatorName,
        classroomId: widget.classroomId,
      );
      // Sort quizzes by creation date (oldest first) for proper unlock sequence
      quizzes.sort((a, b) {
        final aDate = a.createdAt ?? DateTime(1970);
        final bDate = b.createdAt ?? DateTime(1970);
        return aDate.compareTo(bDate);
      });
      setState(() => _quizzes = quizzes);
    } catch (e) {
      setState(() => _quizError = e.toString());
    } finally {
      setState(() => _isLoadingQuizzes = false);
    }
  }

  Future<void> _loadExercises() async {
    try {
      setState(() {
        _isLoadingExercises = true;
        _exerciseError = null;
      });
      final exercises = await _exerciseService.getExercises(
        widget.operatorName,
        classroomId: widget.classroomId,
      );

      setState(() => _exercises = exercises);
    } catch (e) {
      setState(() => _exerciseError = e.toString());
    } finally {
      setState(() => _isLoadingExercises = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingUserRole) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final title =
        '${widget.operatorName[0].toUpperCase()}${widget.operatorName.substring(1)}';

    return Scaffold(
      appBar: AppBar(
        title: Text('$title Module'),
        backgroundColor: Colors.lightBlue,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: _isTeacher
              ? const [
                  Tab(icon: Icon(Icons.menu_book), text: 'Lessons'),
                  Tab(icon: Icon(Icons.quiz), text: 'Quizzes'),
                  Tab(icon: Icon(Icons.videogame_asset), text: 'Games'),
                ]
              : const [
                  // Students: Only Lessons and Games
                  Tab(icon: Icon(Icons.menu_book), text: 'Lessons'),
                  Tab(icon: Icon(Icons.videogame_asset), text: 'Games'),
                ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _isTeacher
            ? [
                _buildLessonsTab(),
                _buildQuizzesTab(),
                GameScreen(operatorKey: widget.operatorName, classroomId: widget.classroomId),
              ]
            : [
                // Students: Only Lessons and Games
                _buildLessonsTab(),
                GameScreen(operatorKey: widget.operatorName, classroomId: widget.classroomId),
              ],
      ),
    );
  }

  Widget _buildLessonsTab() {
    if (_isLoadingLessons) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_lessonError != null) {
      return Center(child: Text('Error: $_lessonError'));
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadLessons();
        await _loadUnlockedItems();
      },
          child: Column(
            children: [
              Expanded(
                child: _lessons.isEmpty
                    ? const Center(child: Text('No lessons available yet.'))
                    : ListView.builder(
        itemCount: _lessons.length,
        itemBuilder: (context, index) {
          final lesson = _lessons[index];
          // Teachers should see all lessons as unlocked (no lock system for teachers)
          // Students: Check unlock status from database
          // First lesson (oldest by creation date) should be unlocked by default via initializeFirstUnlocks
          // Lessons are sorted oldest first, so index 0 is the oldest
          final isUnlocked = _isTeacher || lesson.id == null || _unlockedLessons.contains(lesson.id);
          
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: isUnlocked ? Colors.orange[50] : Colors.grey[200],
            child: ListTile(
              leading: Icon(
                isUnlocked ? Icons.book : Icons.lock,
                color: isUnlocked ? Colors.blueAccent : Colors.grey,
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                lesson.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isUnlocked ? Colors.black : Colors.grey[600],
                      ),
                    ),
                  ),
                  if (!isUnlocked && !_isTeacher)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '🔒 Locked',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              subtitle: Text(
                isUnlocked 
                    ? (lesson.description ?? 'No description provided')
                    : 'Complete quiz 1 with 80% or above (or 3 attempts) to unlock',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isUnlocked ? null : Colors.grey[500],
                ),
              ),
              trailing: Icon(
                isUnlocked ? Icons.arrow_forward_ios_rounded : Icons.lock_outline,
                color: isUnlocked ? null : Colors.grey,
              ),
              onTap: isUnlocked ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BasicOperatorLessonViewScreen(
                      lesson: lesson,
                    ),
                  ),
                ).then((_) {
                  if (!_isTeacher) {
                    _loadUnlockedItems();
                  }
                });
              } : () {
                if (!_isTeacher) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('🔒 This lesson is locked. Complete previous content to unlock it.'),
                      backgroundColor: Colors.orange,
                      action: SnackBarAction(
                        label: 'OK',
                        textColor: Colors.white,
                        onPressed: () {},
                      ),
                    ),
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

  Widget _buildQuizzesTab() {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (_isLoadingQuizzes) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_quizError != null) {
      return Center(child: Text('Error: $_quizError'));
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadQuizzes();
        await _loadUnlockedItems();
      },
      child: _quizzes.isEmpty
          ? const Center(child: Text('No quizzes available yet.'))
          : ListView.builder(
              itemCount: _quizzes.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final quiz = _quizzes[index];
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: Colors.purple[50],
                  child: ListTile(
                    leading: const Icon(
                      Icons.quiz,
                      color: Colors.purpleAccent,
                    ),
                    title: Text(
                      quiz.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                    ),
                    ),
                    subtitle: Text('${quiz.questions.length} questions'),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded),
                    onTap: user != null ? () {
                        // Teachers can only view quizzes, not take them
                        if (_isTeacher) {
                          // Always navigate to view screen for teachers, even if quiz has no questions
                          // The view screen will handle showing appropriate message
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BasicOperatorQuizViewScreen(
                                quiz: quiz,
                              ),
                            ),
                          );
                        } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BasicOperatorQuizScreen(
                              quiz: quiz,
                              userId: user.id,
                            ),
                          ),
                      ).then((_) async {
                        await Future.wait([
                          _loadQuizzes(),
                          _loadUnlockedItems(),
                          _loadLessons(), // Reload lessons to reflect unlock status
                        ]);
                          }).catchError((error) {
                            // Handle navigation errors
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error opening quiz: $error'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                      });
                        }
                    } : () {
                      // Show message if user is not logged in
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please log in to view quizzes'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  Widget _buildExercisesTab() {
    if (_isLoadingExercises) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_exerciseError != null) {
      return Center(child: Text('Error: $_exerciseError'));
    }

    return RefreshIndicator(
      onRefresh: _loadExercises,
      child: _exercises.isEmpty
          ? const Center(child: Text('No exercises available yet.'))
          : ListView.builder(
              itemCount: _exercises.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final exercise = _exercises[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: Colors.green[50],
                  child: ListTile(
                    leading: const Icon(Icons.fitness_center, color: Colors.greenAccent),
                    title: Text(
                      exercise.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      exercise.description ?? 'No description provided',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: exercise.fileUrl != null
                        ? const Icon(Icons.attachment, color: Colors.green)
                        : const Icon(Icons.arrow_forward_ios_rounded),
                    onTap: () {
                      if (exercise.fileUrl != null) {

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Opening: ${exercise.fileName ?? exercise.title}'),
                            action: SnackBarAction(
                              label: 'Open',
                              onPressed: () {

                              },
                            ),
                          ),
                        );
                      }
              },
            ),
          );
        },
      ),
    );
  }
}
