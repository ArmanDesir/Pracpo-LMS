import 'package:flutter/material.dart';
import 'package:pracpro/screens/basic_operator_create_game.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pracpro/screens/basic_operator_module_page.dart';

class BasicOperationsDashboard extends StatefulWidget {
  final String? classroomId;

  const BasicOperationsDashboard({super.key, this.classroomId});

  @override
  State<BasicOperationsDashboard> createState() =>
      _BasicOperationsDashboardState();
}

class _BasicOperationsDashboardState extends State<BasicOperationsDashboard> {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? _userInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final res = await supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      setState(() {
        _userInfo = res;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final role = _userInfo?['user_type'] ?? 'student';
    final name = _userInfo?['name'] ?? 'User';

    return Scaffold(
      appBar: AppBar(
        title: Text('Basic Operations (${role.toUpperCase()})'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Welcome, $name 👋',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            if (role == 'teacher') ...[
              _buildOperatorSection(
                  context, 'Addition', Icons.add, Colors.lightBlue, 'addition'),
              const SizedBox(height: 16),
              _buildOperatorSection(
                  context, 'Subtraction', Icons.remove, Colors.redAccent, 'subtraction'),
              const SizedBox(height: 16),
              _buildOperatorSection(
                  context, 'Multiplication', Icons.close, Colors.green, 'multiplication'),
              const SizedBox(height: 16),
              _buildOperatorSection(
                  context, 'Division', Icons.percent, Colors.purple, 'division'),
            ],

            if (role != 'teacher') ...[
              _buildStudentOperatorCard(context, 'Addition', Icons.add,
                  Colors.lightBlue, 'addition'),
              const SizedBox(height: 16),
              _buildStudentOperatorCard(context, 'Subtraction', Icons.remove,
                  Colors.redAccent, 'subtraction'),
              const SizedBox(height: 16),
              _buildStudentOperatorCard(context, 'Multiplication', Icons.close,
                  Colors.green, 'multiplication'),
              const SizedBox(height: 16),
              _buildStudentOperatorCard(context, 'Division', Icons.percent,
                  Colors.purple, 'division'),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildOperatorSection(
      BuildContext context,
      String title,
      IconData icon,
      Color color,
      String operatorName,
      ) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: Icon(icon),
              label: Text(title),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BasicOperatorModulePage(
                      operatorName: operatorName,
                      classroomId: widget.classroomId,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      '/basic_operator/create',
                      arguments: {
                        'operator': operatorName,
                        'contentType': 'lesson',
                        'classroomId': widget.classroomId,
                      },
                    ),
                    child: const Text('Create Lesson'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      '/basic_operator/create',
                      arguments: {
                        'operator': operatorName,
                        'contentType': 'quiz',
                        'classroomId': widget.classroomId,
                      },
                    ),
                    child: const Text('Create Quiz'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      '/basic_operator/create',
                      arguments: {
                        'operator': operatorName,
                        'contentType': 'exercise',
                        'classroomId': widget.classroomId,
                      },
                    ),
                    child: const Text('Create Exercise'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BasicOperatorCreateGamePage(
                          operatorKey: operatorName,
                          classroomId: widget.classroomId,
                        ),
                      ),
                    ),
                    child: const Text('Create Game'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentOperatorCard(
      BuildContext context,
      String title,
      IconData icon,
      Color color,
      String operatorName,
      ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title,
            style:
            const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        subtitle: const Text('Tap to view available content'),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BasicOperatorModulePage(
                operatorName: operatorName,
                classroomId: widget.classroomId,
              ),
            ),
          );
        },
      ),
    );
  }
}
