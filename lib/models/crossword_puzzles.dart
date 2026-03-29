class CrosswordPuzzle {
  final String id;
  final String operator;
  final String title;
  final String difficulty;
  final Map<String, dynamic> grid;
  final List<dynamic> bank;
  final String? gameId;

  CrosswordPuzzle({
    required this.id,
    required this.operator,
    required this.title,
    required this.difficulty,
    required this.grid,
    required this.bank,
    this.gameId,
  });

  factory CrosswordPuzzle.fromJson(Map<String, dynamic> json) {
    return CrosswordPuzzle(
      id: json['id'] as String,
      operator: json['operator'] as String,
      title: json['title'] as String,
      difficulty: json['difficulty'] as String,
      grid: json['grid'] as Map<String, dynamic>,
      bank: (json['bank'] as List<dynamic>?) ?? [],
      gameId: json['game_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'operator': operator,
    'title': title,
    'difficulty': difficulty,
    'grid': grid,
    'bank': bank,
    'game_id': gameId,
  };
}
