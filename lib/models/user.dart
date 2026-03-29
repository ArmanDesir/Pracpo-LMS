import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

enum UserType { student, teacher }

@JsonSerializable(fieldRename: FieldRename.snake)
class User {
  final String id;
  final String name;
  final String? email;
  final String? photoUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isOnline;
  final String? lastSyncTime;
  final UserType userType;
  final String? teacherCode;
  final List<String> classroomIds;
  final String? classroomId;
  final int? grade;
  final String? teacherId;
  final String? contactNumber;
  final String? studentId;
  final String? guardianName;
  final String? guardianEmail;
  final String? guardianContactNumber;
  final String? studentInfo;

  User({
    required this.id,
    required this.name,
    this.email,
    this.photoUrl,
    this.createdAt,
    this.updatedAt,
    this.isOnline = false,
    this.lastSyncTime,
    required this.userType,
    this.teacherCode,
    this.classroomIds = const [],
    this.classroomId,
    this.grade,
    this.teacherId,
    this.contactNumber,
    this.studentId,
    this.guardianName,
    this.guardianEmail,
    this.guardianContactNumber,
    this.studentInfo,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isOnline,
    String? lastSyncTime,
    UserType? userType,
    String? teacherCode,
    List<String>? classroomIds,
    String? classroomId,
    int? grade,
    String? teacherId,
    String? contactNumber,
    String? studentId,
    String? guardianName,
    String? guardianEmail,
    String? guardianContactNumber,
    String? studentInfo,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isOnline: isOnline ?? this.isOnline,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      userType: userType ?? this.userType,
      teacherCode: teacherCode ?? this.teacherCode,
      classroomIds: classroomIds ?? this.classroomIds,
      classroomId: classroomId ?? this.classroomId,
      grade: grade ?? this.grade,
      teacherId: teacherId ?? this.teacherId,
      contactNumber: contactNumber ?? this.contactNumber,
      studentId: studentId ?? this.studentId,
      guardianName: guardianName ?? this.guardianName,
      guardianEmail: guardianEmail ?? this.guardianEmail,
      guardianContactNumber: guardianContactNumber ?? this.guardianContactNumber,
      studentInfo: studentInfo ?? this.studentInfo,
    );
  }
}
