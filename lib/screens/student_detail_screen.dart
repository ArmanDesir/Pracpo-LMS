import 'package:flutter/material.dart';
import 'package:pracpro/models/user.dart' as app_model;
import 'package:pracpro/services/student_quiz_progress_service.dart';
import 'package:pracpro/widgets/loading_wrapper.dart';
import 'package:pracpro/widgets/empty_state.dart';
import 'package:pracpro/widgets/quiz_progress_table.dart';

class StudentDetailScreen extends StatefulWidget {
  final app_model.User student;
  final String classroomId;

  const StudentDetailScreen({
    super.key,
    required this.student,
    required this.classroomId,
  });

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final StudentQuizProgressService _quizProgressService = StudentQuizProgressService();

  String? _selectedOperator;
  List<QuizProgressData> _quizProgressData = [];
  bool _isLoadingQuizProgress = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }


  Widget _buildStudentInformationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoField('Student name', widget.student.name),
          const SizedBox(height: 16),
          _buildInfoField('Email', widget.student.email ?? 'N/A'),
          const SizedBox(height: 16),
          _buildInfoField('Student ID', widget.student.studentId ?? 'N/A'),
          const SizedBox(height: 16),
          _buildInfoField('Grade', widget.student.grade != null ? 'Grade ${widget.student.grade}' : 'N/A'),
          const SizedBox(height: 16),
          _buildInfoField('Guardian Name', widget.student.guardianName ?? 'N/A'),
          const SizedBox(height: 16),
          _buildInfoField('Guardian Email', widget.student.guardianEmail ?? 'N/A'),
          const SizedBox(height: 16),
          _buildInfoField('Guardian Contact', widget.student.guardianContactNumber ?? 'N/A'),
          const SizedBox(height: 16),
          if (widget.student.studentInfo != null && widget.student.studentInfo!.isNotEmpty)
            _buildInfoField('Student Info', widget.student.studentInfo!),
        ],
      ),
    );
  }

  Widget _buildInfoField(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black26),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadQuizProgress(String operator) async {
    setState(() {
      _selectedOperator = operator;
      _isLoadingQuizProgress = true;
    });

    try {
      final data = await _quizProgressService.getStudentQuizProgress(
        studentId: widget.student.id,
        operator: operator,
        classroomId: widget.classroomId,
      );

      if (mounted) {
        setState(() {
          _quizProgressData = data;
          _isLoadingQuizProgress = false;
        });
      }
    } catch (e, stackTrace) {
      if (mounted) {
        setState(() {
          _isLoadingQuizProgress = false;
        });
      }
    }
  }

  Widget _buildStudentProgressTab() {

    final quizzes = _quizProgressData.where((q) => !q.isGame).toList();
    final games = _quizProgressData.where((q) => q.isGame).toList();
    

    return Column(
      children: [

        Container(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildOperatorFilterButton('addition', '+', Colors.red),
              _buildOperatorFilterButton('subtraction', '−', Colors.red),
              _buildOperatorFilterButton('multiplication', '×', Colors.red),
              _buildOperatorFilterButton('division', '÷', Colors.red),
            ],
          ),
        ),
        const Divider(height: 1),

        Expanded(
          child: _selectedOperator == null
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text(
                      'Select an operator to view quiz and game progress',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                )
              : LoadingWrapper(
                  isLoading: _isLoadingQuizProgress,
                  child: _quizProgressData.isEmpty
                      ? const EmptyState(
                          icon: Icons.quiz_outlined,
                          message: 'No quiz or game progress available.',
                          subtitle: 'No quizzes or games found for this operator.',
                        )
                      : SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              if (quizzes.isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.quiz, color: Colors.purple, size: 24),
                                      const SizedBox(width: 8),
                                      Text(
                                        'QUIZZES',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.purple[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  child: QuizProgressTable(quizData: quizzes),
                                ),
                              ],

                              if (games.isNotEmpty) ...[
                                Padding(
                                  padding: EdgeInsets.fromLTRB(16, quizzes.isNotEmpty ? 8 : 16, 16, 8),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.videogame_asset, color: Colors.green, size: 24),
                                      const SizedBox(width: 8),
                                      Text(
                                        'GAMES',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  child: QuizProgressTable(quizData: games),
                                ),
                              ],

                              if (quizzes.isEmpty && games.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(32.0),
                                  child: Center(
                                    child: Text(
                                      'No quizzes or games found for this operator.',
                                      style: TextStyle(fontSize: 16, color: Colors.grey),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                ),
        ),
      ],
    );
  }

  Widget _buildOperatorFilterButton(String operator, String symbol, Color color) {
    final isSelected = _selectedOperator == operator;

    return ElevatedButton(
      onPressed: () => _loadQuizProgress(operator),
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
            operator.toUpperCase(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _getActivityIcon(String entityType) {
    IconData icon;
    Color color;

    switch (entityType.toLowerCase()) {
      case 'quiz':
        icon = Icons.quiz;
        color = Colors.purple;
        break;
      case 'lesson':
        icon = Icons.book;
        color = Colors.blue;
        break;
      case 'game':
      case 'crossmath':
      case 'ninja':
        icon = Icons.videogame_asset;
        color = Colors.green;
        break;
      case 'exercise':
        icon = Icons.fitness_center;
        color = Colors.orange;
        break;
      default:
        icon = Icons.assignment;
        color = Colors.grey;
    }

    return CircleAvatar(
      backgroundColor: color.withOpacity(0.1),
      child: Icon(icon, color: color, size: 20),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.student.name.toUpperCase(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.grey[100],
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.black,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Student progress'),
            Tab(text: 'Student information'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStudentProgressTab(),
          _buildStudentInformationTab(),
        ],
      ),
    );
  }
}

