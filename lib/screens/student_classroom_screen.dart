import 'package:flutter/material.dart';
import 'package:pracpro/models/classroom.dart';
import 'package:pracpro/screens/basic_operator_module_page.dart';
import 'package:pracpro/widgets/operator_list_card.dart';

class StudentClassroomScreen extends StatefulWidget {
  final Classroom classroom;
  const StudentClassroomScreen({super.key, required this.classroom});

  @override
  State<StudentClassroomScreen> createState() => _StudentClassroomScreenState();
}

class _StudentClassroomScreenState extends State<StudentClassroomScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Classroom: ${widget.classroom.name}'),
        backgroundColor: Colors.blue,
      ),
      body: _buildBasicOperatorsTab(),
    );
  }

  Widget _buildBasicOperatorsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OperatorListCard(
            title: 'Addition',
            subtitle: 'Practice addition operations',
            icon: Icons.add,
            backgroundColor: Colors.indigo[50]!,
            iconColor: Colors.lightBlue,
              onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BasicOperatorModulePage(
                    operatorName: 'addition',
                    classroomId: widget.classroom.id,
        ),
      ),
    );
            },
          ),
          OperatorListCard(
            title: 'Subtraction',
            subtitle: 'Practice subtraction operations',
            icon: Icons.remove,
            backgroundColor: Colors.red[50]!,
            iconColor: Colors.redAccent,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BasicOperatorModulePage(
                    operatorName: 'subtraction',
                    classroomId: widget.classroom.id,
                      ),
                    ),
              );
            },
          ),
          OperatorListCard(
            title: 'Multiplication',
            subtitle: 'Practice multiplication operations',
            icon: Icons.close,
            backgroundColor: Colors.green[50]!,
            iconColor: Colors.green,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BasicOperatorModulePage(
                    operatorName: 'multiplication',
                    classroomId: widget.classroom.id,
                  ),
                ),
              );
            },
          ),
          OperatorListCard(
            title: 'Division',
            subtitle: 'Practice division operations',
            icon: Icons.percent,
            backgroundColor: Colors.purple[50]!,
            iconColor: Colors.purple,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BasicOperatorModulePage(
                    operatorName: 'division',
                    classroomId: widget.classroom.id,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

}
