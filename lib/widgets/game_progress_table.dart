import 'package:flutter/material.dart';
import '../services/student_quiz_progress_service.dart';

class GameProgressTable extends StatelessWidget {
  final List<QuizProgressData> gameData;

  const GameProgressTable({
    super.key,
    required this.gameData,
  });

  int _calculateTotalScore() {
    return gameData.fold(0, (sum, game) => sum + game.totalScore);
  }

  int _calculateTotalPossible() {
    return gameData.fold(0, (sum, game) => sum + game.totalPossible);
  }

  double _calculateTotalPassingRate() {
    if (gameData.isEmpty) return 0;
    final rates = gameData.map((g) => g.passingRate).where((r) => r > 0).toList();
    if (rates.isEmpty) return 0;
    return rates.reduce((a, b) => a + b) / rates.length;
  }

  @override
  Widget build(BuildContext context) {
    if (gameData.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'No game data available.',
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
              1: FixedColumnWidth(100),
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
                  _buildHeaderCell('Game'),
                  _buildHeaderCell('Difficulty'),
                  _buildHeaderCell('Attempts'),
                  _buildHeaderCell('Highest Score'),
                  _buildHeaderCell('Total Score'),
                  _buildHeaderCell('Passing Rate %'),
                ],
              ),
              ...gameData.map((game) {
                final difficulty = game.difficulty != null
                    ? game.difficulty![0].toUpperCase() + game.difficulty!.substring(1)
                    : '-';
                final attempts = game.attemptsCount > 3 ? 3 : game.attemptsCount;                final highestScoreText = game.highestScore > 0 && game.totalQuestions > 0
                    ? '${game.highestScore}/${game.totalQuestions}'
                    : (game.highestScore > 0 ? '${game.highestScore}' : '-');
                final totalScoreText = game.totalScore > 0
                    ? '${game.totalScore}/${game.totalPossible}'
                    : '-';
                final passingRateText = game.passingRate > 0
                    ? '${game.passingRate.toStringAsFixed(1)}%'
                    : '-';

                return TableRow(
                  children: [
                    _buildDataCell(game.quizTitle, isLeftAligned: true),
                    _buildDataCell(difficulty),
                    _buildDataCell('$attempts'),
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

