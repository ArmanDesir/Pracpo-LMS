class OperatorGameVariant {
  final String id;
  final String difficulty;
  final Map<String, dynamic> config;

  OperatorGameVariant({
    required this.id,
    required this.difficulty,
    required this.config,
  });

  factory OperatorGameVariant.fromJson(Map<String, dynamic> json) {
    return OperatorGameVariant(
      id: json['id'] as String,
      difficulty: json['difficulty'] as String,
      config: Map<String, dynamic>.from(json['config'] ?? {}),
    );
  }
}

class OperatorGame {
  final String id;
  final String operatorKey;
  final String gameKey;
  final String title;
  final String? description;
  final bool isActive;
  final List<OperatorGameVariant> variants;

  OperatorGame({
    required this.id,
    required this.operatorKey,
    required this.gameKey,
    required this.title,
    this.description,
    required this.isActive,
    required this.variants,
  });

  factory OperatorGame.fromJson(Map<String, dynamic> json) {
    final vars = (json['operator_game_variants_game_id_fkey'] as List? ?? [])
        .map((v) => OperatorGameVariant.fromJson(v as Map<String, dynamic>))
        .toList();

    return OperatorGame(
      id: json['id'] as String,
      operatorKey: json['operator'] as String,
      gameKey: json['game_key'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      isActive: json['is_active'] ?? true,
      variants: vars,
    );
  }
}
