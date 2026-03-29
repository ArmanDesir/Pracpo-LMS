import 'package:flutter/material.dart';
import 'package:pracpro/models/user.dart' as app_model;
import 'package:pracpro/providers/auth_provider.dart';
import 'package:pracpro/providers/classroom_provider.dart';
import 'package:pracpro/screens/classroom_details_screen.dart';
import 'package:pracpro/screens/manage_classrooms_screen.dart';
import 'package:pracpro/screens/activity_logs_screen.dart';
import 'package:provider/provider.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  final GlobalKey _classroomListKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  int _lessonsCount = 0;

  List<app_model.User> _acceptedStudents = [];
  Map<String, List<app_model.User>> _studentsByClassroom = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final classroomProvider = Provider.of<ClassroomProvider>(context, listen: false);

      final teacherId = authProvider.currentUser?.id ?? '';

      try {
        await classroomProvider.loadTeacherClassrooms();

        final counts = await classroomProvider.getContentCountsForTeacher(teacherId);
        final acceptedStudents = await classroomProvider.getAcceptedStudentsForAllClassrooms();
        final groupedStudents = await classroomProvider.getStudentsGroupedByClassroom();
        final uniqueStudents = _dedupeUsers(acceptedStudents)
          ..sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));

        if (mounted) {
          setState(() {
            _lessonsCount = counts['lessons'] ?? 0;
            _acceptedStudents = uniqueStudents;
            _studentsByClassroom = groupedStudents;
          });
        }
      } catch (e, stack) {
        // Error - continue silently
      }
    });
  }

  List<app_model.User> _dedupeUsers(List<app_model.User> users) {
    final seen = <String>{};
    final unique = <app_model.User>[];
    for (final u in users) {
      final key = (u.id ?? 'email:${u.email ?? ''}').trim();
      if (key.isEmpty || seen.contains(key)) continue;
      seen.add(key);
      unique.add(u);
    }
    return unique;
  }

  void _scrollToClassrooms() {
    if (_classroomListKey.currentContext != null) {
      Scrollable.ensureVisible(
        _classroomListKey.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _openActivityLogsPicker(BuildContext context) async {
    final classroomProvider = Provider.of<ClassroomProvider>(context, listen: false);
    final classrooms = classroomProvider.teacherClassrooms;

    if (classrooms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No classrooms available.')),
      );
      return;
    }

    final chosen = await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                leading: Icon(Icons.school),
                title: Text('Select a classroom'),
                subtitle: Text('Open student activity for the selected class'),
              ),
              const Divider(height: 0),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: classrooms.length,
                  itemBuilder: (_, i) {
                    final c = classrooms[i];
                    return ListTile(
                      leading: const Icon(Icons.class_),
                      title: Text(c.name),
                      subtitle: Text('Code: ${c.code ?? ''} • Students: ${c.studentIds.length}'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => Navigator.pop(sheetCtx, c),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (chosen != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ActivityLogsScreen(classroomId: chosen.id),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final classroomProvider = Provider.of<ClassroomProvider>(context);
    final acceptedStudentsCount = _acceptedStudents.length;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Teacher Dashboard'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/welcome',
                    (route) => false,
              );
            },
          ),
        ],
      ),
      body: classroomProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GestureDetector(
                onTap: _scrollToClassrooms,
                child: _buildStatCard(
                  '${classroomProvider.teacherClassrooms.length}',
                  'Classrooms',
                  Colors.blue,
                ),
              ),
              _buildStatCard(
                '$acceptedStudentsCount',
                'Students',
                Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.settings, color: Colors.blue),
              title: const Text(
                'Manage Classroom',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Create, update, or delete your classrooms'),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ManageClassroomsScreen()),
                );
                Provider.of<ClassroomProvider>(context, listen: false)
                    .loadTeacherClassrooms();
              },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.history, color: Colors.orange),
              title: const Text(
                'Student Activity',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('View student activity logs for monitoring'),
              onTap: () => _openActivityLogsPicker(context),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Your Classrooms',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (classroomProvider.teacherClassrooms.isEmpty)
            Center(
              child: Text(
                'No classrooms yet. Tap "Create Classroom" to add one!',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            )
          else ...[
            ...classroomProvider.teacherClassrooms.take(3).map(
                  (classroom) => Container(
                key: classroom == classroomProvider.teacherClassrooms.first
                    ? _classroomListKey
                    : null,
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.shade100,
                      child: const Icon(Icons.class_, color: Colors.green),
                    ),
                    title: Text(
                      classroom.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Code: ${classroom.code ?? ''}\nStudents: ${_studentsByClassroom[classroom.id]?.length ?? 0}',
                    ),
                    isThreeLine: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ClassroomDetailsScreen(classroom: classroom),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            if (classroomProvider.teacherClassrooms.length > 3)
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ManageClassroomsScreen()),
                  );
                },
                child: const Text('See All Classrooms'),
              ),
          ],
          const SizedBox(height: 24),
          const Text(
            'Accepted Students',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (acceptedStudentsCount == 0)
            Center(
              child: Text(
                'No accepted students yet.',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            )
          else
            Column(
              children: _acceptedStudents.map((student) {
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.person, color: Colors.green),
                    title: Text(student.name ?? 'Unknown'),
                    subtitle: Text(student.email ?? 'No email'),
                    trailing: IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: () {
                        if (student.id != null) {
                          Navigator.pushNamed(
                            context,
                            '/profile',
                            arguments: student.id,
                          );
                        }
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Container(
      width: 140,
      height: 80,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Color.alphaBlend(color.withAlpha((0.08 * 255).toInt()), Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color.alphaBlend(color.withAlpha((0.2 * 255).toInt()), Colors.white),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 16, color: color)),
        ],
      ),
    );
  }
}
