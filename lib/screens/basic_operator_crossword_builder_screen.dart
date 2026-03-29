import 'package:flutter/material.dart';
import 'package:pracpro/modules/basic_operators/addition/crossword_cell.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum PatternType { horizontal, vertical, slant, slantReverse }

class BasicOperatorCrosswordBuilderScreen extends StatefulWidget {
  final String operator;
  final String gameId;
  final String difficulty;
  final Map<String, dynamic> config;
  final String title;
  final String description;

  const BasicOperatorCrosswordBuilderScreen({
    super.key,
    required this.operator,
    required this.gameId,
    required this.difficulty,
    required this.config,
    required this.title,
    required this.description,
  });

  @override
  State<BasicOperatorCrosswordBuilderScreen> createState() =>
      _BasicOperatorCrosswordBuilderScreenState();
}

class _BasicOperatorCrosswordBuilderScreenState
    extends State<BasicOperatorCrosswordBuilderScreen> {
  final _supabase = Supabase.instance.client;
  static const gridSize = 5;

  int get _numRounds {
    switch (widget.difficulty.toLowerCase()) {
      case 'easy':
        return 1;
      case 'medium':
        return 3;
      case 'hard':
        return 5;
      default:
        return 1;
    }
  }

  int _currentRound = 0;
  PatternType? _selectedPattern;
  String? _selectedOperator;
  List<List<List<CrosswordCell>>> _rounds = [];

  int? _selectedRow;
  int? _selectedCol;

  Offset? _menuPosition;

  @override
  void initState() {
    super.initState();
    _initRounds();
  }

  void _initRounds() {
    _rounds = List.generate(_numRounds, (_) {
      return List.generate(
      gridSize,
          (r) => List.generate(
        gridSize,
            (c) => CrosswordCell(row: r, col: c, type: CellType.empty),
      ),
    );
    });
  }

  String _getOperatorSymbol() {
    switch (widget.operator.toLowerCase()) {
      case 'addition':
        return '+';
      case 'subtraction':
        return '-';
      case 'multiplication':
        return '×';
      case 'division':
        return '÷';
      default:
        return '+';
    }
  }

  Future<void> _selectPattern() async {
    final pattern = await showDialog<PatternType>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Select Pattern'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.arrow_forward),
              title: const Text('Horizontal'),
              onTap: () => Navigator.pop(context, PatternType.horizontal),
            ),
            ListTile(
              leading: const Icon(Icons.arrow_downward),
              title: const Text('Vertical'),
              onTap: () => Navigator.pop(context, PatternType.vertical),
            ),
            ListTile(
              leading: const Icon(Icons.trending_up),
              title: const Text('Slant (Diagonal)'),
              onTap: () => Navigator.pop(context, PatternType.slant),
            ),
          ],
        ),
      ),
    );

    if (pattern != null) {
      setState(() {
        _selectedPattern = pattern;
        _selectedOperator = _getOperatorSymbol();
      });
    }
  }

  void _handleCellTap(int row, int col, Offset position) {
    final cell = _rounds[_currentRound][row][col];

    if (cell.type == CellType.empty) {
      _showCellPlacementDialog(row, col);
      return;
    }

    if (cell.type == CellType.number) {
      _editCell(row, col);
      return;
    }

    if (cell.type == CellType.blank) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This is an answer cell that is auto-calculated. Edit the numbers in the equation to change it.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _selectedRow = row;
      _selectedCol = col;
    });
  }

  void _handleCellLongPress(int row, int col, Offset position) {
    final cell = _rounds[_currentRound][row][col];

    if (cell.type == CellType.empty) {
      return;
    }

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        MediaQuery.of(context).size.width - position.dx,
        MediaQuery.of(context).size.height - position.dy,
      ),
      items: [
        PopupMenuItem<String>(
          value: 'edit',
          child: const Row(
            children: [
              Icon(Icons.edit, size: 20),
              SizedBox(width: 8),
              Text('Edit'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: const Row(
            children: [
              Icon(Icons.delete, size: 20, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'cancel',
          child: const Row(
            children: [
              Icon(Icons.cancel, size: 20),
              SizedBox(width: 8),
              Text('Cancel'),
            ],
          ),
        ),
      ],
    ).then((value) {
      setState(() {
        _selectedRow = null;
        _selectedCol = null;
      });

      if (value == 'edit') {
        _editCell(row, col);
      } else if (value == 'delete') {
        _deleteCell(row, col);
      }
    });
  }

  void _showCellPlacementDialog(int row, int col) {

    final canHorizontal = col + 4 < gridSize;
    final canVertical = row + 4 < gridSize;
    final canSlant = (row + 4) < gridSize && (col + 4) < gridSize;
    final canSlantReverse = (row + 4) < gridSize && (col - 4) >= 0;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Start Pattern'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select a pattern type to create a math equation.\n\n'
              'Patterns include: number → operator → number → equals → answer',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.arrow_forward),
              title: const Text('Horizontal'),
              subtitle: Text(canHorizontal
                  ? 'Left to right pattern'
                  : 'Not enough space (need 5 cells to the right)'),
              enabled: canHorizontal,
              onTap: canHorizontal
                  ? () {
                      Navigator.pop(context);
                      _selectedPattern = PatternType.horizontal;
                      _selectedOperator = _getOperatorSymbol();
                      _startPattern(row, col);
                    }
                  : null,
            ),
            ListTile(
              leading: const Icon(Icons.arrow_downward),
              title: const Text('Vertical'),
              subtitle: Text(canVertical
                  ? 'Top to bottom pattern'
                  : 'Not enough space (need 5 cells below)'),
              enabled: canVertical,
              onTap: canVertical
                  ? () {
                      Navigator.pop(context);
                      _selectedPattern = PatternType.vertical;
                      _selectedOperator = _getOperatorSymbol();
                      _startPattern(row, col);
                    }
                  : null,
            ),
            ListTile(
              leading: const Icon(Icons.trending_up),
              title: const Text('Slant (Diagonal ↘)'),
              subtitle: Text(canSlant
                  ? 'Top-left to bottom-right'
                  : 'Not enough space (must start at top-left area)'),
              enabled: canSlant,
              onTap: canSlant
                  ? () {
                      Navigator.pop(context);
                      _selectedPattern = PatternType.slant;
                      _selectedOperator = _getOperatorSymbol();
                      _startPattern(row, col);
                    }
                  : null,
            ),
            ListTile(
              leading: const Icon(Icons.trending_down),
              title: const Text('Slant (Diagonal ↙)'),
              subtitle: Text(canSlantReverse
                  ? 'Top-right to bottom-left'
                  : 'Not enough space (must start at top-right area)'),
              enabled: canSlantReverse,
              onTap: canSlantReverse
                  ? () {
                      Navigator.pop(context);
                      _selectedPattern = PatternType.slantReverse;
                      _selectedOperator = _getOperatorSymbol();
                      _startPattern(row, col);
                    }
                  : null,
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

  Future<void> _editCell(int row, int col) async {
    final cell = _rounds[_currentRound][row][col];

    if (cell.type == CellType.empty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Please start a pattern first by selecting a pattern type.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (cell.type == CellType.blank) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Answer cells are auto-calculated. Edit the numbers in the equation to change the answer.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (cell.type == CellType.number) {
      final newValue = await _askNumber(cell.value);
      if (newValue != null && newValue.isNotEmpty) {
        setState(() {
          cell.value = newValue;
          cell.answer = int.tryParse(newValue);
        });
        _recalculateAllPatterns();
      }
    } else if (cell.type == CellType.operator) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Operator is fixed to: ${_getOperatorSymbol()}'),
          duration: const Duration(seconds: 2),
        ),
      );
    } else if (cell.type == CellType.equals) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Equals sign cannot be edited.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _startPattern(int startRow, int startCol) {
    if (_selectedPattern == null || _selectedOperator == null) return;

    final grid = _rounds[_currentRound];
    bool canPlace = false;
    List<({int row, int col, CellType requiredType, String? value})> cellsToPlace = [];

    switch (_selectedPattern!) {
      case PatternType.horizontal:
        canPlace = startCol + 4 < gridSize;
        if (canPlace) {
          cellsToPlace = [
            (row: startRow, col: startCol, requiredType: CellType.number, value: null),
            (row: startRow, col: startCol + 1, requiredType: CellType.operator, value: _selectedOperator),
            (row: startRow, col: startCol + 2, requiredType: CellType.number, value: null),
            (row: startRow, col: startCol + 3, requiredType: CellType.equals, value: '='),
            (row: startRow, col: startCol + 4, requiredType: CellType.blank, value: null),
          ];
        }
        break;
      case PatternType.vertical:
        canPlace = startRow + 4 < gridSize;
        if (canPlace) {
          cellsToPlace = [
            (row: startRow, col: startCol, requiredType: CellType.number, value: null),
            (row: startRow + 1, col: startCol, requiredType: CellType.operator, value: _selectedOperator),
            (row: startRow + 2, col: startCol, requiredType: CellType.number, value: null),
            (row: startRow + 3, col: startCol, requiredType: CellType.equals, value: '='),
            (row: startRow + 4, col: startCol, requiredType: CellType.blank, value: null),
          ];
        }
        break;
      case PatternType.slant:

        canPlace = (startRow + 4) < gridSize && (startCol + 4) < gridSize;
        if (canPlace) {
          cellsToPlace = [
            (row: startRow, col: startCol, requiredType: CellType.number, value: null),
            (row: startRow + 1, col: startCol + 1, requiredType: CellType.operator, value: _selectedOperator),
            (row: startRow + 2, col: startCol + 2, requiredType: CellType.number, value: null),
            (row: startRow + 3, col: startCol + 3, requiredType: CellType.equals, value: '='),
            (row: startRow + 4, col: startCol + 4, requiredType: CellType.blank, value: null),
          ];
        }
        break;
      case PatternType.slantReverse:

        canPlace = (startRow + 4) < gridSize && (startCol - 4) >= 0;
        if (canPlace) {
          cellsToPlace = [
            (row: startRow, col: startCol, requiredType: CellType.number, value: null),
            (row: startRow + 1, col: startCol - 1, requiredType: CellType.operator, value: _selectedOperator),
            (row: startRow + 2, col: startCol - 2, requiredType: CellType.number, value: null),
            (row: startRow + 3, col: startCol - 3, requiredType: CellType.equals, value: '='),
            (row: startRow + 4, col: startCol - 4, requiredType: CellType.blank, value: null),
          ];
        }
        break;
    }

    if (!canPlace) {
      String helpMessage = '';
      switch (_selectedPattern!) {
        case PatternType.slant:
          helpMessage = 'Slant (↘) needs 5 diagonal cells from top-left to bottom-right.\nFor a 5x5 grid, you must start at the top-left corner (row 0, col 0).';
          break;
        case PatternType.slantReverse:
          helpMessage = 'Slant (↙) needs 5 diagonal cells from top-right to bottom-left.\nFor a 5x5 grid, you must start at the top-right corner (row 0, col 4).';
          break;
        case PatternType.horizontal:
          helpMessage = 'Horizontal pattern needs 5 cells. Try starting at col 0.';
          break;
        case PatternType.vertical:
          helpMessage = 'Vertical pattern needs 5 cells. Try starting at row 0.';
          break;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Pattern does not fit at this position.\n$helpMessage'),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    String? conflictMessage;
    for (final cellPlace in cellsToPlace) {
      final existingCell = grid[cellPlace.row][cellPlace.col];

      if (existingCell.type == CellType.empty) {
        continue;
      }

      if (existingCell.type == cellPlace.requiredType) {

        if (cellPlace.requiredType == CellType.operator || cellPlace.requiredType == CellType.equals) {
          if (existingCell.value != cellPlace.value) {
            conflictMessage = '⚠️ Cell at row ${cellPlace.row + 1}, col ${cellPlace.col + 1} has conflicting value.';
            break;
          }
        }

        continue;
      }

      if (existingCell.type != CellType.empty) {
        conflictMessage = '⚠️ Cannot place pattern: cell at row ${cellPlace.row + 1}, col ${cellPlace.col + 1} is already occupied by a ${existingCell.type.name} cell.';
        break;
      }
    }

    if (conflictMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(conflictMessage),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      for (final cellPlace in cellsToPlace) {
        final existingCell = grid[cellPlace.row][cellPlace.col];

        if (existingCell.type == CellType.empty) {
          grid[cellPlace.row][cellPlace.col] = CrosswordCell(
            row: cellPlace.row,
            col: cellPlace.col,
            type: cellPlace.requiredType,
            value: cellPlace.value,
          );
        } else if (existingCell.type == cellPlace.requiredType) {

          if (cellPlace.requiredType == CellType.operator || cellPlace.requiredType == CellType.equals) {
            if (existingCell.value != cellPlace.value) {
              existingCell.value = cellPlace.value;
            }
          }

        }

      }
    });

    _recalculateAllPatterns();
  }

  void _recalculateAllPatterns() {

    final Map<String, Set<int>> blankCellAnswers = {};

    final grid = _rounds[_currentRound];

    if (grid.length != gridSize) {
      return;
    }
    for (int r = 0; r < gridSize && r < grid.length; r++) {
      if (grid[r].length != gridSize) {
        continue;
      }
      for (int c = 0; c < gridSize && c < grid[r].length; c++) {
        _calculatePatternWithTracking(r, c, blankCellAnswers);
      }
    }

    final Map<String, int> validatedAnswers = {};
    bool hasConflict = false;
    final List<String> conflictMessages = [];

    blankCellAnswers.forEach((key, answers) {
      if (answers.isEmpty) {

        return;
      }

      if (answers.length > 1) {

        hasConflict = true;
        final parts = key.split('_');
        final row = int.parse(parts[0]);
        final col = int.parse(parts[1]);
        conflictMessages.add(
          '⚠️ Cell at row ${row + 1}, col ${col + 1}: Multiple patterns calculate different answers (${answers.join(', ')})'
        );

        validatedAnswers[key] = answers.first;
    } else {

        validatedAnswers[key] = answers.first;
      }
    });

    validatedAnswers.forEach((key, answer) {
      final parts = key.split('_');
      final row = int.parse(parts[0]);
      final col = int.parse(parts[1]);
      final cell = grid[row][col];
      if (cell.type == CellType.blank) {
        cell.answer = answer;
        cell.value = null;
      }
    });

    if (mounted) {
      setState(() {});
    }

    if (hasConflict && conflictMessages.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(conflictMessages.join('\n')),
          duration: const Duration(seconds: 5),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _calculatePatternWithTracking(int row, int col, Map<String, Set<int>> blankCellAnswers) {
    final grid = _rounds[_currentRound];

    for (int startCol = (col - 4).clamp(0, gridSize - 5); startCol <= col && startCol + 4 < gridSize; startCol++) {
      _calculatePatternAndTrack(grid, row, startCol, PatternType.horizontal, blankCellAnswers);
    }

    for (int startRow = (row - 4).clamp(0, gridSize - 5); startRow <= row && startRow + 4 < gridSize; startRow++) {
      _calculatePatternAndTrack(grid, startRow, col, PatternType.vertical, blankCellAnswers);
    }

    for (int offset = -4; offset <= 0; offset++) {
      final startRow = row + offset;
      final startCol = col + offset;
      if (startRow >= 0 && startCol >= 0 && startRow + 4 < gridSize && startCol + 4 < gridSize) {
        _calculatePatternAndTrack(grid, startRow, startCol, PatternType.slant, blankCellAnswers);
      }
    }

    for (int i = 0; i <= 4; i++) {
      final startRow = row - i;
      final startCol = col + i;

      if (startRow >= 0 &&
          startRow + 4 < gridSize &&
          startCol >= 4 &&
          startCol < gridSize) {
        _calculatePatternAndTrack(grid, startRow, startCol, PatternType.slantReverse, blankCellAnswers);
      }
    }
  }

  void _calculatePatternAndTrack(
    List<List<CrosswordCell>> grid,
    int startRow,
    int startCol,
    PatternType patternType,
    Map<String, Set<int>> blankCellAnswers,
  ) {

    if (grid.isEmpty || grid.length != gridSize) {
      return;
    }

    if (startRow < 0 || startRow >= gridSize || startCol < 0 || startCol >= gridSize) {
      return;
    }

    if (startRow >= grid.length || grid[startRow].length != gridSize) {
      return;
    }

    List<CrosswordCell>? cells;
    int? blankRow, blankCol;

    switch (patternType) {
      case PatternType.horizontal:

        if (startCol + 4 >= gridSize || startCol + 4 < 0) return;
        cells = [
          grid[startRow][startCol],
          grid[startRow][startCol + 1],
          grid[startRow][startCol + 2],
          grid[startRow][startCol + 3],
          grid[startRow][startCol + 4],
        ];
        blankRow = startRow;
        blankCol = startCol + 4;
        break;
      case PatternType.vertical:

        if (startRow + 4 >= gridSize || startRow + 4 < 0) return;
        cells = [
          grid[startRow][startCol],
          grid[startRow + 1][startCol],
          grid[startRow + 2][startCol],
          grid[startRow + 3][startCol],
          grid[startRow + 4][startCol],
        ];
        blankRow = startRow + 4;
        blankCol = startCol;
        break;
      case PatternType.slant:

        if (startRow + 4 >= gridSize || startRow + 4 < 0 ||
            startCol + 4 >= gridSize || startCol + 4 < 0) return;
        cells = [
          grid[startRow][startCol],
          grid[startRow + 1][startCol + 1],
          grid[startRow + 2][startCol + 2],
          grid[startRow + 3][startCol + 3],
          grid[startRow + 4][startCol + 4],
        ];
        blankRow = startRow + 4;
        blankCol = startCol + 4;
        break;
      case PatternType.slantReverse:

        if (startRow + 4 >= gridSize || startRow + 4 < 0 ||
            startCol - 4 < 0 || startCol >= gridSize) return;
        cells = [
          grid[startRow][startCol],
          grid[startRow + 1][startCol - 1],
          grid[startRow + 2][startCol - 2],
          grid[startRow + 3][startCol - 3],
          grid[startRow + 4][startCol - 4],
        ];
        blankRow = startRow + 4;
        blankCol = startCol - 4;
        break;
    }

    if (cells == null || blankRow == null || blankCol == null) {
      return;
    }

    if (cells.length != 5) {
      return;
    }

    if (cells[0].type == CellType.number &&
        cells[1].type == CellType.operator &&
        cells[2].type == CellType.number &&
        cells[3].type == CellType.equals &&
        cells[4].type == CellType.blank) {

      final num1 = int.tryParse(cells[0].value ?? '');
      final op = cells[1].value;
      final num2 = int.tryParse(cells[2].value ?? '');

      if (num1 != null && num2 != null && op != null) {
        int? result;
        switch (op) {
          case '+':
            result = num1 + num2;
            break;
          case '-':
            result = num1 - num2;
            break;
          case '×':
            result = num1 * num2;
            break;
          case '÷':
            if (num2 != 0) {
              result = num1 ~/ num2;
            }
            break;
        }

        if (result != null) {
          final key = '${blankRow}_${blankCol}';
          blankCellAnswers.putIfAbsent(key, () => <int>{}).add(result);
        }
      }
    }
  }

  void _calculatePattern(int row, int col) {
    final grid = _rounds[_currentRound];

    for (int startCol = (col - 4).clamp(0, gridSize - 5); startCol <= col && startCol + 4 < gridSize; startCol++) {
      _calculateHorizontalPattern(grid, row, startCol);
    }

    for (int startRow = (row - 4).clamp(0, gridSize - 5); startRow <= row && startRow + 4 < gridSize; startRow++) {
      _calculateVerticalPattern(grid, startRow, col);
    }

    for (int offset = -4; offset <= 0; offset++) {
      final startRow = row + offset;
      final startCol = col + offset;
      if (startRow >= 0 && startCol >= 0 && startRow + 4 < gridSize && startCol + 4 < gridSize) {
        _calculateSlantPattern(grid, startRow, startCol);
      }
    }

    for (int i = 0; i <= 4; i++) {
      final startRow = row - i;
      final startCol = col + i;

      if (startRow >= 0 && startCol >= 4 && startRow + 4 < gridSize) {
        _calculateSlantReversePattern(grid, startRow, startCol);
      }
    }
  }

  void _calculateHorizontalPattern(List<List<CrosswordCell>> grid, int row, int startCol) {
    final cells = [
      grid[row][startCol],
      grid[row][startCol + 1],
      grid[row][startCol + 2],
      grid[row][startCol + 3],
      grid[row][startCol + 4],
    ];

    if (cells[0].type == CellType.number &&
        cells[1].type == CellType.operator &&
        cells[2].type == CellType.number &&
        cells[3].type == CellType.equals &&
        cells[4].type == CellType.blank) {
      _calculateResult(cells);
    }
  }

  void _calculateVerticalPattern(List<List<CrosswordCell>> grid, int startRow, int col) {
    final cells = [
      grid[startRow][col],
      grid[startRow + 1][col],
      grid[startRow + 2][col],
      grid[startRow + 3][col],
      grid[startRow + 4][col],
    ];

    if (cells[0].type == CellType.number &&
        cells[1].type == CellType.operator &&
        cells[2].type == CellType.number &&
        cells[3].type == CellType.equals &&
        cells[4].type == CellType.blank) {
      _calculateResult(cells);
    }
  }

  void _calculateSlantPattern(List<List<CrosswordCell>> grid, int startRow, int startCol) {
    final cells = [
      grid[startRow][startCol],
      grid[startRow + 1][startCol + 1],
      grid[startRow + 2][startCol + 2],
      grid[startRow + 3][startCol + 3],
      grid[startRow + 4][startCol + 4],
    ];

    if (cells[0].type == CellType.number &&
        cells[1].type == CellType.operator &&
        cells[2].type == CellType.number &&
        cells[3].type == CellType.equals &&
        cells[4].type == CellType.blank) {
      _calculateResult(cells);
    }
  }

  void _calculateSlantReversePattern(List<List<CrosswordCell>> grid, int startRow, int startCol) {
    final cells = [
      grid[startRow][startCol],
      grid[startRow + 1][startCol - 1],
      grid[startRow + 2][startCol - 2],
      grid[startRow + 3][startCol - 3],
      grid[startRow + 4][startCol - 4],
    ];

    if (cells[0].type == CellType.number &&
        cells[1].type == CellType.operator &&
        cells[2].type == CellType.number &&
        cells[3].type == CellType.equals &&
        cells[4].type == CellType.blank) {
      _calculateResult(cells);
    }
  }

  void _calculateResult(List<CrosswordCell> patternCells) {
    final num1 = int.tryParse(patternCells[0].value ?? '');
    final op = patternCells[1].value;
    final num2 = int.tryParse(patternCells[2].value ?? '');
    final resultCell = patternCells[4];

    if (num1 != null && num2 != null && op != null) {
      int? result;
      switch (op) {
        case '+':
          result = num1 + num2;
          break;
        case '-':
          result = num1 - num2;
          break;
        case '×':
          result = num1 * num2;
          break;
        case '÷':
          if (num2 != 0) {
            result = num1 ~/ num2;
          }
          break;
      }

      if (result != null) {
    setState(() {
          resultCell.answer = result;
          resultCell.value = null;
          resultCell.type = CellType.blank;
        });
      }
    }
  }

  void _deleteCell(int row, int col) {
    setState(() {
      _rounds[_currentRound][row][col] = CrosswordCell(
        row: row,
        col: col,
        type: CellType.empty,
      );
    });

    _recalculateAllPatterns();
  }

  Future<String?> _askNumber(String? prev) async {
    final controller = TextEditingController(text: prev ?? '');
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Enter Number'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. 12'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<String?> _askOperator(String? prev) async {
    final allowedOp = _getOperatorSymbol();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Select Operator'),
        content: Text(
          'This operator is fixed to: $allowedOp',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, allowedOp),
            child: const Text('OK'),
            ),
        ],
      ),
    );
  }

  Future<void> _saveToSupabase() async {

    for (int round = 0; round < _rounds.length; round++) {
      final error = _validateRound(round);
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Round ${round + 1}: $error'),
            duration: const Duration(seconds: 5),
          ),
        );
      return;
      }
    }

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ You must be logged in to save.')),
        );
        return;
      }

      for (int round = 0; round < _rounds.length; round++) {
        final jsonGrid = _rounds[round]
            .map((row) => row.map((c) => c.toJson()).toList())
            .toList();

      await _supabase.from('crossword_puzzles').insert({
        'operator': widget.operator,
        'game_id': widget.gameId,
          'title': '${widget.title} - Round ${round + 1}',
        'difficulty': widget.difficulty,
        'grid': jsonGrid,
        'bank': [],
        'created_by': user.id,
      });
      }

      if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Saved ${_rounds.length} round(s) successfully!')),
      );
      Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Failed to save: $e')),
        );
      }
    }
  }

  String? _validateRound(int roundIndex) {
    final grid = _rounds[roundIndex];

    final previousRound = _currentRound;
    _currentRound = roundIndex;
    _recalculateAllPatterns();
    _currentRound = previousRound;

    int numberCount = 0;
    int operatorCount = 0;
    int blankCount = 0;
    final List<String> incompletePatterns = [];
    final List<String> missingAnswerCells = [];

    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        final cell = grid[r][c];

        if (cell.type == CellType.number) {
          if (cell.value == null || cell.value!.isEmpty) {
            return 'Some number cells are empty. Please fill in all number cells.';
          }
          if (int.tryParse(cell.value!) == null) {
            return 'Invalid number: "${cell.value}"';
          }
          numberCount++;
        } else if (cell.type == CellType.operator) {
          if (cell.value == null || cell.value!.isEmpty) {
            return 'Some operator cells are empty.';
          }
          operatorCount++;
        } else if (cell.type == CellType.blank) {
          blankCount++;

          bool isPartOfCompletePattern = _isBlankCellPartOfCompletePattern(grid, r, c);

          if (isPartOfCompletePattern) {

            if (cell.answer == null) {
              missingAnswerCells.add('Row ${r + 1}, col ${c + 1}');
            }
          } else {

            incompletePatterns.add('Row ${r + 1}, col ${c + 1}');
          }
        }
      }
    }

    if (numberCount < 2 || operatorCount == 0 || blankCount == 0) {
      return 'Incomplete crossword: must have at least two numbers, one operator, and one blank answer cell.';
    }

    if (incompletePatterns.isNotEmpty) {
      return 'Some patterns are incomplete. Please fill in all number cells in these patterns before saving:\n• ${incompletePatterns.take(5).join('\n• ')}';
    }

    if (missingAnswerCells.isNotEmpty) {

      _currentRound = roundIndex;
      _recalculateAllPatterns();
      _currentRound = previousRound;

      for (int r = 0; r < gridSize; r++) {
        for (int c = 0; c < gridSize; c++) {
          final cell = grid[r][c];
          if (cell.type == CellType.blank && cell.answer == null) {
            final isComplete = _isBlankCellPartOfCompletePattern(grid, r, c);
            if (isComplete) {
              return 'Some blank cells still do not have answers after recalculation. This may indicate a calculation error. Please check the patterns.';
            }
          }
        }
      }
    }

    return null;
  }

  bool _isBlankCellPartOfCompletePattern(List<List<CrosswordCell>> grid, int blankRow, int blankCol) {

    if (blankCol >= 4) {
      final num1 = int.tryParse(grid[blankRow][blankCol - 4].value ?? '');
      final op = grid[blankRow][blankCol - 3].value;
      final num2 = int.tryParse(grid[blankRow][blankCol - 2].value ?? '');
      if (grid[blankRow][blankCol - 4].type == CellType.number &&
          grid[blankRow][blankCol - 3].type == CellType.operator &&
          grid[blankRow][blankCol - 2].type == CellType.number &&
          grid[blankRow][blankCol - 1].type == CellType.equals &&
          grid[blankRow][blankCol].type == CellType.blank &&
          num1 != null && num2 != null && op != null) {
        return true;
      }
    }

    if (blankRow >= 4) {
      final num1 = int.tryParse(grid[blankRow - 4][blankCol].value ?? '');
      final op = grid[blankRow - 3][blankCol].value;
      final num2 = int.tryParse(grid[blankRow - 2][blankCol].value ?? '');
      if (grid[blankRow - 4][blankCol].type == CellType.number &&
          grid[blankRow - 3][blankCol].type == CellType.operator &&
          grid[blankRow - 2][blankCol].type == CellType.number &&
          grid[blankRow - 1][blankCol].type == CellType.equals &&
          grid[blankRow][blankCol].type == CellType.blank &&
          num1 != null && num2 != null && op != null) {
        return true;
      }
    }

    if (blankRow >= 4 && blankCol >= 4) {
      final num1 = int.tryParse(grid[blankRow - 4][blankCol - 4].value ?? '');
      final op = grid[blankRow - 3][blankCol - 3].value;
      final num2 = int.tryParse(grid[blankRow - 2][blankCol - 2].value ?? '');
      if (grid[blankRow - 4][blankCol - 4].type == CellType.number &&
          grid[blankRow - 3][blankCol - 3].type == CellType.operator &&
          grid[blankRow - 2][blankCol - 2].type == CellType.number &&
          grid[blankRow - 1][blankCol - 1].type == CellType.equals &&
          grid[blankRow][blankCol].type == CellType.blank &&
          num1 != null && num2 != null && op != null) {
        return true;
      }
    }

    if (blankRow >= 4 && blankCol <= 0) {
      final num1 = int.tryParse(grid[blankRow - 4][blankCol + 4].value ?? '');
      final op = grid[blankRow - 3][blankCol + 3].value;
      final num2 = int.tryParse(grid[blankRow - 2][blankCol + 2].value ?? '');
      if (grid[blankRow - 4][blankCol + 4].type == CellType.number &&
          grid[blankRow - 3][blankCol + 3].type == CellType.operator &&
          grid[blankRow - 2][blankCol + 2].type == CellType.number &&
          grid[blankRow - 1][blankCol + 1].type == CellType.equals &&
          grid[blankRow][blankCol].type == CellType.blank &&
          num1 != null && num2 != null && op != null) {
        return true;
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crossword Builder - Round ${_currentRound + 1}/${_numRounds}'),
        backgroundColor: Colors.deepPurple,
        actions: [
          if (_numRounds > 1) ...[
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _currentRound > 0
                  ? () => setState(() => _currentRound--)
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: _currentRound < _numRounds - 1
                  ? () => setState(() => _currentRound++)
                  : null,
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.deepPurple.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    if (widget.description.isNotEmpty)
                      Text(
                        widget.description,
                        style: const TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      'Difficulty: ${widget.difficulty.toUpperCase()} - ${_numRounds} round(s)',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (_selectedPattern != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Pattern: ${_selectedPattern!.name.toUpperCase()}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '📝 Instructions:\n'
              '• Tap an empty cell to start a pattern (Horizontal, Vertical, or Slant)\n'
              '• Long press a filled cell for options (Edit, Delete, Cancel)\n'
              '• Patterns create the structure: number → operator → number → equals → answer\n'
              '• Fill in numbers in the pattern - the answer will be calculated automatically\n'
              '• Patterns can overlap! Numbers can be shared between different patterns (like crosswords)\n'
              '• Operator is automatically set based on the selected operator type\n'
              '• You cannot place standalone numbers - they must be part of a pattern',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            if (_selectedPattern == null)
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Select Pattern First'),
                onPressed: _selectPattern,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            const SizedBox(height: 16),
            _buildGrid(),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: Text('Save ${_numRounds} Round(s)'),
              onPressed: _saveToSupabase,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid() {
    final grid = _rounds[_currentRound];
    return Center(
      child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int r = 0; r < gridSize; r++)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int c = 0; c < gridSize; c++)
                  Builder(
                    builder: (context) {
                      final cell = grid[r][c];
                      final isSelected = _selectedRow == r && _selectedCol == c;
                      return GestureDetector(
                        onTap: () {
                          final RenderBox box = context.findRenderObject() as RenderBox;
                          final position = box.localToGlobal(Offset.zero);
                          _handleCellTap(r, c, position);
                        },
                  onLongPress: () {
                          final RenderBox box = context.findRenderObject() as RenderBox;
                          final position = box.localToGlobal(Offset.zero);
                          _handleCellLongPress(r, c, position);
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    margin: const EdgeInsets.all(4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                            color: _colorForType(cell.type),
                      borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? Colors.blue : Colors.black26,
                              width: isSelected ? 2 : 1,
                            ),
                    ),
                    child: Text(
                            cell.value ?? (cell.answer != null ? '?' : ''),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: cell.type == CellType.blank
                                  ? Colors.grey[600]
                                  : Colors.black,
                            ),
                    ),
                  ),
                      );
                    },
                ),
            ],
          ),
      ],
      ),
    );
  }

  Color _colorForType(CellType type) {
    switch (type) {
      case CellType.number:
        return Colors.purple[100]!;
      case CellType.answer:
        return Colors.green[100]!;
      case CellType.operator:
        return Colors.blue[100]!;
      case CellType.equals:
        return Colors.orange[100]!;
      case CellType.blank:
        return Colors.grey[200]!;
      default:
        return Colors.white;
    }
  }
}
