import 'package:flutter/material.dart';
import '../services/student_quiz_progress_service.dart';

class QuizProgressTable extends StatelessWidget {
  final List<QuizProgressData> quizData;

  const QuizProgressTable({
    super.key,
    required this.quizData,
  });

  int _calculateTotalScore() {
    return quizData.fold(0, (sum, quiz) => sum + quiz.totalScore);
  }

  int _calculateTotalPossible() {
    return quizData.fold(0, (sum, quiz) => sum + quiz.totalPossible);
  }

  double _calculateTotalPassingRate() {
    if (quizData.isEmpty) return 0;
    final rates = quizData.map((q) => q.passingRate).where((r) => r > 0).toList();
    if (rates.isEmpty) return 0;
    return rates.reduce((a, b) => a + b) / rates.length;
  }

  @override
  Widget build(BuildContext context) {
    if (quizData.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'No quiz data available for this operator.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    final totalScore = _calculateTotalScore();
    final totalPossible = _calculateTotalPossible();
    final totalPassingRate = _calculateTotalPassingRate();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Table(
            border: TableBorder.all(color: Colors.grey.shade300),
            columnWidths: const {
              0: FixedColumnWidth(200),
              1: FixedColumnWidth(180),
              2: FixedColumnWidth(120),
              3: FixedColumnWidth(120),
              4: FixedColumnWidth(120),
              5: FixedColumnWidth(150),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                children: [
                  _buildHeaderCell('Quiz'),
                  _buildHeaderCell('Lesson'),
                  _buildHeaderCell('Attempts'),
                  _buildHeaderCell('Highest Score'),
                  _buildHeaderCell('Total Score'),
                  _buildHeaderCell('Passing Rate %'),
                ],
              ),
              ...quizData.asMap().entries.map((entry) {
                final index = entry.key;
                final quiz = entry.value;
                
                // Show the actual attempt count (which is already limited to 3 by the service)
                final attemptsText = '${quiz.attemptsCount}';
                final highestScoreText = quiz.highestScorePercentage > 0 && quiz.totalQuestions > 0
                    ? '${((quiz.highestScorePercentage / 100) * quiz.totalQuestions).round()}/${quiz.totalQuestions}'
                    : '-';
                final totalScoreText = quiz.totalScore > 0
                    ? '${quiz.totalScore}/${quiz.totalPossible}'
                    : '-';
                final passingRateText = quiz.passingRate > 0
                    ? '${quiz.passingRate.toStringAsFixed(1)}%'
                    : '-';

                return TableRow(
                  children: [
                    _buildDataCell(quiz.quizTitle, isLeftAligned: true),
                    _buildDataCell(quiz.lessonTitle ?? '-', isLeftAligned: true),
                    _buildDataCell(attemptsText),
                    _buildDataCell(highestScoreText),
                    _buildDataCell(totalScoreText),
                    _buildDataCell(passingRateText),
                  ],
                );
              }).toList(),
              TableRow(
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                children: [
                  _buildTotalCell('TOTAL', isLeftAligned: true),
                  _buildTotalCell(''),
                  _buildTotalCell(''),
                  _buildTotalCell(''),
                  _buildTotalCell('$totalScore/$totalPossible'),
                  _buildTotalCell('${totalPassingRate.toStringAsFixed(1)}%'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDataCell(String text, {bool isLeftAligned = false}) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13),
        textAlign: isLeftAligned ? TextAlign.left : TextAlign.center,
      ),
    );
  }

  Widget _buildTotalCell(String text, {bool isLeftAligned = false}) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900,
        ),
        textAlign: isLeftAligned ? TextAlign.left : TextAlign.center,
      ),
    );
  }

}


