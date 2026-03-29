import 'dart:convert';

class ActivityLog {
  final String id;
  final String? userId;
  final String activityType;
  final String? referenceId;
  final String? description;
  final Map<String, dynamic>? extraData;
  final DateTime createdAt;
  final String? userName;

  ActivityLog({
    required this.id,
    this.userId,
    required this.activityType,
    this.referenceId,
    this.description,
    this.extraData,
    required this.createdAt,
    this. userName,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: json['id'],
      userId: json['user_id'],
      activityType: json['activity_type'],
      referenceId: json['reference_id'],
      description: json['description'],
      extraData: json['extra_data'] != null ? Map<String, dynamic>.from(json['extra_data']) : null,
      createdAt: DateTime.parse(json['created_at']),
      userName: json['user_name'],
    );
  }
}
