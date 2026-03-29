// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: json['id'] as String,
  name: json['name'] as String,
  email: json['email'] as String?,
  photoUrl: json['photo_url'] as String?,
  createdAt:
      json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
  updatedAt:
      json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
  isOnline: json['is_online'] as bool? ?? false,
  lastSyncTime: json['last_sync_time'] as String?,
  userType: $enumDecode(_$UserTypeEnumMap, json['user_type']),
  teacherCode: json['teacher_code'] as String?,
  classroomIds:
      (json['classroom_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  classroomId: json['classroom_id'] as String?,
  grade: (json['grade'] as num?)?.toInt(),
  teacherId: json['teacher_id'] as String?,
  contactNumber: json['contact_number'] as String?,
  studentId: json['student_id'] as String?,
  guardianName: json['guardian_name'] as String?,
  guardianEmail: json['guardian_email'] as String?,
  guardianContactNumber: json['guardian_contact_number'] as String?,
  studentInfo: json['student_info'] as String?,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'email': instance.email,
  'photo_url': instance.photoUrl,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
  'is_online': instance.isOnline,
  'last_sync_time': instance.lastSyncTime,
  'user_type': _$UserTypeEnumMap[instance.userType]!,
  'teacher_code': instance.teacherCode,
  'classroom_ids': instance.classroomIds,
  'classroom_id': instance.classroomId,
  'grade': instance.grade,
  'teacher_id': instance.teacherId,
  'contact_number': instance.contactNumber,
  'student_id': instance.studentId,
  'guardian_name': instance.guardianName,
  'guardian_email': instance.guardianEmail,
  'guardian_contact_number': instance.guardianContactNumber,
  'student_info': instance.studentInfo,
};

const _$UserTypeEnumMap = {
  UserType.student: 'student',
  UserType.teacher: 'teacher',
};
