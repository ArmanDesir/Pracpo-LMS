import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pracpro/models/activity_progress.dart';
import 'package:pracpro/models/classroom.dart';
import 'package:pracpro/models/user.dart' as local;
import 'package:pracpro/providers/auth_provider.dart';
import 'package:pracpro/providers/classroom_provider.dart';
import 'package:pracpro/screens/join_classroom_screen.dart';
import 'package:pracpro/screens/student_classroom_screen.dart';
import 'package:pracpro/services/student_quiz_progress_service.dart';
import 'package:pracpro/widgets/quiz_progress_table.dart';
import 'package:pracpro/widgets/game_progress_table.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _completedLessons = 0;
  List<ActivityProgress> _recentActivities = [];
  
  bool _loadingProgress = false;
  bool _loadingClassroom = true;
  List<QuizProgressData> _quizProgress = [];
  List<QuizProgressData> _gameProgress = [];
  String? _classroomId;
  String? _selectedOperator;
  List<Map<String, String>> _classrooms = []; // List of {id, name} for dropdown

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
    _loadClassroomId();
  }
  
  Future<void> _loadClassroomId() async {
    setState(() {
      _loadingClassroom = true;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      if (user == null) return;
      
      final supabase = Supabase.instance.client;
      
      // Load all classrooms with their names
      final classroomsResponse = await supabase
          .from('user_classrooms')
          .select('classroom_id, classrooms(id, name)')
          .eq('user_id', user.id)
          .eq('status', 'accepted')
          .order('joined_at', ascending: false);
      
      setState(() {
        final previousClassroomId = _classroomId;
        _classrooms = [];
        if (classroomsResponse.isNotEmpty) {
          for (var item in classroomsResponse) {
            final classroomData = item['classrooms'];
            if (classroomData != null) {
              _classrooms.add({
                'id': classroomData['id'] as String,
                'name': classroomData['name'] as String? ?? 'Unknown Classroom',
              });
            }
          }
          // Keep the previous selection if it's still valid, otherwise use the first one
          if (_classrooms.isNotEmpty) {
            final isPreviousClassroomValid = previousClassroomId != null &&
                _classrooms.any((c) => c['id'] == previousClassroomId);
            if (isPreviousClassroomValid) {
              _classroomId = previousClassroomId;
            } else {
              _classroomId = _classrooms.first['id'];
            }
          } else {
            _classroomId = null;
          }
        } else {
          _classroomId = null;
        }
        _loadingClassroom = false;
      });
      
      
      if (_classroomId != null) {
        _loadStudentProgress('addition');
      }
    } catch (e) {
      setState(() {
        _loadingClassroom = false;
      });
    }
  }

  Future<void> _loadStudentProgress(String? operator) async {
    if (_classroomId == null) {
      return;
    }
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user == null) return;
    
    setState(() {
      _loadingProgress = true;
      _selectedOperator = operator;
    });
    
    try {
      final service = StudentQuizProgressService();
      List<QuizProgressData> progress;
      
      if (operator == null) {
        progress = await service.getStudentAllProgress(
          studentId: user.id,
          classroomId: _classroomId!,
        );
      } else {
        progress = await service.getStudentQuizProgress(
          studentId: user.id,
          operator: operator,
          classroomId: _classroomId!,
        );
      }
      
      final quizzes = progress.where((p) => !p.isGame).toList();
      final games = progress.where((p) => p.isGame).toList();
        
      setState(() {
        _quizProgress = quizzes;
        _gameProgress = games;
        _loadingProgress = false;
      });
    } catch (e, stackTrace) {
      setState(() {
        _loadingProgress = false;
      });
    }
  }

  Widget _buildOperatorFilterButton(String? operator, String symbol, Color color) {
    final isSelected = _selectedOperator == operator;

    return ElevatedButton(
      onPressed: () => _loadStudentProgress(operator),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : Colors.grey[300],
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: isSelected ? 4 : 1,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            symbol,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            operator!.toUpperCase(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyProgress() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up, color: Colors.blue, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'My Progress',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (_classrooms.length > 1) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.school, color: Colors.blue[700], size: 18),
                  const SizedBox(width: 6),
                  const Text(
                    'Classroom:',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: DropdownButton<String>(
                        value: _classroomId,
                        isDense: true,
                        isExpanded: true,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.blue, size: 20),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                        items: _classrooms.map((classroom) {
                          return DropdownMenuItem<String>(
                            value: classroom['id'],
                            child: Text(
                              classroom['name']!,
                              style: const TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newClassroomId) {
                          if (newClassroomId != null && newClassroomId != _classroomId) {
                            setState(() {
                              _classroomId = newClassroomId;
                            });
                            _loadStudentProgress(_selectedOperator ?? 'addition');
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            
            if (_loadingClassroom)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_classroomId == null)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Not enrolled in any classroom yet.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else ...[
                /// 🔽 BASIC OPERATOR DROPDOWN
                Row(
                  children: [
                    Icon(Icons.calculate, color: Colors.blue[700], size: 18),
                    const SizedBox(width: 6),
                    const Text(
                      'Operator:',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedOperator ?? 'addition',
                          isDense: true,
                          isExpanded: true,
                          underline: const SizedBox(),
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: Colors.blue,
                            size: 20,
                          ),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'addition',
                              child: Text('Addition "+"'),
                            ),
                            DropdownMenuItem(
                              value: 'subtraction',
                              child: Text('Subtraction "-"'),
                            ),
                            DropdownMenuItem(
                              value: 'multiplication',
                              child: Text('Multiplication "×"'),
                            ),
                            DropdownMenuItem(
                              value: 'division',
                              child: Text('Division "÷"'),
                            ),
                          ],
                          onChanged: (String? value) {
                            if (value == null) return;
                            setState(() {
                              _selectedOperator = value;
                            });
                            _loadStudentProgress(value);
                          },
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),


                if (_loadingProgress)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else ...[
                if (_quizProgress.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.quiz, color: Colors.deepPurple, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Quizzes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  QuizProgressTable(quizData: _quizProgress),
                  const SizedBox(height: 24),
                ],
                
                if (_gameProgress.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.sports_esports, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Games',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GameProgressTable(gameData: _gameProgress),
                ],
                
                if (_quizProgress.isEmpty && _gameProgress.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No progress yet. Start learning!',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _refreshDashboard() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user == null) return;

    final classroomProvider = Provider.of<ClassroomProvider>(context, listen: false);
    await classroomProvider.loadStudentClassrooms(user.id);
    await _loadRecentActivity(user.id);
    
    // Reload classrooms for dropdown
    await _loadClassroomId();

    final currentClassroom = classroomProvider.studentClassrooms.isNotEmpty
        ? classroomProvider.studentClassrooms.first
        : null;

    if (currentClassroom != null) {
      final completed = await classroomProvider.getCompletedLessonsCount(
        studentId: user.id,
        classroomId: currentClassroom.id,
      );
      if (mounted) {
        setState(() {
          _completedLessons = completed;
        });
        // Refresh My Progress if classroom is still selected
        if (_classroomId != null) {
          await _loadStudentProgress(_selectedOperator ?? 'addition');
        }
      }
    }
  }

  Future<void> _initializeDashboard() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user == null) return;

    final classroomProvider = Provider.of<ClassroomProvider>(context, listen: false);

    await classroomProvider.loadStudentClassrooms(user.id);
    await _loadRecentActivity(user.id);

    final currentClassroom = classroomProvider.studentClassrooms.isNotEmpty
        ? classroomProvider.studentClassrooms.first
        : null;

    if (currentClassroom != null) {
      final completed = await classroomProvider.getCompletedLessonsCount(
        studentId: user.id,
        classroomId: currentClassroom.id,
      );
      if (mounted) setState(() => _completedLessons = completed);
    }
  }

  Future<void> _loadRecentActivity(String userId) async {
    try {
      final supabase = Supabase.instance.client;
      final List<ActivityProgress> allActivities = [];

      final classroomsResponse = await supabase
          .from('user_classrooms')
          .select('classroom_id')
          .eq('user_id', userId)
          .eq('status', 'accepted');

      final classroomIds = (classroomsResponse as List)
          .map((c) => c['classroom_id'] as String)
          .toList();

      // Read from unified activity_progress table
      try {
        var query = supabase
          .from('activity_progress')
          .select('*')
          .eq('user_id', userId);

        // Filter by classroom if we have classrooms
        if (classroomIds.isNotEmpty) {
          query = query.inFilter('classroom_id', classroomIds);
        }

        final activityResponse = await query.order('created_at', ascending: false).limit(20);
        final activityData = (activityResponse as List).cast<Map<String, dynamic>>();
        
        // Map to ActivityProgress model
        for (final progress in activityData) {
          final entityType = progress['entity_type']?.toString() ?? '';
          final entityTitle = progress['entity_title']?.toString() ?? 'Unknown';
          final difficulty = progress['difficulty']?.toString() ?? '';
          final operator = progress['operator']?.toString() ?? '';
          
          // Format stage field (operator|difficulty|total_items for games, operator|total_items for quizzes)
          String stage = operator;
          final totalItems = progress['total_items'] as int? ?? 0;
          if (entityType == 'game' && difficulty.isNotEmpty) {
            // Store as operator|difficulty|total_items so we can parse total_items for display
            stage = '$operator|$difficulty|$totalItems';
          } else if (entityType == 'quiz') {
            stage = '$operator|$totalItems';
          }

          // Format title with difficulty for games
          String displayTitle = entityTitle;
          if (entityType == 'game' && difficulty.isNotEmpty) {
            final difficultyCapitalized = difficulty.substring(0, 1).toUpperCase() + difficulty.substring(1);
            displayTitle = '$entityTitle ($difficultyCapitalized)';
          }

          allActivities.add(ActivityProgress(
            source: 'activity_progress',
            sourceId: progress['id']?.toString() ?? '',
            userId: userId,
            userName: null,
            entityType: entityType,
            entityId: progress['entity_id']?.toString(),
            entityTitle: displayTitle,
            stage: stage,
            score: progress['score'] as int?,
            attempt: progress['attempt_number'] as int?,
            highestScore: progress['score'] as int?, // Use score as highest for now
            tries: progress['attempt_number'] as int?,
            status: progress['status']?.toString(),
            classroomId: progress['classroom_id']?.toString() ?? (classroomIds.isNotEmpty ? classroomIds.first : ''),
            createdAt: DateTime.parse(progress['created_at']?.toString() ?? DateTime.now().toIso8601String()),
          ));
        }
      } catch (e) {
        // Ignore errors, just continue
      }

      // Sort by creation date (most recent first) and limit to 20
      allActivities.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final limitedActivities = allActivities.take(20).toList();

      if (mounted) {
      setState(() {
          _recentActivities = limitedActivities;
      });
      }
    } catch (e) {
      // Ignore errors
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final classroomProvider = Provider.of<ClassroomProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Student Dashboard'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authProvider.signOutAndRedirect(context),
          ),
        ],
      ),
      body: classroomProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _refreshDashboard,
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMyProgress(),
            const SizedBox(height: 24),
            _buildQuickStats(classroomProvider),
            const SizedBox(height: 24),
            _buildClassroomStatus(classroomProvider, user),
            const SizedBox(height: 24),
            _buildQuickActions(classroomProvider, user),
            const SizedBox(height: 24),
            _buildRecentActivity(),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner(String name) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.blue, Colors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, $name!',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Keep up the great work and continue learning!',
            style: TextStyle(fontSize: 15, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(ClassroomProvider classroomProvider) {
    final joinedClassrooms = classroomProvider.studentClassrooms.length;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatCard(joinedClassrooms.toString(), 'Classrooms', Colors.blue),
        _buildStatCard(_completedLessons.toString(), 'Completed', Colors.orange),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Container(
      width: 120,
      height: 80,
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 13, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildClassroomStatus(
      ClassroomProvider classroomProvider, local.User? user) {
    final classrooms = classroomProvider.studentClassrooms;

    if (classroomProvider.isLoading) {
      return _buildLoadingClassroomCard();
    }

    if (classrooms.isEmpty || user == null) {
      return _buildNoClassroomCard();
    }

    final activeClassrooms =
    classrooms.where((c) => c.studentIds.contains(user.id)).toList();

    if (activeClassrooms.isEmpty) {
      final pending = classrooms.firstWhere(
            (c) => c.pendingStudentIds.contains(user.id),
        orElse: () => classrooms.first,
      );
      return _buildPendingStatusCard(pending);
    }

    final classroom = activeClassrooms.first;
    return _buildActiveClassroomCard(classroom);
  }

  Widget _buildNoClassroomCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.class_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            const Text(
              'No classrooms joined yet',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            const Text(
              'Join a classroom to begin your learning journey.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const JoinClassroomScreen()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Join Classroom'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingClassroomCard() => const Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: CircularProgressIndicator(),
      ));

  Widget _buildPendingStatusCard(Classroom classroom) {
    return Card(
      color: Colors.orange[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.hourglass_empty, size: 46, color: Colors.orange[600]),
            const SizedBox(height: 12),
            Text(
              'Pending Approval for "${classroom.name}"',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.orange[700],
              ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              backgroundColor: Colors.orange[200],
              valueColor:
              AlwaysStoppedAnimation<Color>(Colors.orange[600]!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveClassroomCard(Classroom classroom) {
    return Card(
      color: Colors.green[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.school_rounded, color: Colors.green[700], size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        classroom.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text('Code: ${classroom.code ?? ''}',
                          style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          StudentClassroomScreen(classroom: classroom),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Enter Classroom'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(
      ClassroomProvider classroomProvider, local.User? user) {
    final classrooms = classroomProvider.studentClassrooms;
    final hasActiveClassrooms =
        user != null && classrooms.any((c) => c.studentIds.contains(user.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (hasActiveClassrooms && user != null)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              leading: const Icon(Icons.book_rounded, color: Colors.blue),
              title: const Text('View Classrooms'),
              subtitle: const Text('Choose a classroom to enter'),
              onTap: () {
                _showClassroomPicker(context, classrooms, user);
              },
            ),
          ),
        if (hasActiveClassrooms) const SizedBox(height: 8),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            leading: const Icon(Icons.add_circle_rounded, color: Colors.blue),
            title: Text(hasActiveClassrooms ? 'Join Another Classroom' : 'Join Classroom'),
            subtitle: const Text('Enter a classroom code to join'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const JoinClassroomScreen()),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showClassroomPicker(
      BuildContext context, List<Classroom> classrooms, local.User user) {
    final joined =
    classrooms.where((c) => c.studentIds.contains(user.id)).toList();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Classrooms',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            if (joined.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('No classrooms joined yet'),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: joined.length,
                  itemBuilder: (context, index) {
                    final classroom = joined[index];
                    return ListTile(
                      leading: const Icon(Icons.class_),
                      title: Text(classroom.name),
                      subtitle: Text('Code: ${classroom.code ?? ''}'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                StudentClassroomScreen(classroom: classroom),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.add_circle, color: Colors.blue),
              title: const Text('Join Another Classroom'),
              subtitle: const Text('Enter a classroom code to join'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const JoinClassroomScreen()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentActivity() {
    final filtered = _recentActivities
        .where((a) {
          return a.entityType.toLowerCase() == 'quiz' || 
                 a.entityType.toLowerCase() == 'game';
        })
        .toList();

    final recent = filtered.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (filtered.isNotEmpty)
              TextButton(
                onPressed: () => _showAllActivities(filtered),
                child: const Text(
                  'See More',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        if (recent.isEmpty)
          Card(
            color: Colors.grey[50],
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.history, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'No recent activity',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Your progress will appear here once you start learning.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: recent.map((activity) {
              String scoreText = '';
              if (activity.score != null) {
                if (activity.entityType.toLowerCase() == 'quiz') {
                  // Parse total_items from stage field (format: "operator|total_items")
                  int totalQuestions = 0;
                  if (activity.stage.contains('|')) {
                    final parts = activity.stage.split('|');
                    if (parts.length >= 2) {
                      totalQuestions = int.tryParse(parts[1]) ?? 0;
                    }
                  }
                  if (totalQuestions > 0) {
                    scoreText = '${activity.score}/$totalQuestions';
                  } else {
                    scoreText = '${activity.score}%';
                  }
                } else {
                  // For games, parse total_items from stage (format: "operator|difficulty|total_items")
                  int totalQuestions = 0;
                  if (activity.stage.contains('|')) {
                    final parts = activity.stage.split('|');
                    // For games: operator|difficulty|total_items (3 parts)
                    // For quizzes: operator|total_items (2 parts)
                    if (parts.length >= 3) {
                      // Game format: operator|difficulty|total_items
                      totalQuestions = int.tryParse(parts[2]) ?? 0;
                    } else if (parts.length >= 2) {
                      // Fallback: try second part (might be old format or quiz)
                      totalQuestions = int.tryParse(parts[1]) ?? 0;
                    }
                  }
                  if (totalQuestions > 0) {
                    scoreText = '${activity.score}/$totalQuestions';
                  } else {
                    scoreText = '${activity.score}';
                  }
                }
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  leading: CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    child: Icon(
                      _iconForEntityType(activity.entityType),
                      color: Colors.blue,
                    ),
                  ),
                  title: Text(
                    activity.entityTitle ?? 'Untitled Activity',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    _formatDateTime(activity.createdAt),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                  trailing: scoreText.isNotEmpty
                      ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      scoreText,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                  )
                      : null,
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  void _showAllActivities(List<ActivityProgress> activities) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'All Recent Activities',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: activities.length,
                      itemBuilder: (context, index) {
                        final a = activities[index];
                        String scoreText = '';
                        if (a.score != null) {
                          if (a.entityType.toLowerCase() == 'quiz') {
                            // Parse total_items from stage field (format: "operator|total_items")
                            int totalQuestions = 0;
                            if (a.stage.contains('|')) {
                              final parts = a.stage.split('|');
                              if (parts.length >= 2) {
                                totalQuestions = int.tryParse(parts[1]) ?? 0;
                              }
                            }
                            if (totalQuestions > 0) {
                              scoreText = '${a.score}/$totalQuestions';
                            } else {
                              scoreText = '${a.score}%';
                            }
                          } else {
                            // For games, parse total_items from stage (format: "operator|difficulty|total_items")
                            int totalQuestions = 0;
                            if (a.stage.contains('|')) {
                              final parts = a.stage.split('|');
                              // For games: operator|difficulty|total_items (3 parts)
                              if (parts.length >= 3) {
                                // Game format: operator|difficulty|total_items
                                totalQuestions = int.tryParse(parts[2]) ?? 0;
                              } else if (parts.length >= 2) {
                                // Fallback: try second part
                                totalQuestions = int.tryParse(parts[1]) ?? 0;
                              }
                            }
                            if (totalQuestions > 0) {
                              scoreText = '${a.score}/$totalQuestions';
                            } else {
                              scoreText = '${a.score}';
                            }
                          }
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            leading: CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.blue.withOpacity(0.1),
                              child: Icon(
                                _iconForEntityType(a.entityType),
                                color: Colors.blue,
                              ),
                            ),
                            title: Text(
                              a.entityTitle ?? 'Untitled Activity',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              _formatDateTime(a.createdAt),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                            trailing: scoreText.isNotEmpty
                                ? Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                scoreText,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue,
                                ),
                              ),
                            )
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  IconData _iconForEntityType(String type) {
    switch (type.toLowerCase()) {
      case 'lesson':
        return Icons.menu_book_rounded;
      case 'quiz':
        return Icons.quiz_rounded;
      case 'exercise':
        return Icons.fitness_center_rounded;
      case 'game':
        return Icons.videogame_asset_rounded;
      default:
        return Icons.history_rounded;
    }
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hrs ago';
    return '${diff.inDays} days ago';
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    
    if (diff.inDays < 1) {
      return _formatTimeAgo(dateTime);
    }
    
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    
    return '$month/$day/$year $hour:$minute';
  }
}
