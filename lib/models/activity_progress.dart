class ActivityProgress {
  final String source;
  final String sourceId;
  final String? userId;
  final String? userName;
  final String entityType;
  final String? entityId;
  final String? entityTitle;
  final String stage;
  final int? score;
  final int? attempt;
  final int? highestScore;
  final int? tries;
  final String? status;
  final String classroomId;
  final DateTime createdAt;

  ActivityProgress({
    required this.source,
    required this.sourceId,
    this.userId,
    this.userName,
    required this.entityType,
    this.entityId,
    this.entityTitle,
    required this.stage,
    this.score,
    this.attempt,
    this.highestScore,
    this.tries,
    this.status,
    required this.classroomId,
    required this.createdAt,
  });

  factory ActivityProgress.fromJson(Map<String, dynamic> json) {
    return ActivityProgress(
      source: json['source'],
      sourceId: json['source_id'],
      userId: json['user_id'],
      userName: json['user_name'],
      entityType: json['entity_type'],
      entityId: json['entity_id'],
      entityTitle: json['entity_title'],
      stage: json['stage'],
      score: json['score'],
      attempt: json['attempt'],
      highestScore: json['highest_score'],
      tries: json['tries'],
      status: json['status'],
      classroomId: json['classroom_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
