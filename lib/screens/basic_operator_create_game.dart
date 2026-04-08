import 'package:flutter/material.dart';
import 'package:pracpro/screens/basic_operator_ninja_builder_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/operator_game_service.dart';

class BasicOperatorCreateGamePage extends StatefulWidget {
  final String operatorKey;
  final String? classroomId;
  const BasicOperatorCreateGamePage({
    super.key,
    required this.operatorKey,
    this.classroomId,
  });

  @override
  State<BasicOperatorCreateGamePage> createState() =>
      _BasicOperatorCreateGamePageState();
}

class _BasicOperatorCreateGamePageState
    extends State<BasicOperatorCreateGamePage> {
  final _formKey = GlobalKey<FormState>();
  final _svc = OperatorGameService();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  bool _isSaving = false;
  String _selectedGame = 'ninjamath'; // Only Ninja Math can be created
  String _selectedDifficulty = 'Easy';

  final Map<String, Map<String, dynamic>> _configs = {
    'Easy': {'timeSec': 180, 'min': 1, 'max': 10, 'rounds': 10},
    'Medium': {'timeSec': 240, 'min': 1, 'max': 20, 'rounds': 12},
    'Hard': {'timeSec': 300, 'min': 1, 'max': 50, 'rounds': 15},
  };
  late final Map<String, Map<String, TextEditingController>> _configControllers;

  @override
  void initState() {
    super.initState();
    _configControllers = {
      for (final level in _configs.keys)
        level: {
          for (final key in _configs[level]!.keys)
            key: TextEditingController(text: _configs[level]![key].toString()),
        },
    };
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    for (final byLevel in _configControllers.values) {
      for (final c in byLevel.values) {
        c.dispose();
      }
    }
    super.dispose();
  }

  int _parseConfigInt(String level, String key, int fallback) {
    final text = _configControllers[level]?[key]?.text.trim() ?? '';
    return int.tryParse(text) ?? fallback;
  }

  bool _roundHasSolution({
    required String operatorKey,
    required List<int> numbers,
    required int target,
  }) {
    bool hasPermutationMatch(List<int> values, bool Function(List<int>) tester) {
      final used = List<bool>.filled(values.length, false);
      final current = <int>[];
      var found = false;

      void backtrack() {
        if (found) return;
        if (current.length == values.length) {
          if (tester(current)) found = true;
          return;
        }
        for (int i = 0; i < values.length; i++) {
          if (used[i]) continue;
          used[i] = true;
          current.add(values[i]);
          backtrack();
          current.removeLast();
          used[i] = false;
          if (found) return;
        }
      }

      backtrack();
      return found;
    }

    final op = operatorKey.toLowerCase();
    for (int mask = 1; mask < (1 << numbers.length); mask++) {
      final selected = <int>[];
      for (int i = 0; i < numbers.length; i++) {
        if ((mask & (1 << i)) != 0) selected.add(numbers[i]);
      }
      if (selected.length < 2) continue;

      bool matched;
      switch (op) {
        case 'addition':
        case 'add':
          matched = selected.fold<int>(0, (a, b) => a + b) == target;
          break;
        case 'subtraction':
        case 'subtract':
          matched = hasPermutationMatch(selected, (perm) {
            if (perm.isEmpty) return false;
            return perm[0] - perm.sublist(1).fold<int>(0, (a, b) => a + b) == target;
          });
          break;
        case 'multiplication':
        case 'multiply':
          matched = selected.fold<int>(1, (a, b) => a * b) == target;
          break;
        case 'division':
        case 'divide':
          matched = hasPermutationMatch(selected, (perm) {
            if (perm.isEmpty) return false;
            final divisor = perm.sublist(1).fold<int>(1, (a, b) => a * b);
            if (divisor == 0 || perm[0] % divisor != 0) return false;
            return (perm[0] ~/ divisor) == target;
          });
          break;
        default:
          matched = selected.fold<int>(0, (a, b) => a + b) == target;
      }

      if (matched) return true;
    }
    return false;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ You must be logged in.')),
        );
        return;
      }

      // Prevent duplicate Ninja Math entries for the same operator + difficulty + scope.
      final existing = await _svc.getPreferredGame(
        operatorKey: widget.operatorKey,
        gameKey: _selectedGame,
        difficulty: _selectedDifficulty,
        classroomId: widget.classroomId,
      );
      final isDuplicateInScope = existing != null &&
          ((widget.classroomId != null && widget.classroomId!.trim().isNotEmpty)
              ? existing.isClassroomScoped
              : !existing.isClassroomScoped);
      if (isDuplicateInScope) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '⚠️ Ninja Math already exists for ${widget.operatorKey} - $_selectedDifficulty.',
            ),
          ),
        );
        return;
      }

      final config = <String, dynamic>{
        'timeSec': _parseConfigInt(
          _selectedDifficulty,
          'timeSec',
          _configs[_selectedDifficulty]!['timeSec'] as int,
        ),
        'min': _parseConfigInt(
          _selectedDifficulty,
          'min',
          _configs[_selectedDifficulty]!['min'] as int,
        ),
        'max': _parseConfigInt(
          _selectedDifficulty,
          'max',
          _configs[_selectedDifficulty]!['max'] as int,
        ),
        'rounds': _parseConfigInt(
          _selectedDifficulty,
          'rounds',
          _configs[_selectedDifficulty]!['rounds'] as int,
        ),
      };

      // Only Ninja Math can be created - always generate rounds
      List<Map<String, dynamic>>? generatedRounds;
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BasicOperatorNinjaBuilderScreen(
              operator: widget.operatorKey,
              config: config,
              difficulty: _selectedDifficulty,
              title: _titleCtrl.text.trim(),
              description: _descCtrl.text.trim(),
            ),
          ),
        );

        if (result == null || result.isEmpty) {
          setState(() => _isSaving = false);
          return;
        }
        generatedRounds = List<Map<String, dynamic>>.from(result);
      final gameId = await _svc.createGame(
        operatorKey: widget.operatorKey,
        gameKey: _selectedGame,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        variantsByDifficulty: {
          _selectedDifficulty.toLowerCase(): config,
        },
        createdBy: user.id,
        classroomId: widget.classroomId,
      );
      if (generatedRounds != null && generatedRounds.isNotEmpty) {
        final hasInvalidRound = generatedRounds.any((round) {
          final numbers = (round['numbers'] as List?)
                  ?.map((e) => int.tryParse(e.toString()) ?? 0)
                  .toList() ??
              <int>[];
          final target = int.tryParse(round['target']?.toString() ?? '') ?? 0;
          return !_roundHasSolution(
            operatorKey: widget.operatorKey,
            numbers: numbers,
            target: target,
          );
        });
        if (hasInvalidRound) {
          throw Exception(
            'One or more rounds are unsolvable. Please regenerate or edit targets.',
          );
        }

        final rows = generatedRounds
            .asMap()
            .entries
            .map((e) => {
          'game_id': gameId,
          'round_no': e.key + 1,
          'numbers': e.value['numbers'],
          'correct_answer': e.value['target'],
        })
            .toList();

        await supabase.from('ninja_math_rounds').insert(rows);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Game created successfully (ID: $gameId)')),
      );
        Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Game'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Game type is fixed to Ninja Math only
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Game Type: ',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const Text(
                      'Ninja Math',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
              ),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Game Title'),
                validator: (v) =>
                v == null || v.isEmpty ? 'Title is required.' : null,
              ),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Difficulty'),
                value: _selectedDifficulty,
                items: const [
                  DropdownMenuItem(value: 'Easy', child: Text('Easy')),
                  DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'Hard', child: Text('Hard')),
                ],
                onChanged: (v) =>
                    setState(() => _selectedDifficulty = v ?? 'Easy'),
              ),
              const SizedBox(height: 16),
              _buildConfigCard(_selectedDifficulty),
              const SizedBox(height: 24),
              _isSaving
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Save & Continue'),
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfigCard(String level) {
    final cfg = _configs[level]!;
    return Card(
      color: Colors.deepPurple.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text('$level Settings'),
        initiallyExpanded: true,
        children: [
          _numField(cfg, 'timeSec', 'Time Limit (seconds)'),
          _numField(cfg, 'min', 'Minimum number'),
          _numField(cfg, 'max', 'Maximum number'),
          _numField(cfg, 'rounds', 'Total Rounds'),
        ],
      ),
    );
  }

  Widget _numField(Map<String, dynamic> cfg, String key, String label) {
    final controller = _configControllers[_selectedDifficulty]![key]!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        keyboardType: TextInputType.number,
        onChanged: (v) {
          final parsed = int.tryParse(v);
          if (parsed != null) {
            cfg[key] = parsed;
          }
        },
      ),
    );
  }
}
