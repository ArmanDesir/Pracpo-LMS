class Classroom {
  final String id;
  final String name;
  final String teacherId;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> studentIds;
  final List<String> pendingStudentIds;
  final List<String> lessonIds;
  final List<String> quizIds;
  final String? code;
  final bool isActive;
  final bool isSynced;
  int studentCount;
  final bool isArchived;

  Classroom({
    required this.id,
    required this.name,
    required this.teacherId,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.studentIds = const [],
    this.pendingStudentIds = const [],
    this.lessonIds = const [],
    this.quizIds = const [],
    this.code,
    this.isActive = true,
    this.isSynced = false,
    this.studentCount = 0,
    this.isArchived = false,
  });

  factory Classroom.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is String) return DateTime.parse(value);
      throw Exception('Invalid date format for Classroom');
    }

    return Classroom(
      id: json['id'] as String,
      name: json['name'] as String,
      teacherId: json['teacher_id'] as String,
      description: json['description'] as String?,
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
      studentIds: (json['student_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
          const [],
      pendingStudentIds: (json['pending_student_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
          const [],
      lessonIds: (json['lesson_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
          const [],
      quizIds: (json['quiz_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
          const [],
      code: json['code'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      isSynced: json['is_synced'] as bool? ?? false,
      studentCount: 0,
      isArchived: json['is_archived'] as bool? ?? !(json['is_active'] as bool? ?? true),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'teacher_id': teacherId,
    'description': description,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'student_ids': studentIds,
    'pending_student_ids': pendingStudentIds,
    'lesson_ids': lessonIds,
    'quiz_ids': quizIds,
    'code': code,
    'is_active': isActive,
    'is_synced': isSynced,
    'is_archived': isArchived,
  };

  Classroom copyWith({
    String? id,
    String? name,
    String? teacherId,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? studentIds,
    List<String>? pendingStudentIds,
    List<String>? lessonIds,
    List<String>? quizIds,
    String? code,
    bool? isActive,
    bool? isSynced,
    int? studentCount,
    bool? isArchived,
  }) {
    return Classroom(
      id: id ?? this.id,
      name: name ?? this.name,
      teacherId: teacherId ?? this.teacherId,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      studentIds: studentIds ?? this.studentIds,
      pendingStudentIds: pendingStudentIds ?? this.pendingStudentIds,
      lessonIds: lessonIds ?? this.lessonIds,
      quizIds: quizIds ?? this.quizIds,
      code: code ?? this.code,
      isActive: isActive ?? this.isActive,
      isSynced: isSynced ?? this.isSynced,
      studentCount: studentCount ?? this.studentCount,
      isArchived: isArchived ?? this.isArchived,
    );
  }
}
